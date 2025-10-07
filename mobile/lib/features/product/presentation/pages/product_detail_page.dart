// lib/features/product/presentation/pages/product_detail_page.dart
import 'package:flutter/material.dart';

// ===== Entity + API integration =====
import 'package:mobile/features/product/domain/entities/product.dart';
import 'package:mobile/features/product/domain/usecases/get_product_detail.dart';
import 'package:mobile/features/product/domain/usecases/toggle_favorite.dart';
import 'package:mobile/injection.dart';

// ===== Local wishlist store (in-memory demo) =====
import 'package:mobile/features/product/presentation/state/wishlist_store.dart';


// ===== Transaction functionality =====
import 'package:mobile/features/transaction/domain/usecases/create_inquiry.dart';
import 'package:mobile/features/transaction/domain/usecases/create_transaction_request.dart';
import 'package:mobile/features/transaction/domain/entities/transaction_inquiry.dart';

// ===== Chat functionality =====
import 'package:mobile/features/chat/domain/usecases/create_chat_room.dart';
import 'package:mobile/features/chat/presentation/pages/chat_page.dart';

// ===== Auth functionality =====
import 'package:mobile/core/auth/token_manager.dart';
import 'package:mobile/core/auth/auth_state_manager.dart';


// ===== Checkout functionality =====
import 'package:mobile/features/checkout/presentation/pages/checkout_page.dart';

// ===== Chat functionality =====
import 'package:mobile/features/chat/presentation/pages/chat_page.dart';
import 'package:mobile/features/chat/domain/usecases/get_chat_list.dart';

const kBrandGreen = Color(0xFF32C286); // <-- use this brand green

class ProductDetailPage extends StatefulWidget {
  final dynamic productId;
  final ProductEntity? initial;

