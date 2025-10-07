import 'package:flutter/material.dart';
import 'pickup_page.dart';
import 'complete_page.dart';
import 'payment_methods_page.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../chat/domain/usecases/get_chat_list.dart';
import '../../../chat/domain/usecases/create_chat_room.dart';
import '../../../../injection.dart';
import '../../../transaction/domain/usecases/create_inquiry.dart';
import '../../../transaction/domain/usecases/create_transaction_request.dart';
import '../../../transaction/domain/entities/transaction_inquiry.dart';
import '../../../product/domain/entities/product.dart';
import '../../../chat/data/services/chat_websocket_service.dart';

class CheckoutPage extends StatefulWidget {
  final String productName;
  final String productImage;
  final double productPrice;
  final String productId;
  final String sellerId;
  final ProductEntity? product; // Add product entity for real data

  const CheckoutPage({
    Key? key,
    required this.productName,
    required this.productImage,
    required this.productPrice,
    required this.productId,
    required this.sellerId,
    this.product, // Optional product entity
  }) : super(key: key);

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController _inquiryMessageController = TextEditingController();

  @override
  void dispose() {
    _inquiryMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Purchase Inquiry", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.grey.shade100,
      body: ListView(
        padding: EdgeInsets.all(12),
        children: [
          _buildSellerInfoSection(),
          SizedBox(height: 12),
          _buildProductSection(),
          SizedBox(height: 12),
          _buildInquirySummary(),
          SizedBox(height: 12),
          _buildInquiryMessageSection(), // 购买咨询消息输入
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(12),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: () => _initiateTransaction(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF32C286),
            padding: EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: Text(
            "Send Booking Request",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildSellerInfoSection() {
    // Get seller info from product entity or use fallback
    final seller = widget.product?.seller;
    final sellerName = seller?.username ?? widget.product?.sellerUsername ?? "Seller";
    final sellerAvatar = seller?.avatar ?? widget.product?.sellerAvatar;
    final avgResponseTime = seller?.avgResponseTime ?? "Usually replies within 1 hour";
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Seller Information",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: sellerAvatar != null && sellerAvatar.isNotEmpty
                    ? NetworkImage(sellerAvatar)
                    : null,
                child: sellerAvatar == null || sellerAvatar.isEmpty
                    ? Icon(Icons.person, color: Colors.grey.shade600)
                    : null,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sellerName,
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                    Text(
                      "Online · $avgResponseTime",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Online",
                  style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductSection() {
    // Get product image from product entity or use fallback
    final productImage = widget.product?.mainImage ?? widget.productImage;
    final isNetworkImage = productImage.startsWith('http');
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: _boxDecoration(),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade200,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isNetworkImage
                  ? Image.network(
                      productImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.image_not_supported,
                        color: Colors.grey.shade400,
                      ),
                    )
                  : Image.asset(
                      productImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.image_not_supported,
                        color: Colors.grey.shade400,
                      ),
                    ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.productName,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 4),
                Text("Qty: 1", style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Text("\$${widget.productPrice}",
              style: TextStyle(color: Colors.red, fontSize: 14)),
        ],
      ),
    );
  }


  Widget _buildInquirySummary() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Inquiry Information",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          SizedBox(height: 8),
          _buildSummaryRow("Product Price", "\$${widget.productPrice}"),
          _buildSummaryRow("Inquiry Type", "Purchase Inquiry"),
          _buildSummaryRow("Transaction Method", "Offline Transaction"),
          Divider(),
          _buildSummaryRow("Expected Reply Time", "Within 1 hour", isBold: true),
        ],
      ),
    );
  }

  Widget _buildInquiryMessageSection() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Purchase Inquiry Message",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          SizedBox(height: 8),
          TextField(
            controller: _inquiryMessageController,
            decoration: InputDecoration(
              hintText: "Hello, is this product still available? Can you offer a discount?",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            maxLines: 3,
          ),
          SizedBox(height: 8),
          Text(
            "After sending the inquiry, the seller will reply to you through chat",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }



  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.black,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.black,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
    );
  }

  void _initiateTransaction(BuildContext context) {
    // 发起交易申请
    _sendTransactionRequest(context);
  }

  Future<void> _sendTransactionRequest(BuildContext context) async {
    final message = _inquiryMessageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter inquiry message")),
      );
      return;
    }

    // 显示发送中的对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF32C286)),
              ),
              SizedBox(height: 20),
              Text(
                'Sending inquiry...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );

    try {
      // 首先检查是否已存在聊天室
      String? chatRoomId = await _findExistingChatRoom();
      
      // 如果不存在聊天室，则创建新的
      if (chatRoomId == null) {
        final createChatRoom = ServiceLocator().get<CreateChatRoom>();
        final chatRoomResult = await createChatRoom.call(
          sellerId: widget.sellerId,
        );
        chatRoomId = chatRoomResult['chatRoomId'] as String;
      }
      
      // 发起交易申请
      final createTransactionRequest = ServiceLocator().get<CreateTransactionRequest>();
      final result = await createTransactionRequest.call(
        chatRoomId: chatRoomId!,
        productId: widget.productId,
        message: message,
      );

      // 发送交易申请消息到聊天室
      await _sendTransactionRequestMessage(chatRoomId, result['transactionId'], message);

      // 关闭发送中对话框
      Navigator.of(context).pop();

      // 显示成功对话框
      _showTransactionRequestSuccessDialog(context, result, chatRoomId);
    } catch (e) {
      // 关闭发送中对话框
      Navigator.of(context).pop();
      
      // 显示错误信息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send transaction request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToExistingChat(BuildContext context) async {
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
        if (chatRoom.participant.id == widget.sellerId) {
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
              inquiryType: 'PURCHASE',
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

  void _showPurchaseSuccessDialog(BuildContext context, TransactionInquiryEntity result) {
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
                  Icons.check,
                  size: 40,
                  color: Color(0xFF32C286),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Inquiry Sent Successfully!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'The seller will reply to your inquiry as soon as possible. Please check your chat messages.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // 关闭成功对话框
                        Navigator.of(context).pop(); // 返回上一页
                      },
                      child: Text('Back'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // 关闭成功对话框
                        // 跳转到聊天页面
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              chatRoomId: result.chatRoomId,
                              transactionId: result.transactionId,
                              inquiryType: 'PURCHASE',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF32C286),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'View Chat',
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
            ],
          ),
        );
      },
    );
  }

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

  // 查找现有的聊天室
  Future<String?> _findExistingChatRoom() async {
    try {
      final getChatList = ServiceLocator().get<GetChatList>();
      final chatList = await getChatList.call(page: 1, size: 100);
      
      // 查找与当前卖家相关的聊天室
      for (final chatRoom in chatList.content) {
        if (chatRoom.participant.id == widget.sellerId) {
          return chatRoom.chatRoomId;
        }
      }
      return null;
    } catch (e) {
      print('Failed to find existing chat room: $e');
      return null;
    }
  }

  // 发送交易申请消息到聊天室
  Future<void> _sendTransactionRequestMessage(String chatRoomId, String transactionId, String message) async {
    try {
      // 通过WebSocket发送TRANSACTION_REQUEST类型的消息
      print('Sending transaction request message to chat room: chatRoomId=$chatRoomId, transactionId=$transactionId, message=$message');
      
      // 获取WebSocket服务实例
      final chatWebSocketService = ServiceLocator().get<ChatWebSocketService>();
      
      // 发送TRANSACTION_REQUEST消息
      chatWebSocketService.sendMessage(
        chatRoomId: chatRoomId,
        type: 'TRANSACTION_REQUEST',
        content: message,
        transactionId: transactionId,
        productId: widget.productId,
      );
      
      print('Transaction request message sent to chat room');
    } catch (e) {
      print('Failed to send transaction request message: $e');
      // 即使WebSocket发送失败，也不应该阻止整个流程
      // 因为交易申请已经通过API创建了
    }
  }

  void _showTransactionRequestSuccessDialog(BuildContext context, Map<String, dynamic> result, String chatRoomId) {
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
                  Icons.check_circle_outline,
                  size: 40,
                  color: Color(0xFF32C286),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Transaction Request Sent',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Your transaction request has been sent to the seller. Please wait for the seller\'s response.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // 关闭成功对话框
                        Navigator.of(context).pop(); // 返回商品详情页
                      },
                      child: Text('Back to Product'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // 关闭成功对话框
                        // 跳转到聊天页面
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              chatRoomId: chatRoomId,
                              transactionId: result['transactionId'],
                              inquiryType: 'PURCHASE',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF32C286),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'View Chat',
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
            ],
          ),
        );
      },
    );
  }
}
