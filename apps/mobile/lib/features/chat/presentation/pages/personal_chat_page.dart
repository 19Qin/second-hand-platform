import 'package:flutter/material.dart';

// ---- Domain + Data layer
import 'package:mobile/features/chat/domain/entities/chat_message.dart';
import 'package:mobile/features/chat/domain/entities/chat_thread.dart';
import 'package:mobile/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:mobile/features/chat/data/repositories/chat_repository_impl.dart';

// ---- Mock (swap with real DS when ready)
import 'package:mobile/features/chat/presentation/mock/chat_mock.dart';

class PersonalChatPage extends StatefulWidget {
  final ChatThreadEntity thread; // pass from chat list
  const PersonalChatPage({super.key, required this.thread});

  @override
  State<PersonalChatPage> createState() => _PersonalChatPageState();
}

class _PersonalChatPageState extends State<PersonalChatPage> {
  late final ChatRepositoryImpl _repo;
  final _ds = ChatFakeDataSource(); // implements ChatRemoteDataSource

  final _input = TextEditingController();
  final _scroll = ScrollController();

  List<ChatMessageEntity> _messages = const [];
  bool _loading = true;
  bool _canSend = false;
  int _unread = 0;
  String? _myId;

  @override
  void initState() {
    super.initState();
    _repo = ChatRepositoryImpl(_ds as ChatRemoteDataSource);

    _unread = _ThreadFields.unreadOf(widget.thread) ?? 0;
    _myId = _ThreadFields.meIdOf(widget.thread) ??
        _ThreadFields.currentUserIdOf(widget.thread);

    _input.addListener(() {
      final can = _input.text.trim().isNotEmpty;
      if (can != _canSend && mounted) setState(() => _canSend = can);
    });

    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final tid = _ThreadFields.idOf(widget.thread);

    final list = await _repo.getMessages(tid);
    setState(() {
      _messages = list;
      _loading = false;
    });

    await _repo.markThreadRead(tid);
    if (mounted) setState(() => _unread = 0);

    await Future.delayed(const Duration(milliseconds: 80));
    _jumpToBottom();
  }

  void _jumpToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent + 200,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;

    final tid = _ThreadFields.idOf(widget.thread);