  const ProductDetailPage({
    super.key,
    required this.productId,
    this.initial,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Future<ProductEntity> _future;
  int _page = 0; // current image page
  bool _isFav = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ProductEntity> _load() async {
    try {
      ProductEntity product;
      // Use initial product if provided, otherwise fetch from API
      if (widget.initial != null) {
        product = widget.initial!;
      } else {
        final getProductDetail = ServiceLocator().get<GetProductDetail>();
        final productId = widget.productId.toString();
        product = await getProductDetail.call(productId);
      }
      
      // Set initial favorite state
      setState(() {
        _isFav = product.stats?.isFavorited ?? false;
      });
      
      return product;
    } catch (e) {
      // If API fails, show error to user
      throw Exception('Failed to load product details: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final toggleFavorite = ServiceLocator().get<ToggleFavorite>();
      final response = await toggleFavorite.call(widget.productId.toString());
      
      setState(() {
        _isFav = response.isFavorited;
        _isLoading = false;
      });

      _snack(response.isFavorited ? 'Added to favorites' : 'Removed from favorites');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      _snack('Failed to update favorite: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the page in a Theme that sets primary to kBrandGreen
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme:
            Theme.of(context).colorScheme.copyWith(primary: kBrandGreen),
      ),
      child: Builder(
        builder: (context) {
          final cs = Theme.of(context).colorScheme;

          return FutureBuilder<ProductEntity>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Colors.white,
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              
              if (snap.hasError) {
                return Scaffold(
                  backgroundColor: Colors.white,
                  appBar: AppBar(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                    title: const Text('Product Details', style: TextStyle(color: Colors.black87)),
                  ),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to Load',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snap.error.toString().replaceAll('Exception: ', ''),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _future = _load();
                            });
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              if (!snap.hasData) {
                return const Scaffold(
                  backgroundColor: Colors.white,
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              
              final product = snap.data!;
              final images = _imagesOf(product);
              final price = product.price;
              final reviewsCount = (product.viewCount ?? 0).toInt();

              return Scaffold(
                backgroundColor: Colors.white,
                body: CustomScrollView(
                  slivers: [
                    // ===== SliverAppBar with gallery =====
                    SliverAppBar(
                      expandedHeight: MediaQuery.of(context).size.width, // Square aspect ratio
                      floating: false,
                      pinned: true,
                      backgroundColor: Colors.white,
                      elevation: 0,
                      leading: _IconBubble(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      actions: [
                        _HeartButton(
                          isFav: _isFav,
                          isLoading: _isLoading,
                          onTap: _isLoading ? null : _toggleFavorite,
                        ),
                        const SizedBox(width: 8),
                        _IconBubble(
                          icon: Icons.ios_share_rounded,
                          onTap: () => _snack('Share'),
                        ),
                        const SizedBox(width: 16),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: _Gallery(
                          images: images,
                          page: _page,
                          onPageChanged: (i) => setState(() => _page = i),
                          // Remove overlays since they're now in AppBar
                          topLeft: null,
                          topRight: null,
                          bottomRight: _AlbumBadge(
                            current: _page + 1,
                            total: images.length,
                          ),
                        ),
                      ),
                    ),
                    
                    // ===== Content =====
                    SliverToBoxAdapter(
                      child: Column(
                        children: [

                      // ===== Price (left) + reviews (right) =====
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _money(price),
                                      style: const TextStyle(
                                        color: Color(0xFFE03636),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 26,
                                      ),
                                    ),
                                    if (product.originalPrice != null && product.originalPrice! > price) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        _money(product.originalPrice!),
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (product.discount != null) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      product.discount!,
                                      style: TextStyle(
                                        color: Colors.red[600],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const Spacer(),
                            Text(
                              '${_formatCount(reviewsCount)} Views',
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Product tags
                      if (product.tags.isNotEmpty) 
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _translateTags(product.tags).map((tag) => _Chip(text: tag)).toList(),
                          ),
                        ),

                      // ===== Product name with optional HOT badge =====
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                        child: Row(
                          children: [
                            // Show HOT badge if product has high view count or is popular
                            if ((product.viewCount ?? 0) > 100 || product.tags.contains('热门') || product.tags.contains('Hot')) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF4D4F),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('HOT!',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                product.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ===== Product Detail square (light grey background) =====
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _ProductDetailCard(product: product),
                      ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ===== Bottom actions =====
                bottomNavigationBar: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _buyNow(context, product),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: cs.primary, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: Text(
                              'Buy now',
                              style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _contactSeller(context, product),
                            style: FilledButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: const Text(
                              'Contact seller',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<String> _imagesOf(ProductEntity p) {
    final pics = <String>[];
    if ((p.mainImage ?? '').isNotEmpty) pics.add(p.mainImage!);
    pics.addAll(p.images.where((e) => e.isNotEmpty));
    if (pics.isEmpty) pics.add('');
    return pics;
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // 显示自己商品的提醒对话框
  void _showSelfProductDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.orange,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  Future<void> _buyNow(BuildContext context, ProductEntity product) async {
    // 检查用户是否已登录
    final canProceed = await AuthStateManager.instance.checkAuthAndShowDialog(context);
    if (!canProceed) return;
    
    // 检查是否为自己的商品
    if (product.stats?.isOwn == true) {
      _showSelfProductDialog(context, "You cannot buy your own product!");
      return;
    }
    
    // 跳转到结账页面
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(
          productName: product.title,
          productImage: product.mainImage ?? '',
          productPrice: product.price,
          productId: product.id,
          sellerId: product.sellerId?.toString() ?? '',
          product: product, // Pass the product entity for real data
        ),
      ),
    );
  }

  Future<void> _contactSeller(BuildContext context, ProductEntity product) async {
    // 检查用户是否已登录
    final canProceed = await AuthStateManager.instance.checkAuthAndShowDialog(context);
    if (!canProceed) return;

    // 检查是否为自己的商品
    if (product.stats?.isOwn == true) {
      _showSelfProductDialog(context, "You cannot contact yourself!");
      return;
    }

    // 显示输入消息的对话框
    final message = await _showInquiryDialog(context, product);
    if (message == null || message.isEmpty) return;

    // 显示发送中的对话框
    _showSendingDialog(context);

    try {
      // 使用CreateInquiry用例发送INFO类型的inquiry
      final createInquiry = ServiceLocator().get<CreateInquiry>();
      final result = await createInquiry.call(
        productId: product.id,
        sellerId: product.sellerId?.toString() ?? '',
        message: message,
        inquiryType: 'INFO', // 信息咨询
      );

      // 关闭发送中对话框
      Navigator.of(context).pop();

      // 显示成功对话框
      _showSuccessDialog(context, result);
    } catch (e) {
      // 关闭发送中对话框
      Navigator.of(context).pop();
      
      // 检查是否是"已存在交易记录"错误
      if (e.toString().contains('Transaction record already exists')) {
        // 直接跳转到聊天页面
        _navigateToExistingChat(context, product);
      } else {
        // 显示其他错误信息
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Send failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateToExistingChat(BuildContext context, ProductEntity product) async {
    // 显示提示信息
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Existing chat found, searching...'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
    
    try {
      // 通过聊天列表API查找对应的聊天室
      final getChatList = ServiceLocator().get<GetChatList>();
      final chatList = await getChatList.call(page: 1, size: 100);
      
      // 查找与当前商品和卖家相关的聊天室
      String? targetChatRoomId;
      for (final chatRoom in chatList.content) {
        // 这里可以根据商品ID或卖家ID来匹配
        // 暂时使用简单的逻辑，实际应该根据API返回的数据结构来匹配
        if (chatRoom.participant.id == product.sellerId) {
          targetChatRoomId = chatRoom.chatRoomId;
          break;
        }
      }
      
      if (targetChatRoomId != null) {
        // 跳转到找到的聊天页面
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              chatRoomId: targetChatRoomId!,
              inquiryType: 'INFO',
            ),
          ),
        );
      } else {
        // 如果找不到对应的聊天室，显示错误信息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No corresponding chat found'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // 如果获取聊天列表失败，显示错误信息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get chat list: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _showInquiryDialog(BuildContext context, ProductEntity product) async {
    final controller = TextEditingController();
    
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                'Contact Seller',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              
              // Subtitle
              Text(
                'Send a message to the seller:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 20),
              
              // Text field
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Please enter what you would like to know...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF32C286), width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 3,
                textInputAction: TextInputAction.newline,
              ),
              SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(controller.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF32C286),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Send',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSendingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Loading icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Color(0xFF32C286).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF32C286)),
                  strokeWidth: 3,
                ),
              ),
              SizedBox(height: 24),
              
              // Loading text
              Text(
                'Sending message...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              
              Text(
                'Please wait a moment',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, TransactionInquiryEntity result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Color(0xFF32C286).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 50,
                  color: Color(0xFF32C286),
                ),
              ),
              SizedBox(height: 24),
              
              // Title
              Text(
                'Message Sent Successfully!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              
              // Description
              Text(
                'Your message has been sent to the seller. They will reply to you through chat.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // 跳转到聊天页面
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              chatRoomId: result.chatRoomId,
                              inquiryType: 'INFO',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF32C286),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 18,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'View Chat',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}

/* ─────────────────────────────  GALLERY  ───────────────────────────── */

class _Gallery extends StatelessWidget {
  final List<String> images;
  final int page;
  final ValueChanged<int> onPageChanged;
  final Widget? topLeft;
  final Widget? topRight;
  final Widget? bottomRight;

  const _Gallery({
    required this.images,
    required this.page,
    required this.onPageChanged,
    this.topLeft,
    this.topRight,
    this.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    final controller = PageController(initialPage: page);
    final cs = Theme.of(context).colorScheme;
    final double safeTop = MediaQuery.of(context).padding.top;

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          PageView.builder(
            controller: controller,
            onPageChanged: onPageChanged,
            itemCount: images.length,
            itemBuilder: (context, i) {
              final url = images[i];
              if (url.isEmpty) return ColoredBox(color: cs.primary.withOpacity(.10));
              final isNet = url.startsWith('http');
              return GestureDetector(
                onTap: () => _showComingSoonDialog(context),
                child: isNet
                    ? Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            ColoredBox(color: cs.primary.withOpacity(.10)),
                      )
                    : Image.asset(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            ColoredBox(color: cs.primary.withOpacity(.10)),
                      ),
              );
            },
          ),

          if (topLeft != null)
            Positioned(
              left: 8,
              top: safeTop + 8, // stay below notch/status bar
              child: topLeft!,
            ),

          if (topRight != null)
            Positioned(
              right: 8,
              top: safeTop + 8,
              child: topRight!,
            ),

          if (bottomRight != null)
            Positioned(
              right: 8,
              bottom: 8,
              child: bottomRight!,
            ),
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBubble({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 20, color: Colors.black87),
        ),
      ),
    );
  }
}

class _HeartButton extends StatelessWidget {
  final bool isFav;
  final bool isLoading;
  final VoidCallback? onTap;
  const _HeartButton({
    required this.isFav, 
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: isLoading 
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isFav ? cs.primary : Colors.black87,
                  ),
                ),
              )
            : Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                size: 20,
                color: isFav ? cs.primary : Colors.black87,
              ),
        ),
      ),
    );
  }
}

class _AlbumBadge extends StatelessWidget {
  final int current;
  final int total;
  const _AlbumBadge({required this.current, required this.total});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: cs.primary, width: 1.6),
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Album $current/$total',
        style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/* ─────────────────────────────  PRODUCT DETAIL CARD  ───────────────────────────── */

class _ProductDetailCard extends StatefulWidget {
  final ProductEntity product;
  const _ProductDetailCard({required this.product});

  @override
  State<_ProductDetailCard> createState() => _ProductDetailCardState();
}

class _ProductDetailCardState extends State<_ProductDetailCard> {
  bool _descExpanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Extract product attributes or use defaults
    final brand = _extractBrand(widget.product.title);
    final color = 'Unknown'; // Could be extracted from product attributes
    final model = widget.product.title;

    // Build key-value pairs from product data
    final kv = <_KV>[];
    
    // Add usage info if available
    if (widget.product.usageInfo != null) {
      kv.add(_KV('Usage time', _translateUsageInfo(widget.product.usageInfo!.displayText)));
    }
    
    // Add condition
    if (widget.product.conditionText != null) {
      kv.add(_KV('Product Condition', _translateConditionText(widget.product.conditionText!)));
    }
    
    // Add warranty info
    if (widget.product.warranty != null) {
      final warranty = widget.product.warranty!;
      kv.add(_KV(
        'Warranty', 
        warranty.displayText ?? (warranty.hasWarranty ? 'Available' : 'Not available'), 
        valueColor: warranty.hasWarranty ? Colors.teal : Colors.grey,
      ));
    }
    
    // Add category info
    if (widget.product.categoryPath != null) {
      kv.add(_KV('Category', _translateCategoryPath(widget.product.categoryPath!)));
    }
    
    // Add location info (temporarily show Unknown as backend location system is not ready)
    if (widget.product.locationDisplay != null) {
      kv.add(_KV('Location', 'Unknown'));
    }

    final description = widget.product.description ?? 'No description available.';

    const panelColor = Color(0xFFF4F5F7); // solid light grey square

    return Container(
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Row(
              children: [
                const Text('Product Detail',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  'Following information was filled by seller',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),

          // Brand / Color / Model + chevron (tap to go to attributes page)
          InkWell(
            onTap: () => _snack(context, 'See all product attributes'),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  Expanded(child: _TripleCell(label: 'Brand', value: brand)),
                  Expanded(child: _TripleCell(label: 'Color', value: color)),
                  Expanded(
                    child: _TripleCell(label: 'Model', value: model, maxLines: 1),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),

          const Divider(height: 16, thickness: 0.7),

          // Key-value rows
          for (final r in kv) _KvRow(r),

          // Description with expand arrow on the same line (right aligned)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 120,
                  child: Text('Description',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AnimatedCrossFade(
                          firstChild: Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          secondChild: Text(description),
                          crossFadeState: _descExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 160),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(_descExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded),
                        onPressed: () =>
                            setState(() => _descExpanded = !_descExpanded),
                        tooltip: _descExpanded ? 'Collapse' : 'Expand',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _snack(BuildContext context, String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
}

class _TripleCell extends StatelessWidget {
  final String label;
  final String value;
  final int maxLines;
  const _TripleCell({
    required this.label,
    required this.value,
    this.maxLines = 2,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _KV {
  final String key;
  final String value;
  final Color? valueColor;
  const _KV(this.key, this.value, {this.valueColor});
}

class _KvRow extends StatelessWidget {
  final _KV row;
  const _KvRow(this.row);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              row.key,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              row.value,
              style: TextStyle(color: row.valueColor ?? cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

/* ─────────────────────────────  HELPERS  ───────────────────────────── */

String _money(double v) {
  return '\$${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)}';
}

String _formatCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

String _extractBrand(String title) {
  // Simple brand extraction logic - can be enhanced
  final commonBrands = ['iPhone', 'Samsung', 'Sony', 'Nintendo', 'Apple', 'Microsoft', 'HP', 'Dell', 'Lenovo'];
  for (final brand in commonBrands) {
    if (title.toLowerCase().contains(brand.toLowerCase())) {
      return brand;
    }
  }
  return 'Unknown';
}

// Map Chinese category path to English
String _translateCategoryPath(String? categoryPath) {
  if (categoryPath == null || categoryPath.isEmpty) return 'Unknown';
  
  // Category mapping based on the publish page options
  final categoryMap = {
    '电子产品': 'Electronics',
    '服装配饰': 'Fashion & Accessories',
    '家居用品': 'Home & Garden',
    '运动户外': 'Sports & Outdoors',
    '图书文具': 'Books & Stationery',
    '美妆护肤': 'Beauty & Skincare',
    '母婴用品': 'Baby & Kids',
    '其他': 'Others',
    '手机': 'Mobile Phones',
    '电脑': 'Computers',
    '数码相机': 'Digital Cameras',
    '游戏设备': 'Gaming Devices',
    '智能穿戴': 'Smart Wearables',
    '耳机音响': 'Audio & Headphones',
  };
  
  // Replace Chinese terms with English
  String result = categoryPath;
  categoryMap.forEach((chinese, english) {
    result = result.replaceAll(chinese, english);
  });
  
  // Replace the arrow symbol
  result = result.replaceAll(' > ', ' > ');
  
  return result;
}

// Map Chinese condition text to English
String _translateConditionText(String? conditionText) {
  if (conditionText == null || conditionText.isEmpty) return 'Unknown';
  
  final conditionMap = {
    '全新': 'New',
    '几乎全新': 'Like New',
    '良好': 'Good',
    '一般': 'Fair',
    '较差': 'Poor',
  };
  
  return conditionMap[conditionText] ?? conditionText;
}

// Map Chinese usage info to English
String _translateUsageInfo(String? usageText) {
  if (usageText == null || usageText.isEmpty) return 'Unknown';
  
  final usageMap = {
    '天': 'days',
    '周': 'weeks',
    '月': 'months',
    '年': 'years',
    '次': 'times',
    '使用': 'used',
    '购买': 'purchased',
  };
  
  String result = usageText;
  usageMap.forEach((chinese, english) {
    result = result.replaceAll(chinese, english);
  });
  
  return result;
}

// Map Chinese tags to English
List<String> _translateTags(List<String> tags) {
  if (tags.isEmpty) return [];
  
  final tagMap = {
    '苹果': 'Apple',
    '手机': 'Mobile Phone',
    '全新': 'New',
    '未拆封': 'Unopened',
    '钛金色': 'Titanium Gold',
    '个人自用': 'Personal Use',
    '配件齐全': 'Complete Accessories',
    '有发票': 'With Invoice',
    '二手': 'Second Hand',
    '九成新': '90% New',
    '八成新': '80% New',
    '七成新': '70% New',
    '六成新': '60% New',
    '五成新': '50% New',
    '几乎全新': 'Like New',
    '良好': 'Good',
    '一般': 'Fair',
    '较差': 'Poor',
    '电子产品': 'Electronics',
    '服装': 'Clothing',
    '家居': 'Home',
    '运动': 'Sports',
    '图书': 'Books',
    '美妆': 'Beauty',
    '母婴': 'Baby',
    '热门': 'Hot', // Add this mapping for HOT badge
  };
  
  return tags.map((tag) => tagMap[tag] ?? tag).toList();
}

// Map Chinese location to English (basic mapping for common locations)
String _translateLocation(String? location) {
  if (location == null || location.isEmpty) return 'Unknown';
  
  final locationMap = {
    '广东省': 'Guangdong Province',
    '深圳市': 'Shenzhen City',
    '南山区': 'Nanshan District',
    '科技园': 'Technology Park',
    '北京市': 'Beijing City',
    '上海市': 'Shanghai City',
    '广州市': 'Guangzhou City',
    '朝阳区': 'Chaoyang District',
    '海淀区': 'Haidian District',
    '西城区': 'Xicheng District',
    '东城区': 'Dongcheng District',
    '丰台区': 'Fengtai District',
    '石景山区': 'Shijingshan District',
    '门头沟区': 'Mentougou District',
    '房山区': 'Fangshan District',
    '通州区': 'Tongzhou District',
    '顺义区': 'Shunyi District',
    '昌平区': 'Changping District',
    '大兴区': 'Daxing District',
    '怀柔区': 'Huairou District',
    '平谷区': 'Pinggu District',
    '密云区': 'Miyun District',
    '延庆区': 'Yanqing District',
  };
  
  String result = location;
  locationMap.forEach((chinese, english) {
    result = result.replaceAll(chinese, english);
  });
  
  return result;
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: cs.primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

// 显示"敬请期待"对话框的全局方法
void _showComingSoonDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Color(0xFF32C286).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 40,
                color: Color(0xFF32C286),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Online transaction and shipping features are under development, stay tuned!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF32C286),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Got it',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
