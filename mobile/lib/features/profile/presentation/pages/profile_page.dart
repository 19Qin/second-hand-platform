import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'edit_profile_page.dart';
import 'user_products_page.dart';
import 'settings_page.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/usecases/get_user_profile_usecase.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';
import '../../domain/usecases/get_user_products_usecase.dart';
import '../../../../core/auth/auth_state_manager.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../../core/auth/token_manager.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../product/presentation/pages/favorites_page.dart';
import '../../../product/domain/usecases/get_user_favorites.dart';
import '../../../chat/domain/usecases/get_chat_list.dart';
import '../../../file/data/datasources/file_remote_data_source.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.onRefresh});
  
  final VoidCallback? onRefresh;

  @override
  ProfilePageState createState() => ProfilePageState();
}

// Add a flag to track if authentication has been checked
bool _hasCheckedAuth = false;

class ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _error;
  bool _isUploadingAvatar = false;
  final GetUserProductsUseCase _getUserProductsUseCase = ServiceLocator().get<GetUserProductsUseCase>();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadUserProductsSummary();
    
    // 如果提供了刷新回调，则调用它
    if (widget.onRefresh != null) {
      widget.onRefresh!();
    }
  }
  
  // 公共刷新方法
  void refreshProfile() {
    _loadUserProfile();
    _loadUserProductsSummary();
  }

  Future<void> _loadUserProfile() async {
    try {
      // Try to get user info from TokenManager (saved during login)
      // If backend /user/profile interface is not implemented yet, use basic info from login
      
      final apiClient = ApiClient();
      
      // First try to call the real user profile interface
      try {
        final response = await apiClient.get('/user/profile');
        if (response != null && response['code'] == 200) {
          // If interface exists, use real data
          final userProfile = response['data'];
          setState(() {
            _userData = {
              'username': userProfile['username'] ?? 'User',
              'email': userProfile['email'],
              'avatar': userProfile['avatar'] ?? 'https://cdn.fliliy.com/avatar/default.png',
              'gender': userProfile['gender'] ?? 0,
              'birthday': userProfile['birthday'],
              'location': userProfile['location'],
              'bio': userProfile['bio'],
              'verified': userProfile['verified'] ?? false,
              'stats': userProfile['stats'] ?? {
                'publishedCount': 0,
                'activeCount': 0,
                'soldCount': 0,
                'boughtCount': 0,
                'favoriteCount': 0,
                'chatCount': 0,
              },
            };
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        // If interface doesn't exist or error, use basic info from login
        print('User profile interface not implemented yet, using login info: $e');
      }
      
      // Use basic info from login as default data
      // Try to get user info from TokenManager (saved during login)
      Map<String, dynamic> userInfo = {};
      try {
        final tokenManager = TokenManager.instance;
        final savedUserInfo = await tokenManager.getUserInfo();
        if (savedUserInfo != null) {
          userInfo = savedUserInfo;
        }
      } catch (e) {
        print('Failed to get user info from TokenManager: $e');
      }
      
      final userProfile = {
        'username': userInfo['username'] ?? 'User',
        'email': userInfo['email'] ?? null,
        'avatar': userInfo['avatar'] ?? 'https://cdn.fliliy.com/avatar/default.png',
        'gender': 0, // Unknown - not saved during login
        'birthday': null, // Not saved during login
        'location': null, // Not saved during login
        'bio': null, // Not saved during login
        'verified': false, // Not saved during login
        'stats': {
          'publishedCount': 0,
          'activeCount': 0,
          'soldCount': 0,
          'boughtCount': 0,
          'favoriteCount': 0,
          'chatCount': 0,
        },
      };
      
      setState(() {
        _userData = userProfile;
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserProductsSummary() async {
    try {
      // Get all products to get accurate counts
      final allResponse = await _getUserProductsUseCase(
        status: null, // Get all products
        page: 1,
        size: 50, // Get enough to count accurately
        sort: 'time_desc',
      );

      // Get favorites count
      int favoriteCount = 0;
      try {
        final favoritesResponse = await ServiceLocator().get<GetUserFavorites>().call(
          status: '', // Empty string to avoid status parameter in API call
          page: 1,
          size: 1, // Just need the count
          sort: 'time_desc',
        );
        favoriteCount = favoritesResponse.pagination.total;
      } catch (e) {
        print('Failed to get favorites count: $e');
      }

      // Get chats count
      int chatCount = 0;
      try {
        final chatsResponse = await ServiceLocator().get<GetChatList>().call(
          page: 1,
          size: 1, // Just need the count
        );
        chatCount = chatsResponse.pagination.total;
      } catch (e) {
        print('Failed to get chats count: $e');
      }

      if (mounted) {
        setState(() {
          if (_userData != null) {
            // Count products by status from the actual data
            final allProducts = allResponse.products;
            final activeCount = allProducts.where((p) => p.status == 'ACTIVE').length;
            final soldCount = allProducts.where((p) => p.status == 'SOLD').length;
            final inactiveCount = allProducts.where((p) => p.status == 'INACTIVE').length;
            
            _userData!['stats'] = {
              'publishedCount': allProducts.length, // Total published products
              'activeCount': activeCount,
              'soldCount': soldCount,
              'boughtCount': _userData!['stats']?['boughtCount'] ?? 0,
              'favoriteCount': favoriteCount,
              'chatCount': chatCount,
            };
          }
        });
      }
    } catch (e) {
      print('Failed to load user product summary: $e');
      // Doesn't affect main functionality, just statistics may be inaccurate
    }
  }

  @override
  Widget build(BuildContext context) {
    
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF32C286)),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load user profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadUserProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF32C286),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top green gradient background area
            _buildTopSection(),
            
            // White background content area
            _buildContentSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.5, -1.0),
          end: Alignment(1.0, 1.0),
          colors: [
            Color.fromRGBO(50, 194, 134, 0.33),
            Color.fromRGBO(50, 194, 134, 0.04),
          ],
          stops: [0.0, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Circular avatar with edit button
              Stack(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipOval(
                      child: _userData?['avatar'] != null && _userData!['avatar'].isNotEmpty
                          ? Image.network(
                              _userData!['avatar'],
                              width: 68,
                              height: 68,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 68,
                                  height: 68,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            )
                          : Image.asset(
                              'assets/images/profile_picture.png',
                              width: 68,
                              height: 68,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 68,
                                  height: 68,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  // Avatar edit button (右下角加号)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploadingAvatar ? null : _changeAvatar,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _isUploadingAvatar 
                              ? Colors.grey 
                              : const Color(0xFF32C286),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _isUploadingAvatar
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(
                                Icons.add,
                                size: 16,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Username and edit button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _userData?['username'] ?? 'User',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _navigateToEditProfile(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Color(0xFF32C286),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Statistics card - moved inside green box
              _buildStatsCardInGreen(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Buy/Sell status bar - right below green box
          _buildBuySellSection(),
          
          const SizedBox(height: 30),
          
          // Menu items list
          _buildMenuItems(),
          
          // Leave enough space for bottom navigation bar
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStatsCardInGreen() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(Icons.favorite_outline, '0', 'Wishlist'),
          _buildStatItem(Icons.rate_review_outlined, '0', 'Review'),
          _buildStatItem(Icons.stars_outlined, '0', 'Points'),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(Icons.favorite_outline, '0', 'Wishlist'),
            _buildStatItem(Icons.rate_review_outlined, '0', 'Review'),
            _buildStatItem(Icons.stars_outlined, '0', 'Points'),
          ],
        ),
      ),
    );
  }

  Widget _buildBuySellSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Color(0xFF32C286), size: 20),
                SizedBox(width: 8),
                Text(
                  'Trading Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF32C286),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            
            // First row: Product statistics
            Row(
              children: [
                Expanded(
                  child: _buildTradingItem(
                    Icons.shopping_bag_outlined, 
                    '${_userData?['stats']?['publishedCount'] ?? 0}', 
                    'Published',
                    'Total products listed',
                    Color(0xFF4CAF50),
                    onTap: () => _navigateToUserProductsWithStatus('all'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildTradingItem(
                    Icons.store_outlined, 
                    '${_userData?['stats']?['activeCount'] ?? 0}', 
                    'Active',
                    'Currently selling',
                    Color(0xFF2196F3),
                    onTap: () => _navigateToUserProductsWithStatus('active'),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Second row: Transaction statistics
            Row(
              children: [
                Expanded(
                  child: _buildTradingItem(
                    Icons.check_circle_outline, 
                    '${_userData?['stats']?['soldCount'] ?? 0}', 
                    'Sold',
                    'Successfully sold',
                    Color(0xFF32C286),
                    onTap: () => _navigateToUserProductsWithStatus('sold'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildTradingItem(
                    Icons.shopping_cart_outlined, 
                    '${_userData?['stats']?['boughtCount'] ?? 0}', 
                    'Bought',
                    'Items purchased',
                    Color(0xFFFF9800),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Third row: Interaction statistics
            Row(
              children: [
                Expanded(
                  child: _buildTradingItem(
                    Icons.favorite_outline, 
                    '${_userData?['stats']?['favoriteCount'] ?? 0}', 
                    'Favorites',
                    'Items favorited',
                    Color(0xFFE91E63),
                    onTap: _navigateToFavorites,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildTradingItem(
                    Icons.chat_bubble_outline, 
                    '${_userData?['stats']?['chatCount'] ?? 0}', 
                    'Chats',
                    'Active conversations',
                    Color(0xFF9C27B0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItems() {
    return Column(
      children: [
        _buildMenuItem(Icons.inventory_2_outlined, 'My Products', '', onTap: _navigateToUserProducts),
        _buildMenuItem(Icons.account_balance_wallet_outlined, 'My wallet', 'Exchange'),
        _buildMenuItem(Icons.history_outlined, 'History', ''),
        _buildMenuItem(Icons.headset_mic_outlined, 'Customer service', ''),
        _buildMenuItem(Icons.school_outlined, 'Uni student', 'Verify'),
        _buildMenuItem(Icons.payment_outlined, 'Payment methods', ''),
        _buildMenuItem(Icons.settings_outlined, AppLocalizations.of(context).settings, '', onTap: _navigateToSettings),
        const SizedBox(height: 20),
        _buildLogoutButton(),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String count, String label) {
    return Column(
      children: [
        Stack(
          children: [
            Icon(
              icon,
              size: 28,
              color: Colors.grey[600],
            ),
            if (count != '0' && label != 'Points')
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    count,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusItem(IconData icon, String count, String label) {
    return Column(
      children: [
        Stack(
          children: [
            Icon(
              icon,
              size: 24,
              color: Colors.grey[600],
            ),
            if (count != '0')
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: Text(
                    count,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String trailing, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          size: 24,
          color: Colors.grey[700],
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing.isNotEmpty)
              Text(
                trailing,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
        onTap: onTap ?? () {
          // Default click handling
        },
      ),
    );
  }

  Widget _buildTradingItem(IconData icon, String count, String label, String description, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                SizedBox(width: 8),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 2),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEditProfile(BuildContext context) async {
    _showMaintenanceDialog();
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }

  void _navigateToUserProducts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UserProductsPage(),
      ),
    );
  }

  void _navigateToUserProductsWithStatus(String status) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProductsPage(initialStatus: status),
      ),
    );
  }

  void _navigateToFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FavoritesPage(),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: _showLogoutDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[50],
          foregroundColor: Colors.red[700],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.red[300]!),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Log out',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Confirm Logout',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get refreshToken
      final refreshToken = await TokenManager.instance.getRefreshToken();
      
      // Call logout interface
      final authDataSource = ServiceLocator().get<AuthRemoteDataSource>();
      await authDataSource.logout(refreshToken: refreshToken);
      
      // Clear local tokens
      await TokenManager.instance.clearTokens();
      
      // Close loading indicator
      if (mounted) {
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully logged out'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to login page
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      // Even if API call fails, clear local data and navigate
      print('Logout API call failed: $e');
      
      // Clear local tokens
      await TokenManager.instance.clearTokens();
      
      // Close loading indicator
      if (mounted) {
        Navigator.of(context).pop();
        
        // Show warning message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out (local data cleared)'),
            backgroundColor: Colors.orange,
          ),
        );
        
        // Navigate to login page
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
          (route) => false,
        );
      }
    }
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
                  Icons.person_outline,
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
                'Profile editing feature is under development, stay tuned!',
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

  // 头像更换功能
  Future<void> _changeAvatar() async {
    _showMaintenanceDialog();
  }

  Widget _buildAvatarOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF32C286).withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              icon,
              size: 30,
              color: const Color(0xFF32C286),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _isUploadingAvatar = true;
        });

        // 上传头像到服务器
        await _uploadAvatar(image);
      }
    } catch (e) {
      _showErrorDialog('选择图片失败: $e');
    }
  }

  Future<void> _uploadAvatar(XFile imageFile) async {
    try {
      final apiClient = ApiClient();
      
      // 直接使用头像上传API
      final bytes = await imageFile.readAsBytes();
      final uri = Uri.parse('${apiClient.baseUrl}/user/avatar/upload');
      
      final request = http.MultipartRequest('POST', uri);
      
      // 获取文件扩展名并设置正确的Content-Type
      final filename = imageFile.name;
      final extension = filename.split('.').last.toLowerCase();
      String contentType;
      
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        default:
          contentType = 'image/jpeg'; // 默认
      }
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: MediaType.parse(contentType),
        ),
      );
      
      final token = await TokenManager.instance.getAccessToken();
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['code'] == 200) {
          final avatarUrl = jsonData['data']['url'];
          
          // 更新用户资料中的头像URL
          final updateData = {
            'avatar': avatarUrl,
          };

          final profileDataSource = ProfileRemoteDataSourceImpl(apiClient);
          await profileDataSource.updateUserProfile(updateData);

          // 更新本地状态
          setState(() {
            _userData?['avatar'] = avatarUrl;
            _isUploadingAvatar = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('头像更新成功')),
          );
        } else {
          throw Exception(jsonData['message'] ?? '头像上传失败');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isUploadingAvatar = false;
      });
      _showErrorDialog('头像上传失败: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showMaintenanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.build, color: Color(0xFF32C286)),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).maintenance),
          ],
        ),
        content: Text(AppLocalizations.of(context).maintenanceMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).ok),
          ),
        ],
      ),
    );
  }
}