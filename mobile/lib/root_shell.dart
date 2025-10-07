// lib/root_shell.dart
import 'package:flutter/material.dart';

// Pages
import 'package:mobile/features/product/presentation/pages/home_page_new.dart';
import 'package:mobile/features/nearby/presentation/pages/nearby_page.dart';
import 'package:mobile/features/chat/presentation/pages/chat_list_page.dart';
import 'package:mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:mobile/features/post/presentation/pages/create_post_page.dart';
import 'package:mobile/features/health/presentation/widgets/health_status_banner.dart';
import 'package:mobile/features/product/presentation/pages/favorites_page.dart';

// Dependencies
import 'injection.dart';
import 'features/chat/domain/usecases/get_total_unread_count.dart';
import 'core/auth/auth_state_manager.dart';
import 'core/auth/token_manager.dart';

class RootShell extends StatefulWidget {
  final int initialIndex;
  
  const RootShell({super.key, this.initialIndex = 0});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  // Brand
  static const kGreen = Color(0xFF32C286);
  static const kBadgeRed = Color(0xFFFF4E4E);

  late int _index;
  bool _fabActive = false;
  int _chatUnread = 0;

  // Search controller lives in the shell (shared with HomePage)
  final _search = TextEditingController();

  // User info - will be loaded dynamically
  String _username = 'User';
  final String _location = 'NSW';
  
  // GlobalKeys for accessing refresh methods
  final GlobalKey<HomePageNewState> _homePageKey = GlobalKey<HomePageNewState>();
  final GlobalKey<NearbyPageState> _nearbyPageKey = GlobalKey<NearbyPageState>();
  final GlobalKey<ChatListPageState> _chatListPageKey = GlobalKey<ChatListPageState>();
  final GlobalKey<ProfilePageState> _profilePageKey = GlobalKey<ProfilePageState>();

  late final List<Widget> _pages = [
    HomePageNew(key: _homePageKey, searchController: _search), // Home reads this controller
    NearbyPage(key: _nearbyPageKey),
    ChatListPage(key: _chatListPageKey, onUnreadCountChanged: refreshUnreadCount),
    ProfilePage(key: _profilePageKey),
  ];

  void _setIndex(int i) async {
    // 检查是否需要登录
    if (i == 2 || i == 3) { // Chat or Profile page
      final isGuest = await AuthStateManager.instance.isGuestUser();
      if (isGuest) {
        // Guest user, show login prompt and don't switch
        AuthStateManager.instance.showLoginRequiredDialog(context);
        return;
      }
    }
    
    setState(() => _index = i);
    
    // 根据切换到的页面执行相应的刷新操作
    switch (i) {
      case 0: // Home页面
        _refreshHome();
        _loadUserInfo(); // 刷新用户信息
        break;
      case 1: // Nearby页面
        _refreshNearby();
        break;
      case 2: // Chat页面
        _loadUnreadCount();
        _refreshChatList();
        break;
      case 3: // Profile页面
        _refreshProfile();
        break;
    }
  }

  // 添加一个公共方法来刷新未读消息数量
  void refreshUnreadCount() {
    _loadUnreadCount();
  }
  
  // 刷新各个页面的方法
  void _refreshHome() {
    _homePageKey.currentState?.refreshHome();
  }
  
  void _refreshNearby() {
    _nearbyPageKey.currentState?.refreshNearby();
  }
  
  void _refreshChatList() {
    _chatListPageKey.currentState?.refreshChatList();
  }
  
  void _refreshProfile() {
    _profilePageKey.currentState?.refreshProfile();
  }
  
