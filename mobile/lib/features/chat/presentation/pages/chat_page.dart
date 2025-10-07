import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:async';
import '../../domain/entities/chat_room.dart';
import '../../../checkout/presentation/pages/pickup_page.dart';
import '../../../checkout/presentation/pages/seller_pickup_page.dart';
import '../../../transaction/presentation/pages/transaction_status_page.dart';
import '../../../../injection.dart';
import '../../domain/usecases/get_chat_messages.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/usecases/mark_as_read.dart';
import '../../domain/usecases/recall_message.dart';
import '../../domain/usecases/upload_chat_file.dart';
import '../../../transaction/domain/usecases/respond_to_transaction_request.dart';
import '../../../transaction/domain/usecases/get_transactions.dart';
import '../../../../core/auth/token_manager.dart';

class ChatPage extends StatefulWidget {
  final String chatRoomId;
  final String? transactionId;
  final String? inquiryType; // PURCHASE or INFO

  const ChatPage({
    Key? key,
    required this.chatRoomId,
    this.transactionId,
    this.inquiryType,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  List<MessageEntity> _messages = [];
  bool _isLoading = false;
  bool _showTransactionAgreement = false;
  String _participantName = 'Loading...'; // Participant's name
  String? _participantAvatar; // Participant's avatar
  String? _currentUserAvatar; // Current user avatar
  String? _currentUserName; // Current user name
  List<Map<String, dynamic>> _discussedProducts = []; // Discussed products info
  Map<String, String> _messageProductMap = {}; // Message ID to product ID mapping
  Map<String, dynamic>? _currentProduct; // Current chat room associated product info
  
  // 录音相关状态
  bool _isRecording = false;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _checkTransactionStatus();
    _loadCurrentUserInfo();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final getChatMessages = ServiceLocator().get<GetChatMessages>();
      
      final messageList = await getChatMessages.call(
        chatRoomId: widget.chatRoomId,
        page: 1,
        size: 20,
      );
      
      print('🔍 Got ${messageList.messages.length} messages for chat ${widget.chatRoomId}');
      setState(() {
        // Reverse message list to show latest messages at bottom
        _messages = messageList.messages.reversed.toList();
        _isLoading = false;
      });
      
      // Extract discussed products info from response
      if (messageList.chatInfo.discussedProducts != null) {
        _discussedProducts = messageList.chatInfo.discussedProducts!;
        print('🔍 Loaded discussed products: ${_discussedProducts.length}');
      }
      
      // Get participant info from messages (get senderName from first message if not sent by self)
      if (_messages.isNotEmpty) {
        for (final message in _messages) {
          if (!message.isFromMe) {
            _participantName = message.senderName;
            break;
          }
        }
        // If all messages are sent by self, show default name
        if (_participantName == 'Loading...') {
          _participantName = 'Chat';
        }
      }
      
      // Get participant info from chat room info
      if (messageList.chatInfo.participant.username.isNotEmpty) {
        _participantName = messageList.chatInfo.participant.username;
        _participantAvatar = messageList.chatInfo.participant.avatar;
      }
      
      // Get current product info from chat room info
      if (messageList.chatInfo.product != null) {
        _currentProduct = {
          'id': messageList.chatInfo.product!.id,
          'title': messageList.chatInfo.product!.title,
          'price': messageList.chatInfo.product!.price,
          'mainImage': messageList.chatInfo.product!.mainImage,
          'status': messageList.chatInfo.product!.status,
        };
        print('🔍 Loaded current product: ${_currentProduct!['title']}');
      }
      
      // Mark messages as read
      _markAsRead();
      
      // Scroll to bottom to show latest messages
      _scrollToBottom();
    } catch (e) {
      print('❌ Error loading messages: $e');
      setState(() {
        _isLoading = false;
      });
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load messages: $e')),
      );
    }
  }

  void _checkTransactionStatus() {
    // No longer show old transaction request dialog, now using new TRANSACTION_REQUEST message type
    print('🔍 Using new transaction request message system');
  }

  // Get current user info
  Future<void> _loadCurrentUserInfo() async {
    try {
      final userInfo = await TokenManager.instance.getUserInfo();
      if (userInfo != null) {
        setState(() {
          _currentUserName = userInfo['username'] ?? 'User';
          _currentUserAvatar = userInfo['avatar'] ?? 'https://cdn.fliliy.com/avatar/default.png';
        });
      }
    } catch (e) {
      print('❌ Failed to get current user info: $e');
    }
  }

  // Get correct product info
  Map<String, dynamic> _getProductInfo() {
    // Prioritize current chat room associated product info
    if (_currentProduct != null) {
      return {
        'name': _currentProduct!['title'] ?? 'Product',
        'image': _currentProduct!['mainImage'] ?? 'assets/images/ps5.png',
        'price': (_currentProduct!['price'] ?? 0.0).toDouble(),
      };
    }
    
    // If no current product info, use the first discussed product
    if (_discussedProducts.isNotEmpty) {
      final product = _discussedProducts.first;
      return {
        'name': product['title'] ?? 'Product',
        'image': product['mainImage'] ?? 'assets/images/ps5.png',
        'price': (product['price'] ?? 0.0).toDouble(),
      };
    }
    
    // Default values
    return {
      'name': 'Product',
      'image': 'assets/images/ps5.png',
      'price': 0.0,
    };
  }

  // Get product info for specific message
  Map<String, dynamic> _getProductInfoForMessage(MessageEntity message) {
    // First try to match product from message content
    Map<String, dynamic>? productInfo = _matchProductByContent(message.content);
    
    // If content matching fails, try matching by message timestamp
    if (productInfo == null && _discussedProducts.isNotEmpty) {
      productInfo = _matchProductByTimestamp(message);
    }
    
    // Last fallback: use latest product info
    if (productInfo == null && _discussedProducts.isNotEmpty) {
      productInfo = _discussedProducts.last;
      print('🔍 Using latest product as fallback for message: ${productInfo['title']}');
    }
    
    // If still not found, use current chat room product info
    if (productInfo == null) {
      return _getProductInfo();
    }
    
    return {
      'name': productInfo['title'] ?? 'Product',
      'image': productInfo['mainImage'] ?? 'assets/images/ps5.png',
      'price': (productInfo['price'] ?? 0.0).toDouble(),
    };
  }

  Future<void> _markAsRead() async {
    try {
      final markAsRead = ServiceLocator().get<MarkAsRead>();
      await markAsRead.call(widget.chatRoomId);
      print('🔍 Messages marked as read for chatRoomId: ${widget.chatRoomId}');
    } catch (e) {
      print('❌ Error marking messages as read: $e');
      // Don't show error to user as read function is not critical
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      final sendMessage = ServiceLocator().get<SendMessage>();
      await sendMessage.call(
        chatRoomId: widget.chatRoomId,
        type: 'TEXT',
        content: text,
      );
      
      // Reload message list
      await _loadMessages();
      // Scroll to bottom to show new messages
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  void _showMessageOptions(MessageEntity message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.undo, color: Colors.red),
              title: Text('Recall Message'),
              onTap: () {
                Navigator.pop(context);
                _recallMessage(message);
              },
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _recallMessage(MessageEntity message) async {
    try {
      final recallMessage = ServiceLocator().get<RecallMessage>();
      await recallMessage.call(message.id);
      
      // Reload message list
      await _loadMessages();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message recalled'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recall failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_participantName),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.black),
            onPressed: () => _showMoreOptions(context),
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // 旧的交易申请对话框已移除，现在使用新的TRANSACTION_REQUEST消息类型
          
          // Message list
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading messages...'),
                      ],
                    ),
                  )
                : _buildMessageList(),
          ),
          
          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildTransactionAgreement() {
    return Container(
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              SizedBox(width: 8),
          Text(
            'Purchase Inquiry',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Buyer has sent a purchase inquiry, please confirm if you agree to offline transaction',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade600,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showAgreeTransactionDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    'Agree',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showRejectTransactionDialog(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red),
                    padding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    'Reject',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start a conversation!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(MessageEntity message) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: message.isFromMe 
            ? CrossAxisAlignment.end 
            : CrossAxisAlignment.start,
        children: [
        Row(
          mainAxisAlignment: message.isFromMe 
              ? MainAxisAlignment.end 
              : MainAxisAlignment.start,
          children: [
            if (!message.isFromMe) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade300,
                child: Icon(Icons.person, size: 16),
              ),
              SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: message.isFromMe 
                    ? CrossAxisAlignment.end 
                    : CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onLongPress: message.isFromMe ? () => _showMessageOptions(message) : null,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: message.isFromMe 
                            ? Color(0xFF32C286) 
                            : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!message.isFromMe)
                            Text(
                              message.senderName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          SizedBox(height: 2),
                          _buildMessageContent(message),
                          SizedBox(height: 4),
                          Text(
                            _formatTime(message.sentAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: message.isFromMe 
                                  ? Colors.white.withOpacity(0.8)
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  if (message.isFromMe)
                    _buildMessageStatusText(message.status)
                  else
                    _buildMessageReadStatus(message),
                ],
              ),
            ),
            if (message.isFromMe) ...[
              SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF32C286),
                child: Icon(Icons.person, size: 16, color: Colors.white),
              ),
            ],
          ],
        ),
        ],
      ),
    );
  }

  Widget _buildMessageStatusText(String status) {
    String statusText;
    
    switch (status.toUpperCase()) {
      case 'SENT':
        statusText = 'unread';
        break;
      case 'DELIVERED':
        statusText = 'unread';
        break;
      case 'READ':
        statusText = 'has read';
        break;
      default:
        statusText = 'unread';
    }
    
    return Text(
      statusText,
      style: TextStyle(
        fontSize: 10,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildMessageReadStatus(MessageEntity message) {
    // 对于对方发送的消息，我们需要显示我们是否已读
    // 这里可以根据实际需求来实现，比如通过消息的已读状态来判断
    // 暂时显示一个简单的已读状态
    return Text(
      'read',
      style: TextStyle(
        fontSize: 10,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.grey.shade600),
            onPressed: () => _showAttachmentOptions(),
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (text) => _sendMessage(),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send, color: Color(0xFF32C286)),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    // 调试信息
    print('🔍 Time Debug:');
    print('  Now: $now');
    print('  Message time: $dateTime');
    print('  Difference: ${difference.inHours} hours, ${difference.inMinutes} minutes');
    
    // 如果时间差小于1分钟，显示"Just now"
    if (difference.inSeconds < 60) {
      return 'Just now';
    }
    // 如果时间差小于1小时，显示分钟
    else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }
    // 如果时间差小于24小时，显示小时
    else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    }
    // 如果时间差小于7天，显示天数
    else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    }
    // 超过7天，显示具体日期
    else {
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }


  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (kIsWeb) ...[
              // Web environment prompt
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Image and voice messages are not supported in web environment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please use mobile device for full functionality',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Mobile environment options
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.blue),
                title: Text('Select Image'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.green),
                title: Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.mic, color: Colors.red),
                title: Text(_isRecording ? 'Stop Recording' : 'Voice Message'),
                onTap: () {
                  Navigator.pop(context);
                  if (_isRecording) {
                    _stopRecording();
                  } else {
                    _startRecording();
                  }
                },
              ),
            ],
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.search),
              title: Text('Search Chat Records'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement search functionality
              },
            ),
            ListTile(
              leading: Icon(Icons.image),
              title: Text('View Images'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement image viewing
              },
            ),
            ListTile(
              leading: Icon(Icons.download),
              title: Text('Export Chat Records'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement export functionality
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAgreeTransactionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Agree Transaction'),
        content: Text('Are you sure you want to agree to offline transaction with the buyer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _agreeTransaction();
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showRejectTransactionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Transaction'),
        content: Text('Are you sure you want to reject the transaction with the buyer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectTransaction();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _agreeTransaction() {
    // TODO: Call agree transaction API
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transaction agreed, waiting for buyer confirmation')),
    );
    
    setState(() {
      _showTransactionAgreement = false;
      // Show buyer pickup option
      _showBuyerPickupOption();
    });
  }

  void _showBuyerPickupOption() {
    // Show buyer pickup option
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 40,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Seller has agreed to the transaction!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'You can now start the pickup process, the system will generate a transaction code for you',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  _navigateToPickup(null);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF32C286),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Start Pickup',
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
      ),
    );
  }

  void _navigateToPickup(Map<String, dynamic>? result) {
    // Navigate to pickup page with transaction data
    // Note: This method is for buyers, sellers should use _navigateToSellerPickup
    
    // Get correct product info
    final productInfo = _getProductInfo();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PickupPage(
          productName: productInfo['name'],
          productImage: productInfo['image'],
          productPrice: productInfo['price'],
          transactionId: widget.transactionId,
          transactionCode: result?['transactionCode'],
          sellerName: _participantName,
          sellerAvatar: _participantAvatar,
          sellerPhone: 'NSW', // Example: use NSW instead of phone number
          buyerName: _currentUserName ?? 'User',
          buyerAvatar: _currentUserAvatar,
          buyerPhone: 'NSW', // Example: use NSW instead of phone number
          meetingLocation: productInfo['name'], // Use product name as meeting location identifier
          meetingTime: DateTime.now().add(Duration(hours: 2)),
          status: 'AGREED', // Status after seller agrees
          isSeller: false, // Buyer perspective
        ),
      ),
    );
  }

  void _rejectTransaction() {
    // TODO: Call reject transaction API
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transaction rejected')),
    );
    
    setState(() {
      _showTransactionAgreement = false;
    });
  }

  // Image selection method
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _sendImageMessage(image.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Send image message
  Future<void> _sendImageMessage(String imagePath) async {
    try {
      // Show loading prompt
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uploading image...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Upload image
      final uploadChatFile = ServiceLocator().get<UploadChatFile>();
      final uploadResponse = await uploadChatFile.call(
        filePath: imagePath,
        type: 'image',
      );

      // Get image dimensions
      final file = File(imagePath);
      final fileSize = await file.length();

      // Send image message
      final sendMessage = ServiceLocator().get<SendMessage>();
      await sendMessage.call(
        chatRoomId: widget.chatRoomId,
        type: 'IMAGE',
        content: uploadResponse.url,
        thumbnail: uploadResponse.thumbnail,
        width: 800, // Can be obtained from upload response, simplified here
        height: 600,
        fileSize: fileSize,
      );

      // Reload message list
      await _loadMessages();
      _scrollToBottom();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Start recording
  Future<void> _startRecording() async {
    try {
      // Request microphone permission
      final permission = await Permission.microphone.request();
      if (permission != PermissionStatus.granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Microphone permission required for recording'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Start recording
      await _audioRecorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: '/tmp/voice_${DateTime.now().millisecondsSinceEpoch}.aac',
      );

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      // Start timing
      _startRecordingTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recording started...'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start recording: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Stop recording
  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      
      setState(() {
        _isRecording = false;
        _recordingPath = path;
      });

      if (path != null && _recordingDuration.inSeconds > 0) {
        await _sendVoiceMessage(path);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recording time too short'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to stop recording: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Recording timer
  void _startRecordingTimer() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_isRecording) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _recordingDuration = Duration(seconds: _recordingDuration.inSeconds + 1);
      });

      // Maximum 60 seconds
      if (_recordingDuration.inSeconds >= 60) {
        _stopRecording();
        timer.cancel();
      }
    });
  }

  // Send voice message
  Future<void> _sendVoiceMessage(String voicePath) async {
    try {
      // Show loading prompt
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uploading voice...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Upload voice
      final uploadChatFile = ServiceLocator().get<UploadChatFile>();
      final uploadResponse = await uploadChatFile.call(
        filePath: voicePath,
        type: 'voice',
      );

      // Get file size
      final file = File(voicePath);
      final fileSize = await file.length();

      // Send voice message
      final sendMessage = ServiceLocator().get<SendMessage>();
      await sendMessage.call(
        chatRoomId: widget.chatRoomId,
        type: 'VOICE',
        content: uploadResponse.url,
        duration: _recordingDuration.inSeconds,
        fileSize: fileSize,
      );

      // Reload message list
      await _loadMessages();
      _scrollToBottom();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voice sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send voice: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Build message content
  Widget _buildMessageContent(MessageEntity message) {
    switch (message.type.toUpperCase()) {
      case 'TEXT':
        return Text(
          message.content,
          style: TextStyle(
            color: message.isFromMe ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
        );
      case 'TRANSACTION_REQUEST':
        return _buildTransactionRequestCard(message);
      case 'IMAGE':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                message.content,
                width: 200,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200,
                    height: 150,
                    color: Colors.grey.shade300,
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey.shade600,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 200,
                    height: 150,
                    color: Colors.grey.shade300,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (message.content.isNotEmpty && message.content != '[Message recalled]')
              Text(
                '[Image]',
                style: TextStyle(
                  color: message.isFromMe ? Colors.white : Colors.black87,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        );
      case 'VOICE':
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: message.isFromMe ? Colors.white.withOpacity(0.2) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_arrow,
                color: message.isFromMe ? Colors.white : Colors.grey.shade600,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '${message.duration ?? 0}s',
                style: TextStyle(
                  color: message.isFromMe ? Colors.white : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      default:
        return Text(
          message.content,
          style: TextStyle(
            color: message.isFromMe ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
        );
    }
  }

  // Build transaction request card
  Widget _buildTransactionRequestCard(MessageEntity message) {
    // Match corresponding product info based on message's productId
    Map<String, dynamic>? productInfo;
    
    // First try to match product from message content
    productInfo = _matchProductByContent(message.content);
    
    // If content matching fails, try matching by message timestamp
    if (productInfo == null && _discussedProducts.isNotEmpty) {
      productInfo = _matchProductByTimestamp(message);
    }
    
    // Last fallback: use latest product info
    if (productInfo == null && _discussedProducts.isNotEmpty) {
      productInfo = _discussedProducts.last;
      print('🔍 Using latest product as fallback: ${productInfo['title']}');
    }
    
    // Check transaction status
    String transactionStatus = _getTransactionStatus(message);
    
    return Container(
      width: 320,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: message.isFromMe ? Colors.white.withOpacity(0.1) : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: message.isFromMe ? Colors.white.withOpacity(0.3) : Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shopping_cart,
                color: message.isFromMe ? Colors.white : Colors.blue.shade600,
                size: 20,
              ),
              SizedBox(width: 8),
                  Text(
                    'Booking Request',
                    style: TextStyle(
                      color: message.isFromMe ? Colors.white : Colors.blue.shade800,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            ],
          ),
          SizedBox(height: 12),
          
          // Product info display
          if (productInfo != null) ...[
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isFromMe ? Colors.white.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: message.isFromMe ? Colors.white.withOpacity(0.2) : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  // Product image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      productInfo['mainImage'] ?? 'assets/images/placeholder.png',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey.shade300,
                          child: Icon(Icons.image, color: Colors.grey.shade600),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  // Product info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productInfo['title'] ?? 'Unknown Product',
                          style: TextStyle(
                            color: message.isFromMe ? Colors.white : Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          '\$${productInfo['price']?.toString() ?? '0'}',
                          style: TextStyle(
                            color: message.isFromMe ? Colors.white.withOpacity(0.8) : Colors.green.shade700,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
          ],
          
          // Buyer message
          Text(
            message.content,
            style: TextStyle(
              color: message.isFromMe ? Colors.white.withOpacity(0.9) : Colors.black87,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 12),
          
          // Display different buttons based on transaction status
          _buildTransactionActionButtons(message, transactionStatus),
        ],
      ),
    );
  }

  // Match product info based on message content
  Map<String, dynamic>? _matchProductByContent(String content) {
    if (_discussedProducts.isEmpty) return null;
    
    final lowerContent = content.toLowerCase();
    print('🔍 Matching content: "$content" against ${_discussedProducts.length} products');
    
    // Try to match Macbook
    if (lowerContent.contains('macbook')) {
      try {
        final product = _discussedProducts.firstWhere(
          (product) => product['title']?.toString().toLowerCase().contains('macbook') == true,
        );
        print('🔍 Matched Macbook by content: ${product['title']}');
        return product;
      } catch (e) {
        print('🔍 Macbook not found in discussed products');
      }
    }
    
    // Try to match HUAWEI
    if (lowerContent.contains('huawei') || lowerContent.contains('smart glass')) {
      try {
        final product = _discussedProducts.firstWhere(
          (product) => product['title']?.toString().toLowerCase().contains('huawei') == true,
        );
        print('🔍 Matched HUAWEI by content: ${product['title']}');
        return product;
      } catch (e) {
        print('🔍 HUAWEI not found in discussed products');
      }
    }
    
    // Try to match MSI
    if (lowerContent.contains('msi') || lowerContent.contains('monitor')) {
      try {
        final product = _discussedProducts.firstWhere(
          (product) => product['title']?.toString().toLowerCase().contains('msi') == true,
        );
        print('🔍 Matched MSI by content: ${product['title']}');
        return product;
      } catch (e) {
        print('🔍 MSI not found in discussed products');
      }
    }
    
    // Try to match TV
    if (lowerContent.contains('tv') || lowerContent.contains('television')) {
      try {
        final product = _discussedProducts.firstWhere(
          (product) => product['title']?.toString().toLowerCase().contains('tv') == true,
        );
        print('🔍 Matched TV by content: ${product['title']}');
        return product;
      } catch (e) {
        print('🔍 TV not found in discussed products');
      }
    }
    
    // Try to match Phone
    if (lowerContent.contains('phone') || lowerContent.contains('手机')) {
      try {
        final product = _discussedProducts.firstWhere(
          (product) => product['title']?.toString().toLowerCase().contains('phone') == true,
        );
        print('🔍 Matched Phone by content: ${product['title']}');
        return product;
      } catch (e) {
        print('🔍 Phone not found in discussed products');
      }
    }
    
    print('🔍 No product matched by content');
    return null;
  }

  // Match product info based on message timestamp
  Map<String, dynamic>? _matchProductByTimestamp(MessageEntity message) {
    if (_discussedProducts.isEmpty) return null;
    
    // Try to match most relevant product based on message send time
    // Use more precise strategy: match based on message time order and product discussion time order
    
    // Get all TRANSACTION_REQUEST type messages
    final transactionMessages = _messages.where((m) => m.type == 'TRANSACTION_REQUEST').toList();
    final messageIndex = transactionMessages.indexOf(message);
    
    print('🔍 Transaction message index: $messageIndex, total products: ${_discussedProducts.length}');
    
    if (messageIndex >= 0 && messageIndex < _discussedProducts.length) {
      final product = _discussedProducts[messageIndex];
      print('🔍 Matched product by transaction order: ${product['title']}');
      return product;
    }
    
    // If index is out of range, use the last product (latest)
    if (_discussedProducts.isNotEmpty) {
      final product = _discussedProducts.last;
      print('🔍 Using latest product by timestamp: ${product['title']}');
      return product;
    }
    
    return null;
  }

  // Respond to transaction request
  Future<void> _respondToTransactionRequest(MessageEntity message, String action) async {
    try {
      // Get transaction ID from message
      String? transactionId = message.transactionId ?? widget.transactionId;
      
      // If no transactionId in message, try to get from other sources
      if (transactionId == null) {
        print('⚠️ No transactionId in message, trying to get from other sources');
        
        try {
          // Query latest transaction records
          final getTransactions = ServiceLocator().get<GetTransactions>();
          final transactions = await getTransactions.call(
            type: 'all',
            status: 'PENDING',
            page: 1,
            size: 10,
          );
          
          // Find transactions related to current chat room
          for (final transaction in transactions) {
            // Here we can match transactions based on chat room ID or other conditions
            if (transaction['status'] == 'PENDING') {
              transactionId = transaction['id']?.toString();
              print('✅ Found transactionId from transaction records: $transactionId');
              break;
            }
          }
        } catch (e) {
          print('❌ Failed to query transaction records: $e');
        }
      }
      
      if (transactionId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction ID not found. Please try refreshing the chat.'),
            action: SnackBarAction(
              label: 'Refresh',
              onPressed: () {
                // Refresh chat records
                _loadMessages();
              },
            ),
          ),
        );
        return;
      }

      // Show loading dialog
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
                  'Processing transaction response...',
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

      final respondToTransactionRequest = ServiceLocator().get<RespondToTransactionRequest>();
      final result = await respondToTransactionRequest.call(
        transactionId: transactionId,
        action: action,
        reason: action == 'REJECT' ? 'Seller declined the transaction' : null,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (action == 'AGREE') {
        // Show transaction code
        _showTransactionCodeDialog(result, message);
        // Reload message list to update UI status
        _loadMessages();
      } else {
        // Show rejection success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction request rejected'),
            backgroundColor: Colors.orange,
          ),
        );
        // Reload message list to update UI status
        _loadMessages();
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to respond to transaction: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show transaction code dialog
  void _showTransactionCodeDialog(Map<String, dynamic> result, MessageEntity message) {
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
                'Transaction Agreed',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),
              if (result['transactionCode'] != null) ...[
                Text(
                  'Transaction Code:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Color(0xFF32C286).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFF32C286)),
                  ),
                  child: Text(
                    result['transactionCode'],
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF32C286),
                      letterSpacing: 2,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  result['note'] ?? 'Please provide this code to the seller during the transaction.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ],
              SizedBox(height: 20),
              Container(
                width: double.infinity,
                  child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // After seller clicks agree, should navigate to seller pickup page
                    _navigateToSellerPickupAfterAgree(result, message);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF32C286),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Continue to Pickup',
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

  // Get transaction status
  String _getTransactionStatus(MessageEntity message) {
    // Find system messages related to this transaction request
    for (final msg in _messages) {
      if (msg.type == 'SYSTEM' && 
          (msg.content.contains('Transaction request approved') || 
           msg.content.contains('交易申请已同意')) && 
          (msg.transactionId == message.transactionId || 
           msg.transactionId == null)) { // Allow null transactionId for system messages
        return 'AGREED';
      }
      if (msg.type == 'SYSTEM' && 
          (msg.content.contains('Transaction request rejected') || 
           msg.content.contains('交易申请已拒绝')) && 
          (msg.transactionId == message.transactionId || 
           msg.transactionId == null)) { // Allow null transactionId for system messages
        return 'REJECTED';
      }
    }
    return 'PENDING';
  }


  // Build transaction action buttons
  Widget _buildTransactionActionButtons(MessageEntity message, String status) {
    // For now, use a simple heuristic: if message is from me and it's a transaction request, I'm the buyer
    // Otherwise, I'm the seller responding to the request
    bool isBuyer = message.isFromMe && message.type == 'TRANSACTION_REQUEST';
    
    if (isBuyer) {
      // Buyer perspective
      switch (status) {
        case 'AGREED':
          return Column(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Transaction request approved',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _navigateToBuyerPickup(message),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF32C286),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'View Transaction Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        case 'REJECTED':
          return Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.cancel, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Transaction request rejected',
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        default:
          return Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Waiting for seller response',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
      }
    } else {
      // Seller perspective
      switch (status) {
        case 'AGREED':
          return Column(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Transaction request approved',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _navigateToSellerPickup(message),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF32C286),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Connect Transaction Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        case 'REJECTED':
          return Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.cancel, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Transaction request rejected',
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        default:
          return Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _respondToTransactionRequest(message, 'AGREE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Agree',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _respondToTransactionRequest(message, 'REJECT'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red),
                    padding: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Reject',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
      }
    }
  }

  // Navigate to buyer pickup page
  void _navigateToBuyerPickup(MessageEntity message) async {
    String? transactionId = message.transactionId ?? widget.transactionId;
    
    // If still no transactionId, try to get from transaction records
    if (transactionId == null) {
      try {
        final getTransactions = ServiceLocator().get<GetTransactions>();
        final transactions = await getTransactions.call(
          type: 'all',
          status: 'AGREED',
          page: 1,
          size: 10,
        );
        
        // Try to match transaction by product info from message
        final productInfo = _getProductInfoForMessage(message);
        for (final transaction in transactions) {
          if (transaction['status'] == 'AGREED') {
            // Match by product title or other criteria
            final transactionProduct = transaction['product'];
            if (transactionProduct != null && 
                transactionProduct['title'] == productInfo['name']) {
              transactionId = transaction['id']?.toString();
              print('✅ Found matching transaction ID: $transactionId for product: ${productInfo['name']}');
              break;
            }
          }
        }
        
        // If still no match, don't use a random transaction
        if (transactionId == null) {
          print('❌ No matching transaction found for product: ${productInfo['name']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No matching transaction found. Please try refreshing the chat.'),
              action: SnackBarAction(
                label: 'Refresh',
                onPressed: () => _loadMessages(),
              ),
            ),
          );
          return;
        }
      } catch (e) {
        print('❌ Failed to get transaction ID: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load transaction details: $e')),
        );
        return;
      }
    }
    
    // Get product info for specific message
    final productInfo = _getProductInfoForMessage(message);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PickupPage(
          productName: productInfo['name'],
          productImage: productInfo['image'],
          productPrice: productInfo['price'],
          transactionId: transactionId,
          transactionCode: null, // Buyer needs to view transaction code
          sellerName: _participantName,
          sellerAvatar: _participantAvatar,
          sellerPhone: 'NSW', // Example: use NSW instead of phone number
          buyerName: _currentUserName ?? 'User',
          buyerAvatar: _currentUserAvatar,
          buyerPhone: 'NSW', // Example: use NSW instead of phone number
          meetingLocation: productInfo['name'], // Use product name as meeting location identifier
          meetingTime: DateTime.now().add(Duration(hours: 2)),
          status: 'AGREED',
          isSeller: false, // Buyer perspective
        ),
      ),
    );
  }

  // Navigate to seller pickup page after seller agrees to transaction
  void _navigateToSellerPickupAfterAgree(Map<String, dynamic>? result, MessageEntity message) async {
    String? transactionId = message.transactionId ?? widget.transactionId;
    
    // If still no transactionId, try to get from transaction records
    if (transactionId == null) {
      try {
        final getTransactions = ServiceLocator().get<GetTransactions>();
        final transactions = await getTransactions.call(
          type: 'all',
          status: 'AGREED',
          page: 1,
          size: 10,
        );
        
        // Try to match transaction by product info from message
        final productInfo = _getProductInfoForMessage(message);
        for (final transaction in transactions) {
          if (transaction['status'] == 'AGREED') {
            // Match by product title or other criteria
            final transactionProduct = transaction['product'];
            if (transactionProduct != null && 
                transactionProduct['title'] == productInfo['name']) {
              transactionId = transaction['id']?.toString();
              print('✅ Found matching transaction ID: $transactionId for product: ${productInfo['name']}');
              break;
            }
          }
        }
        
        // If still no match, don't use a random transaction
        if (transactionId == null) {
          print('❌ No matching transaction found for product: ${productInfo['name']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No matching transaction found. Please try refreshing the chat.'),
              action: SnackBarAction(
                label: 'Refresh',
                onPressed: () => _loadMessages(),
              ),
            ),
          );
          return;
        }
      } catch (e) {
        print('❌ Failed to get transaction ID: $e');
      }
    }
    
    // Get product info for specific message
    final productInfo = _getProductInfoForMessage(message);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellerPickupPage(
          productName: productInfo['name'],
          productImage: productInfo['image'],
          productPrice: productInfo['price'],
          buyerName: _participantName,
          buyerAvatar: _participantAvatar,
          buyerPhone: 'NSW', // Example: use NSW instead of phone number
          meetingLocation: productInfo['name'], // Use product name as meeting location identifier
          meetingTime: DateTime.now().add(Duration(hours: 2)),
          transactionId: transactionId,
        ),
      ),
    );
  }

  // Navigate to seller pickup page
  void _navigateToSellerPickup(MessageEntity message) async {
    String? transactionId = message.transactionId ?? widget.transactionId;
    
    // If still no transactionId, try to get from transaction records
    if (transactionId == null) {
      try {
        final getTransactions = ServiceLocator().get<GetTransactions>();
        final transactions = await getTransactions.call(
          type: 'all',
          status: 'AGREED',
          page: 1,
          size: 10,
        );
        
        // Try to match transaction by product info from message
        final productInfo = _getProductInfoForMessage(message);
        for (final transaction in transactions) {
          if (transaction['status'] == 'AGREED') {
            // Match by product title or other criteria
            final transactionProduct = transaction['product'];
            if (transactionProduct != null && 
                transactionProduct['title'] == productInfo['name']) {
              transactionId = transaction['id']?.toString();
              print('✅ Found matching transaction ID: $transactionId for product: ${productInfo['name']}');
              break;
            }
          }
        }
        
        // If still no match, don't use a random transaction
        if (transactionId == null) {
          print('❌ No matching transaction found for product: ${productInfo['name']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No matching transaction found. Please try refreshing the chat.'),
              action: SnackBarAction(
                label: 'Refresh',
                onPressed: () => _loadMessages(),
              ),
            ),
          );
          return;
        }
      } catch (e) {
        print('❌ Failed to get transaction ID: $e');
      }
    }
    
    // Get product info for specific message
    final productInfo = _getProductInfoForMessage(message);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellerPickupPage(
          productName: productInfo['name'],
          productImage: productInfo['image'],
          productPrice: productInfo['price'],
          buyerName: _participantName,
          buyerAvatar: _participantAvatar,
          buyerPhone: 'NSW', // Example: use NSW instead of phone number
          meetingLocation: productInfo['name'], // Use product name as meeting location identifier
          meetingTime: DateTime.now().add(Duration(hours: 2)),
          transactionId: transactionId,
        ),
      ),
    );
  }
}