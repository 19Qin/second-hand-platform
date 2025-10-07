import 'package:flutter/material.dart';
import '../../domain/entities/chat_room.dart';
import 'chat_page.dart';
import '../../../transaction/presentation/pages/transaction_flow_demo_page.dart';
import '../../../../injection.dart';
import '../../domain/usecases/get_chat_list.dart';
import '../../../../core/auth/auth_state_manager.dart';

class ChatListPage extends StatefulWidget {
  final VoidCallback? onUnreadCountChanged;
  
  const ChatListPage({Key? key, this.onUnreadCountChanged}) : super(key: key);

  @override
  ChatListPageState createState() => ChatListPageState();
}

class ChatListPageState extends State<ChatListPage> {
  List<ChatRoomEntity> _chatRooms = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }
  
  // 公共刷新方法
  void refreshChatList() {
    _loadChatRooms();
  }

  Future<void> _loadChatRooms() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final getChatList = ServiceLocator().get<GetChatList>();
      final chatList = await getChatList.call(page: 1, size: 20);
      
      print('🔍 Got ${chatList.content.length} chat rooms');
      setState(() {
        _chatRooms = chatList.content;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading chat rooms: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // 移除默认的返回按钮
        actions: [
          IconButton(
            icon: Icon(Icons.play_arrow, color: Colors.black),
            onPressed: () => _showTransactionFlowDemo(),
          ),
          IconButton(
            icon: Icon(Icons.search, color: Colors.black),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.black),
            onPressed: () => _showMoreOptions(),
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _chatRooms.isEmpty
                  ? _buildEmptyState()
                  : _buildChatList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'Failed to load chat list',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadChatRooms,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
            Text(
              'No chat records',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start chatting with sellers',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      itemCount: _chatRooms.length,
      itemBuilder: (context, index) {
        final chatRoom = _chatRooms[index];
        return _buildChatItem(chatRoom);
      },
    );
  }

  Widget _buildChatItem(ChatRoomEntity chatRoom) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: chatRoom.participant.avatar != null
                  ? NetworkImage(chatRoom.participant.avatar!)
                  : null,
              child: chatRoom.participant.avatar == null
                  ? Icon(Icons.person, color: Colors.grey.shade600)
                  : null,
            ),
            if (chatRoom.participant.isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                chatRoom.participant.username,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (chatRoom.unreadCount > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(0xFF32C286),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  chatRoom.unreadCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            if (chatRoom.product != null) ...[
              Text(
                chatRoom.product!.title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    chatRoom.lastMessage?.content ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: chatRoom.unreadCount > 0
                          ? Colors.black87
                          : Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  _formatTime(chatRoom.lastMessage?.sentAt ?? chatRoom.updatedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            if (chatRoom.transactionStatus != null) ...[
              SizedBox(height: 4),
              _buildTransactionStatusChip(chatRoom.transactionStatus!),
            ],
          ],
        ),
        onTap: () => _openChat(chatRoom),
      ),
    );
  }

  Widget _buildTransactionStatusChip(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'INQUIRY':
        color = Colors.orange;
        text = 'Inquiry';
        icon = Icons.help_outline;
        break;
      case 'AGREED':
        color = Colors.blue;
        text = 'Agreed';
        icon = Icons.check_circle_outline;
        break;
      case 'COMPLETED':
        color = Colors.green;
        text = 'Completed';
        icon = Icons.done_all;
        break;
      case 'CANCELLED':
        color = Colors.red;
        text = 'Cancelled';
        icon = Icons.cancel_outlined;
        break;
      default:
        color = Colors.grey;
        text = status;
        icon = Icons.info_outline;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  void _openChat(ChatRoomEntity chatRoom) async {
    final inquiryType = chatRoom.transactionId != null ? 'PURCHASE' : 'INFO';
    print('🔍 Opening chat: ${chatRoom.chatRoomId}, transactionId: ${chatRoom.transactionId}, type: $inquiryType');
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          chatRoomId: chatRoom.chatRoomId,
          transactionId: chatRoom.transactionId,
          inquiryType: inquiryType,
        ),
      ),
    );
    // 从聊天页面返回后，刷新聊天列表和未读消息数量
    _loadChatRooms();
    // 通知父组件刷新未读消息数量
    if (widget.onUnreadCountChanged != null) {
      widget.onUnreadCountChanged!();
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Search chat records'),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Enter keywords to search',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement search functionality
            },
            child: Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showTransactionFlowDemo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionFlowDemoPage(),
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.play_arrow),
              title: Text('Transaction Flow Demo'),
              onTap: () {
                Navigator.pop(context);
                _showTransactionFlowDemo();
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Notification Settings'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement notification settings
              },
            ),
            ListTile(
              leading: Icon(Icons.block),
              title: Text('Block User'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement block functionality
              },
            ),
            ListTile(
              leading: Icon(Icons.report),
              title: Text('Report'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement report functionality
              },
            ),
          ],
        ),
      ),
    );
  }
}