    final temp = _TempMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      threadId: tid,
      senderId: _myId ?? 'me',
      text: text,
      sentAt: DateTime.now(),
      isMine: true,
      status: ChatMessageStatus.sending,
    );

    setState(() => _messages = List.of(_messages)..add(temp));
    _input.clear();
    _jumpToBottom();

    try {
      final saved = await _repo.sendMessage(tid, text);
      setState(() {
        _messages = List.of(_messages)
          ..removeWhere((m) => m.id == temp.id)
          ..add(saved);
      });
      _jumpToBottom();
    } catch (_) {
      setState(() {
        final i = _messages.indexWhere((m) => m.id == temp.id);
        if (i != -1) {
          _messages[i] = temp.copyWith(status: ChatMessageStatus.failed);
        }
      });
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final name = _ThreadFields.titleOf(widget.thread) ?? 'Chat';
    final uid = _ThreadFields.partnerIdOf(widget.thread) ??
        _ThreadFields.userIdOf(widget.thread) ??
        '—';
    final maskedId = _maskUserId(uid);
    final online = _ThreadFields.onlineOf(widget.thread) ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leadingWidth: 86,
        leading: Row(
          children: [
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            if (_unread > 0)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$_unread',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
          ],
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: online ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            Text(
              'User id: $maskedId',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Report',
            icon: const Icon(Icons.report_gmailerrorred_outlined),
            onPressed: () => _snack('Report user'),
          ),
          IconButton(
            tooltip: 'Call',
            icon: const Icon(Icons.call_outlined),
            onPressed: () => _snack('Call seller'),
          ),
          const SizedBox(width: 4),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    itemCount: 1 + _messages.length, // +1 for product header
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ProductHeaderCard(
                            imageUrl: _ThreadFields.productImageOf(widget.thread) ??
                                _ThreadFields.avatarOf(widget.thread),
                            title: _ThreadFields.titleOf(widget.thread) ?? '—',
                            price: _ThreadFields.productPriceOf(widget.thread),
                            statusText: _ThreadFields.pickupOf(widget.thread) ??
                                'Self–collection available',
                            locationText:
                                _ThreadFields.locationOf(widget.thread) ??
                                    'Rosebery · NSW',
                            onPlaceOrder: () => _snack('Place order'),
                          ),
                        );
                      }

                      // message rows (shift index by 1)
                      final m = _messages[i - 1];
                      final me = m.isMine;
                      final showStamp = _shouldShowStamp(i - 1);
                      final statusText = _statusText(m);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showStamp)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Center(
                                child: Text(
                                  _dateLabel(m.sentAt),
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: me
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              if (!me)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _Avatar.small(
                                      url: _ThreadFields.avatarOf(
                                          widget.thread)),
                                ),
                              Flexible(
                                child: _Bubble(text: m.text, mine: me),
                              ),
                              if (me)
                                Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: _Avatar.me(),
                                ),
                            ],
                          ),
                          if (statusText != null)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Align(
                                alignment: me
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 6),
                        ],
                      );
                    },
                  ),
          ),

          // Composer
          SafeArea(
            top: false,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mic_none_rounded),
                    onPressed: () => _snack('Voice input'),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: 'Type your message …',
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  // Right-side: Emoji / Send toggle
                  IconButton(
                    icon: Icon(
                        _canSend ? Icons.send_rounded : Icons.emoji_emotions_outlined),
                    color: _canSend ? cs.primary : null,
                    tooltip: _canSend ? 'Send' : 'Emoji',
                    onPressed: _canSend ? _send : () => _snack('Emoji'),
                  ),
                  IconButton(
                    icon: Icon(
                        _canSend ? Icons.check_circle_outline : Icons.add_circle_outline),
                    color: _canSend ? cs.primary : null,
                    tooltip: _canSend ? 'Send' : 'More',
                    onPressed: _canSend ? _send : () => _snack('More'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _statusText(ChatMessageEntity m) {
    switch (m.status) {
      case ChatMessageStatus.read:
        return 'was read';
      case ChatMessageStatus.sent:
      case ChatMessageStatus.delivered:
        return null;
      case ChatMessageStatus.sending:
        return 'sending…';
      case ChatMessageStatus.failed:
        return 'failed to send';
    }
  }

  bool _shouldShowStamp(int i) {
    if (i == 0) return true;
    final a = _messages[i - 1].sentAt;
    final b = _messages[i].sentAt;
    final sameDay = a.year == b.year && a.month == b.month && a.day == b.day;
    return !sameDay;
  }

  String _dateLabel(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$m-$d $hh:$mm';
  }

  String _maskUserId(String raw) {
    if (raw.length < 7) return raw;
    final prefix = raw.substring(0, 3);
    final suffix = raw.substring(raw.length - 3);
    return '$prefix **** $suffix';
  }

  void _snack(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
}

/* ------------------------------ Product header ------------------------------ */

class _ProductHeaderCard extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final double? price;
  final String statusText;   // e.g. “Self–collection available”
  final String locationText; // e.g. “Rosebery · NSW”
  final VoidCallback onPlaceOrder;

  const _ProductHeaderCard({
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.statusText,
    required this.locationText,
    required this.onPlaceOrder,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 64,
              height: 64,
              child: (imageUrl ?? '').isEmpty
                  ? ColoredBox(color: cs.primary.withOpacity(.10))
                  : (imageUrl!.startsWith('http')
                      ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              ColoredBox(color: cs.primary.withOpacity(.10)),
                        )
                      : Image.asset(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              ColoredBox(color: cs.primary.withOpacity(.10)),
                        )),
            ),
          ),
          const SizedBox(width: 12),

          // texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (price != null)
                  Text(
                    _money(price!),
                    style: const TextStyle(
                      color: Color(0xFFE03636),
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  locationText,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // CTA
          FilledButton(
            onPressed: onPlaceOrder,
            style: FilledButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('Place order'),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------ Helpers ------------------------------ */

class _ThreadFields {
  static String idOf(ChatThreadEntity t) => t.id;

  static String? titleOf(ChatThreadEntity t) {
    final d = t as dynamic;
    try { return d.peerName as String?; } catch (_) {}
    try { return d.title as String?; } catch (_) {}
    try { return d.partnerName as String?; } catch (_) {}
    return null;
  }

  static String? userIdOf(ChatThreadEntity t) {
    final d = t as dynamic;
    try { return d.userId as String?; } catch (_) {}
    return null;
  }

  static String? partnerIdOf(ChatThreadEntity t) {
    final d = t as dynamic;
    try { return d.partnerId as String?; } catch (_) {}
    return null;
  }

  static String? meIdOf(ChatThreadEntity t) {
    final d = t as dynamic;
    try { return d.meId as String?; } catch (_) {}
    return null;
  }

  static String? currentUserIdOf(ChatThreadEntity t) {
    final d = t as dynamic;
    try { return d.currentUserId as String?; } catch (_) {}
    return null;
  }

  static bool? onlineOf(ChatThreadEntity t) {
    final d = t as dynamic;
    try { return d.isOnline as bool?; } catch (_) {}
    return null;
  }

  static int? unreadOf(ChatThreadEntity t) {
    final d = t as dynamic;
    try { return d.unreadCount as int?; } catch (_) {}
    try { return d.unread as int?; } catch (_) {}
    return null;
  }

  static String? avatarOf(ChatThreadEntity t) {
    final d = t as dynamic;
    try { return d.peerAvatarUrl as String?; } catch (_) {}
    try { return d.avatar as String?; } catch (_) {}
    try { return d.partnerAvatar as String?; } catch (_) {}
    return null;
  }

  // Product details (best-effort—safe across various thread shapes)
  static String? productImageOf(ChatThreadEntity t) {
    final d = t as dynamic;
    try { return d.productImage as String?; } catch (_) {}
    try { return d.productThumb as String?; } catch (_) {}
    try { return d.imageUrl as String?; } catch (_) {}
    return null;
  }

  static double? productPriceOf(ChatThreadEntity t) {
    final d = t as dynamic;
    try { return (d.productPrice as num?)?.toDouble(); } catch (_) {}
    try { return (d.price as num?)?.toDouble(); } catch (_) {}
    return null;
  }

  static String? locationOf(ChatThreadEntity t) {
    final d = t as dynamic;
    try { return d.location as String?; } catch (_) {}
    try { return d.sellerLocation as String?; } catch (_) {}
    return null;
  }

  static String? pickupOf(ChatThreadEntity t) {
    final d = t as dynamic;
    try { return d.pickupNote as String?; } catch (_) {}
    try { return d.fulfillment as String?; } catch (_) {}
    return null;
  }
}

/* ------------------------------ UI bits ------------------------------ */

class _Bubble extends StatelessWidget {
  final String text;
  final bool mine;
  const _Bubble({required this.text, required this.mine});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = mine ? cs.primary : cs.surfaceContainerHighest;
    final fg = mine ? Colors.white : cs.onSurface;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(14),
          topRight: const Radius.circular(14),
          bottomLeft: Radius.circular(mine ? 14 : 4),
          bottomRight: Radius.circular(mine ? 4 : 14),
        ),
      ),
      child: Text(text, style: TextStyle(color: fg, fontSize: 15)),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final bool me;
  const _Avatar._({this.url, required this.me});

  factory _Avatar.small({String? url}) => _Avatar._(url: url, me: false);
  factory _Avatar.me() => const _Avatar._(me: true);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 16,
      backgroundColor: cs.primary.withOpacity(.12),
      backgroundImage:
          (url != null && url!.isNotEmpty && url!.startsWith('http'))
              ? NetworkImage(url!)
              : null,
      child: (url == null || url!.isEmpty)
          ? Icon(me ? Icons.person : Icons.person_outline, color: cs.primary)
          : null,
    );
  }
}

/* ---------------------- Temp outgoing message model ---------------------- */

class _TempMessage implements ChatMessageEntity {
  @override
  final String id;
  @override
  final String threadId;
  @override
  final String senderId;
  @override
  final String text;
  @override
  final DateTime sentAt;
  @override
  final bool isMine;
  @override
  final ChatMessageStatus status;

  _TempMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.text,
    required this.sentAt,
    required this.isMine,
    required this.status,
  });

  _TempMessage copyWith({ChatMessageStatus? status}) => _TempMessage(
        id: id,
        threadId: threadId,
        senderId: senderId,
        text: text,
        sentAt: sentAt,
        isMine: isMine,
        status: status ?? this.status,
      );
}

/* ------------------------------ misc ------------------------------ */

String _money(double v) =>
    '\$${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)}';
