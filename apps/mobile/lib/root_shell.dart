// lib/root_shell.dart
import 'package:flutter/material.dart';

// Pages
import 'package:mobile/features/product/presentation/pages/home_page.dart';
import 'package:mobile/features/nearby/presentation/pages/nearby_page.dart';
import 'package:mobile/features/chat/presentation/pages/chat_page.dart';
import 'package:mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:mobile/features/post/presentation/pages/create_post_page.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  // Brand
  static const kGreen = Color(0xFF32C286);
  static const kBadgeRed = Color(0xFFFF4E4E);

  int _index = 0;
  bool _fabActive = false;
  int _chatUnread = 7; // demo

  // Search controller lives in the shell (shared with HomePage)
  final _search = TextEditingController();

  // Demo header text
  final String _username = 'Richard';
  final String _location = 'Rosebery, New South Wales';

  late final List<Widget> _pages = [
    HomePage(searchController: _search), // Home reads this controller
    const NearbyPage(),
    const ChatPage(),
    const ProfilePage(),
  ];

  void _setIndex(int i) => setState(() => _index = i);

  @override
  void initState() {
    super.initState();
    // Rebuild while typing so Home can re-read controller.text
    _search.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_index == 0 && mounted) setState(() {});
  }

  @override
  void dispose() {
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themed = Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(primary: kGreen),
    );

    return Theme(
      data: themed,
      child: Scaffold(
        extendBody: true,

        // HEADER (+ pages kept alive)
        body: Column(
          children: [
            if (_index == 0)
              _HomeGreenHeader(
                username: _username,
                location: _location,
                controller: _search,
              ),
            // Keep states of all tabs
            Expanded(
              child: IndexedStack(index: _index, children: _pages),
            ),
          ],
        ),

        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: _AnimatedPostFab(
          active: _fabActive,
          notchMargin: 8,
          onHighlightChanged: (h) => setState(() => _fabActive = h),
          onTap: () async {
            setState(() => _fabActive = true);
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreatePostPage()),
            );
            if (mounted) setState(() => _fabActive = false);
          },
        ),

        bottomNavigationBar: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor:
                MediaQuery.of(context).textScaleFactor.clamp(0.9, 1.0),
          ),
          child: SafeArea(
            top: false,
            child: BottomAppBar(
              shape: const CircularNotchedRectangle(),
              notchMargin: 8,
              elevation: 6,
              child: SizedBox(
                height: 62,
                child: Row(
                  children: [
                    Expanded(
                      child: _IconOnlyNavItem(
                        icon: Icons.home_outlined,
                        selectedIcon: Icons.home,
                        label: 'Home',
                        selected: _index == 0,
                        onTap: () => _setIndex(0),
                        selectedColor: kGreen,
                      ),
                    ),
                    Expanded(
                      child: _IconOnlyNavItem(
                        icon: Icons.place_outlined,
                        selectedIcon: Icons.place,
                        label: 'Nearby',
                        selected: _index == 1,
                        onTap: () => _setIndex(1),
                        selectedColor: kGreen,
                      ),
                    ),
                    const SizedBox(width: 72), // FAB notch spacer
                    Expanded(
                      child: _IconOnlyNavItem(
                        icon: Icons.chat_bubble_outline,
                        selectedIcon: Icons.chat_bubble,
                        label: 'Chat',
                        selected: _index == 2,
                        onTap: () => _setIndex(2),
                        selectedColor: kGreen,
                        badgeCount: _chatUnread,
                        badgeColor: kBadgeRed,
                      ),
                    ),
                    Expanded(
                      child: _IconOnlyNavItem(
                        icon: Icons.person_outline,
                        selectedIcon: Icons.person,
                        label: 'Me',
                        selected: _index == 3,
                        onTap: () => _setIndex(3),
                        selectedColor: kGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The green header that used to live in HomePage.
class _HomeGreenHeader extends StatelessWidget {
  final String username;
  final String location;
  final TextEditingController controller;

  const _HomeGreenHeader({
    required this.username,
    required this.location,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.primary,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea( // keep below notch
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search + small square avatar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search here …',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    // optional: onSubmitted to close keyboard
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  ),
                ),
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 28,
                    height: 28,
                    color: Colors.white.withOpacity(.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Dear, $username',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(location, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Center FAB with white halo; halo turns green when active.
class _AnimatedPostFab extends StatelessWidget {
  final bool active;
  final double notchMargin;
  final ValueChanged<bool>? onHighlightChanged;
  final VoidCallback onTap;

  const _AnimatedPostFab({
    required this.active,
    required this.onTap,
    required this.notchMargin,
    this.onHighlightChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: active ? cs.primary : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onHighlightChanged: onHighlightChanged,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: EdgeInsets.all(notchMargin),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary,
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }
}

/// Compact icon+label nav item with optional badge.
class _IconOnlyNavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? badgeCount;
  final Color? badgeColor;
  final Color selectedColor;

  const _IconOnlyNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount,
    this.badgeColor,
    this.selectedColor = const Color(0xFF32C286),
  });

  @override
  Widget build(BuildContext context) {
    const double itemHeight = 56;
    final cs = Theme.of(context).colorScheme;
    final inactive = cs.onSurfaceVariant;
    final showBadge = (badgeCount ?? 0) > 0;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        height: itemHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  size: 24,
                  color: selected ? selectedColor : inactive,
                ),
                if (showBadge)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: _Badge(
                      count: badgeCount!,
                      color: badgeColor ?? const Color(0xFFFF4E4E),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                height: 1.0,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? selectedColor : inactive,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  final Color color;
  const _Badge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : '$count';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
      ),
    );
  }
}
