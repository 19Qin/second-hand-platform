import 'package:flutter/material.dart';
import 'chat_list_page.dart';
import 'chat_page.dart';

class ChatRoutes {
  static const String chatList = '/chat/list';
  static const String chat = '/chat';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case chatList:
        return MaterialPageRoute(
          builder: (_) => ChatListPage(),
          settings: settings,
        );
      case chat:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ChatPage(
            chatRoomId: args?['chatRoomId'] ?? '',
            transactionId: args?['transactionId'],
            inquiryType: args?['inquiryType'],
          ),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Page not found: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
