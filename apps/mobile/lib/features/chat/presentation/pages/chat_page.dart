import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/chat_thread.dart';
import '../../domain/usecases/get_threads.dart';
import '../widgets/chat_thread_tile.dart';
import 'personal_chat_page.dart';

// Fake data source for demo
import '../mock/chat_mock.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final GetThreads _getThreads;
  late Future<List<ChatThreadEntity>> _future;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    final ds = ChatFakeDataSource(); // swap with real remote later
    final repo = ChatRepositoryImpl(ds);
    _getThreads = GetThreads(repo);
    _future = _getThreads();
  }

  void _search(String text) {
    setState(() {
      _keyword = text.trim();
      _future = _getThreads(keyword: _keyword.isEmpty ? null : _keyword);
    });
  }

  @override
  Widget build(BuildContext context) {
    final divider = Colors.grey.shade200;

    return Scaffold(
      backgroundColor: Colors.white, // ← page background
      appBar: AppBar(
        backgroundColor: Colors.white,        // ← white AppBar
        foregroundColor: Colors.black,         // icons/text dark
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,  // kill M3 tint
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark, // dark status bar icons
        title: const Text('Chat'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search chat …',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                filled: true,
                fillColor: Colors.white, // input background stays white
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: divider),
                ),
              ),
              onChanged: _search,
            ),
          ),
          Divider(height: 1, color: divider),
          Expanded(
            child: FutureBuilder<List<ChatThreadEntity>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Failed: ${snap.error}'));
                }
                final threads = snap.data ?? const <ChatThreadEntity>[];
                if (threads.isEmpty) {
                  return const Center(child: Text('No chats'));
                }
                return ListView.separated(
                  itemBuilder: (_, i) => ChatThreadTile(
                    thread: threads[i],
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => PersonalChatPage(thread: threads[i]),
                      ));
                    },
                  ),
                  separatorBuilder: (_, __) => Divider(height: 1, color: divider),
                  itemCount: threads.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