  // 加载用户信息
  Future<void> _loadUserInfo() async {
    try {
      final tokenManager = TokenManager.instance;
      final userInfo = await tokenManager.getUserInfo();
      if (userInfo != null && userInfo['username'] != null) {
        setState(() {
          _username = userInfo['username'];
        });
      }
    } catch (e) {
      print('Failed to load user info: $e');
      // 保持默认值 'User'
    }
  }

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    // Rebuild while typing so Home can re-read controller.text
    _search.addListener(_onSearchChanged);
    // 加载未读消息数量
    _loadUnreadCount();
    // 加载用户信息
    _loadUserInfo();
  }

  void _onSearchChanged() {
    if (_index == 0 && mounted) setState(() {});
  }

  Future<void> _loadUnreadCount() async {
    try {
      final getTotalUnreadCount = ServiceLocator().get<GetTotalUnreadCount>();
      final unreadCount = await getTotalUnreadCount.call();
      if (mounted) {
        setState(() {
          _chatUnread = unreadCount;
        });
      }
    } catch (e) {
      print('❌❌ Error loading unread count: $e');
      // 如果加载失败，保持当前值
    }
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
        body: SafeArea(
          bottom: false, // 不处理底部安全区域，由底部导航栏单独处理
          child: Column(
            children: [
              // Health status banner
              const HealthStatusBanner(),
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
        ),

        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: _AnimatedPostFab(
          active: _fabActive,
          notchMargin: 8,
          onHighlightChanged: (h) => setState(() => _fabActive = h),
          onTap: () async {
            // 检查是否需要登录
            final isGuest = await AuthStateManager.instance.isGuestUser();
            if (isGuest) {
              // Guest user, show login prompt and don't navigate
              AuthStateManager.instance.showLoginRequiredDialog(context);
              return;
            }
            
            setState(() => _fabActive = true);
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreatePostPage()),
            );
            if (mounted) setState(() => _fabActive = false);
          },
        ),

        // 修改底部导航栏，使其完全贴近底部
        bottomNavigationBar: _CustomBottomNavBar(
          currentIndex: _index,
          onTabSelected: _setIndex,
          chatUnreadCount: _chatUnread,
        ),
      ),
    );
  }
}

/// 自定义底部导航栏，完全贴近底部
class _CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final int chatUnreadCount;

  const _CustomBottomNavBar({
    required this.currentIndex,
    required this.onTabSelected,
    required this.chatUnreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 导航栏内容
          SizedBox(
            height: 62, // 导航栏高度
            child: Row(
              children: [
                Expanded(
                  child: _IconOnlyNavItem(
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home,
                    label: 'Home',
                    selected: currentIndex == 0,
                    onTap: () => onTabSelected(0),
                    selectedColor: const Color(0xFF32C286),
                  ),
                ),
                Expanded(
                  child: _IconOnlyNavItem(
                    icon: Icons.place_outlined,
                    selectedIcon: Icons.place,
                    label: 'Nearby',
                    selected: currentIndex == 1,
                    onTap: () => onTabSelected(1),
                    selectedColor: const Color(0xFF32C286),
                  ),
                ),
                const SizedBox(width: 72), // FAB notch spacer
                Expanded(
                  child: _IconOnlyNavItem(
                    icon: Icons.chat_bubble_outline,
                    selectedIcon: Icons.chat_bubble,
                    label: 'Chat',
                    selected: currentIndex == 2,
                    onTap: () => onTabSelected(2),
                    selectedColor: const Color(0xFF32C286),
                    badgeCount: chatUnreadCount,
                    badgeColor: const Color(0xFFFF4E4E),
                  ),
                ),
                Expanded(
                  child: _IconOnlyNavItem(
                    icon: Icons.person_outlined,
                    selectedIcon: Icons.person,
                    label: 'Me',
                    selected: currentIndex == 3,
                    onTap: () => onTabSelected(3),
                    selectedColor: const Color(0xFF32C286),
                  ),
                ),
              ],
            ),
          ),
          // 底部安全区域占位 - 让导航栏延伸到屏幕最底部
          SizedBox(
            height: MediaQuery.of(context).padding.bottom,
          ),
        ],
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

  void _showFavorites(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FavoritesPage(),
      ),
    );
  }

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
            // Search + favorites button + small square avatar
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
                // Favorites button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => _showFavorites(context),
                    icon: const Icon(Icons.favorite_border, color: Colors.red),
                    tooltip: 'My Favorites',
                    iconSize: 20,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
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