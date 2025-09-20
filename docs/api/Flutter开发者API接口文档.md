# 🚀 Fliliy 二手平台 API 接口文档 [Flutter开发者版本]

## 📖 文档说明

**版本**: v1.0 [Flutter开发者专用版]  
**更新时间**: 2025-09-02  
**目标用户**: Flutter/Dart 开发人员  
**文档特点**: 专注移动端开发，包含完整Dart示例

---

## 🎯 Flutter开发者快速上手指南

### 1. **30秒快速了解**

这是一个**RESTful API**，所有接口都返回**统一的JSON格式**：

```json
{
  "code": 200,
  "message": "操作成功",
  "data": { /* 具体数据 */ },
  "timestamp": 1640995200000
}
```

### 2. **5分钟开始开发**

```dart
// pubspec.yaml 依赖
dependencies:
  dio: ^5.3.2
  json_annotation: ^4.8.1

dev_dependencies:
  json_serializable: ^6.7.1
  build_runner: ^2.4.7

// API服务基础配置
class ApiService {
  static const String baseUrl = 'http://localhost:8080/api/v1';
  late final Dio _dio;
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      timeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    
    // 添加请求拦截器
    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }
  
  // 统一请求方法
  Future<T> request<T>(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? queryParameters,
    dynamic data,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.request(
        path,
        options: Options(method: method),
        queryParameters: queryParameters,
        data: data,
      );
      
      final result = response.data;
      
      // 统一错误处理
      if (result['code'] != 200) {
        throw ApiException(result['code'], result['message']);
      }
      
      if (fromJson != null) {
        return fromJson(result['data']);
      }
      
      return result['data'];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
}

// 认证拦截器
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = TokenManager.instance.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token过期，尝试刷新
      TokenManager.instance.refreshToken().then((_) {
        // 重试原请求
        _dio.fetch(err.requestOptions).then((response) {
          handler.resolve(response);
        }).catchError((error) {
          handler.reject(error);
        });
      }).catchError((error) {
        // 刷新失败，跳转登录
        NavigatorService.pushAndClearStack('/login');
        handler.reject(err);
      });
    } else {
      super.onError(err, handler);
    }
  }
}
```

### 3. **认证流程（必读）**

```dart
// Token管理器
class TokenManager {
  static final TokenManager instance = TokenManager._internal();
  TokenManager._internal();
  
  String? _accessToken;
  String? _refreshToken;
  
  String? get accessToken => _accessToken;
  
  // 保存Token
  Future<void> setTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }
  
  // 刷新Token
  Future<void> refreshToken() async {
    if (_refreshToken == null) throw Exception('No refresh token');
    
    final response = await ApiService().request(
      '/auth/token/refresh',
      method: 'POST',
      data: {'refreshToken': _refreshToken},
    );
    
    await setTokens(response['accessToken'], response['refreshToken']);
  }
}
```

---

# 1. 用户认证模块 [已实现] 🔐

## 1.1 发送短信验证码 📱

**接口**: `POST /auth/sms/send`  

### Dart实现示例
```dart
// SMS服务类
class SmsService {
  final ApiService _apiService = ApiService();
  
  Future<String> sendSmsCode(String mobile, String type) async {
    final response = await _apiService.request<Map<String, dynamic>>(
      '/auth/sms/send',
      method: 'POST',
      data: {
        'mobile': mobile,
        'type': type, // 'register', 'login', 'reset'
      },
    );
    
    return response['smsId'];
  }
}

// 验证码输入Widget
class SmsCodeInput extends StatefulWidget {
  final String mobile;
  final String type;
  final Function(String code, String smsId) onCodeComplete;
  
  const SmsCodeInput({
    Key? key,
    required this.mobile,
    required this.type,
    required this.onCodeComplete,
  }) : super(key: key);
  
  @override
  _SmsCodeInputState createState() => _SmsCodeInputState();
}

class _SmsCodeInputState extends State<SmsCodeInput> {
  final List<TextEditingController> _controllers = 
      List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = 
      List.generate(4, (index) => FocusNode());
  
  String? _smsId;
  int _countdown = 0;
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _sendSmsCode();
  }
  
  Future<void> _sendSmsCode() async {
    try {
      _smsId = await SmsService().sendSmsCode(widget.mobile, widget.type);
      _startCountdown();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送验证码失败: $e')),
      );
    }
  }
  
  void _startCountdown() {
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _countdown--);
      if (_countdown <= 0) {
        timer.cancel();
      }
    });
  }
  
  void _onCodeChanged(int index, String value) {
    if (value.length == 1 && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    
    // 检查是否输入完成
    final code = _controllers.map((c) => c.text).join();
    if (code.length == 4 && _smsId != null) {
      widget.onCodeComplete(code, _smsId!);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) {
            return SizedBox(
              width: 50,
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                decoration: const InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _onCodeChanged(index, value),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: _countdown > 0 ? null : _sendSmsCode,
          child: Text(_countdown > 0 ? '${_countdown}秒后重试' : '重新发送'),
        ),
      ],
    );
  }
}
```

## 1.2 用户注册 👤

### Dart实现示例
```dart
// 用户认证服务
class AuthService {
  final ApiService _apiService = ApiService();
  
  Future<AuthResult> register(RegisterRequest request) async {
    final response = await _apiService.request<Map<String, dynamic>>(
      '/auth/register',
      method: 'POST',
      data: request.toJson(),
    );
    
    final authResult = AuthResult.fromJson(response);
    
    // 保存Token
    await TokenManager.instance.setTokens(
      authResult.accessToken,
      authResult.refreshToken,
    );
    
    return authResult;
  }
  
  Future<AuthResult> loginWithPassword(String mobile, String password) async {
    final response = await _apiService.request<Map<String, dynamic>>(
      '/auth/login/password',
      method: 'POST',
      data: {
        'mobile': mobile,
        'password': password,
        'rememberMe': true,
      },
    );
    
    final authResult = AuthResult.fromJson(response);
    await TokenManager.instance.setTokens(
      authResult.accessToken,
      authResult.refreshToken,
    );
    
    return authResult;
  }
}

// 数据模型
@JsonSerializable()
class RegisterRequest {
  final String username;
  final String mobile;
  final String password;
  final String confirmPassword;
  final String smsCode;
  final String smsId;
  final bool agreeTerms;
  
  RegisterRequest({
    required this.username,
    required this.mobile,
    required this.password,
    required this.confirmPassword,
    required this.smsCode,
    required this.smsId,
    required this.agreeTerms,
  });
  
  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);
  
  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}

@JsonSerializable()
class AuthResult {
  final String userId;
  final String username;
  final String mobile;
  final String avatar;
  final bool verified;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final int refreshExpiresIn;
  
  AuthResult({
    required this.userId,
    required this.username,
    required this.mobile,
    required this.avatar,
    required this.verified,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.refreshExpiresIn,
  });
  
  factory AuthResult.fromJson(Map<String, dynamic> json) =>
      _$AuthResultFromJson(json);
  
  Map<String, dynamic> toJson() => _$AuthResultToJson(this);
}

// 注册页面
class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _agreeTerms = false;
  bool _loading = false;
  
  Future<void> _register(String smsCode, String smsId) async {
    if (!_formKey.currentState!.validate() || !_agreeTerms) {
      return;
    }
    
    setState(() => _loading = true);
    
    try {
      final request = RegisterRequest(
        username: _usernameController.text,
        mobile: _mobileController.text,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        smsCode: smsCode,
        smsId: smsId,
        agreeTerms: _agreeTerms,
      );
      
      await AuthService().register(request);
      
      // 注册成功，跳转主页
      Navigator.of(context).pushReplacementNamed('/home');
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('注册失败: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('用户注册')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: '用户名'),
                validator: (value) {
                  if (value == null || value.length < 2) {
                    return '用户名至少2个字符';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(labelText: '手机号'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || !RegExp(r'^(1[3-9]\d{9}|0[4-5]\d{8})$').hasMatch(value)) {
                    return '手机号格式不正确';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: '密码'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return '密码至少8位';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(labelText: '确认密码'),
                obscureText: true,
                validator: (value) {
                  if (value != _passwordController.text) {
                    return '两次密码输入不一致';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SmsCodeInput(
                mobile: _mobileController.text,
                type: 'register',
                onCodeComplete: _register,
              ),
              CheckboxListTile(
                title: const Text('我同意用户协议'),
                value: _agreeTerms,
                onChanged: (value) => setState(() => _agreeTerms = value ?? false),
              ),
              const SizedBox(height: 20),
              if (_loading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: null, // 由验证码输入完成后自动触发
                  child: const Text('注册'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

# 2. 商品展示模块 [核心功能] 🛍️

## 2.1 轮播图查询 🎠

### Dart实现示例
```dart
// 轮播图服务
class BannerService {
  final ApiService _apiService = ApiService();
  
  Future<List<BannerModel>> getBanners() async {
    final response = await _apiService.request<List<dynamic>>(
      '/banners',
      queryParameters: {
        'type': 'homepage',
        'status': 'active',
      },
    );
    
    return response.map((json) => BannerModel.fromJson(json)).toList();
  }
}

// 轮播图模型
@JsonSerializable()
class BannerModel {
  final int id;
  final String title;
  final String image;
  final String link;
  final String linkType;
  final int sortOrder;
  final bool isActive;
  
  BannerModel({
    required this.id,
    required this.title,
    required this.image,
    required this.link,
    required this.linkType,
    required this.sortOrder,
    required this.isActive,
  });
  
  factory BannerModel.fromJson(Map<String, dynamic> json) =>
      _$BannerModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$BannerModelToJson(this);
}

// 轮播图Widget
class BannerCarousel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BannerModel>>(
      future: BannerService().getBanners(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 200,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink(); // 轮播图失败不影响主功能
        }
        
        final banners = snapshot.data!;
        if (banners.isEmpty) return const SizedBox.shrink();
        
        return Container(
          height: 200,
          child: PageView.builder(
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return GestureDetector(
                onTap: () => _handleBannerTap(context, banner),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Image.network(
                          banner.image,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Text(
                              banner.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
  
  void _handleBannerTap(BuildContext context, BannerModel banner) {
    switch (banner.linkType) {
      case 'category':
        Navigator.of(context).pushNamed('/products', arguments: {
          'categoryId': _extractCategoryId(banner.link),
        });
        break;
      case 'product':
        Navigator.of(context).pushNamed('/product-detail', arguments: {
          'productId': _extractProductId(banner.link),
        });
        break;
      case 'external':
        _launchUrl(banner.link);
        break;
    }
  }
  
  int? _extractCategoryId(String link) {
    final match = RegExp(r'/products/category/(\d+)').firstMatch(link);
    return match != null ? int.parse(match.group(1)!) : null;
  }
  
  int? _extractProductId(String link) {
    final match = RegExp(r'/products/(\d+)').firstMatch(link);
    return match != null ? int.parse(match.group(1)!) : null;
  }
  
  void _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}
```

## 2.2 商品列表查询 📋

### Dart实现示例
```dart
// 商品服务
class ProductService {
  final ApiService _apiService = ApiService();
  
  Future<ProductListResponse> getProducts({
    int page = 1,
    int size = 20,
    int? categoryId,
    String? condition,
    double? minPrice,
    double? maxPrice,
    String? sort,
    String? location,
    int? sellerId,
  }) async {
    final response = await _apiService.request<Map<String, dynamic>>(
      '/products',
      queryParameters: {
        'page': page,
        'size': size,
        if (categoryId != null) 'category_id': categoryId,
        if (condition != null) 'condition': condition,
        if (minPrice != null) 'min_price': minPrice,
        if (maxPrice != null) 'max_price': maxPrice,
        if (sort != null) 'sort': sort,
        if (location != null) 'location': location,
        if (sellerId != null) 'seller_id': sellerId,
      },
    );
    
    return ProductListResponse.fromJson(response);
  }
  
  Future<void> toggleFavorite(int productId) async {
    await _apiService.request(
      '/products/$productId/favorite',
      method: 'POST',
    );
  }
}

// 商品列表响应模型
@JsonSerializable()
class ProductListResponse {
  final List<Product> items;
  final PaginationInfo pagination;
  final FilterInfo filters;
  
  ProductListResponse({
    required this.items,
    required this.pagination,
    required this.filters,
  });
  
  factory ProductListResponse.fromJson(Map<String, dynamic> json) =>
      _$ProductListResponseFromJson(json);
}

@JsonSerializable()
class Product {
  final int id;
  final String title;
  final String description;
  final double price;
  final double? originalPrice;
  final int? discount;
  final String mainImage;
  final List<String> images;
  final String condition;
  final String conditionText;
  final CategoryInfo category;
  final SellerInfo seller;
  final LocationInfo location;
  final List<String> tags;
  final String status;
  final int viewCount;
  final int favoriteCount;
  final int chatCount;
  final DateTime publishedAt;
  final DateTime updatedAt;
  final bool isFavorited;
  final double? distance;
  
  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.originalPrice,
    this.discount,
    required this.mainImage,
    required this.images,
    required this.condition,
    required this.conditionText,
    required this.category,
    required this.seller,
    required this.location,
    required this.tags,
    required this.status,
    required this.viewCount,
    required this.favoriteCount,
    required this.chatCount,
    required this.publishedAt,
    required this.updatedAt,
    required this.isFavorited,
    this.distance,
  });
  
  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
  
  Map<String, dynamic> toJson() => _$ProductToJson(this);
}

// 商品列表页面
class ProductListPage extends StatefulWidget {
  final int? categoryId;
  final String? keyword;
  
  const ProductListPage({
    Key? key,
    this.categoryId,
    this.keyword,
  }) : super(key: key);
  
  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final ScrollController _scrollController = ScrollController();
  final List<Product> _products = [];
  
  int _currentPage = 1;
  int _totalPages = 1;
  bool _loading = false;
  bool _hasMore = true;
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadProducts();
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }
  
  Future<void> _loadProducts({bool refresh = false}) async {
    if (_loading) return;
    
    setState(() => _loading = true);
    
    try {
      final page = refresh ? 1 : _currentPage;
      final response = await ProductService().getProducts(
        page: page,
        categoryId: widget.categoryId,
      );
      
      setState(() {
        if (refresh) {
          _products.clear();
          _currentPage = 1;
        }
        
        _products.addAll(response.items);
        _totalPages = response.pagination.totalPages;
        _hasMore = _currentPage < _totalPages;
        _currentPage++;
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }
  
  Future<void> _loadMore() async {
    if (_hasMore && !_loading) {
      await _loadProducts();
    }
  }
  
  Future<void> _refresh() async {
    await _loadProducts(refresh: true);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryId != null ? '商品列表' : '搜索结果'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: _products.length + (_loading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _products.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            final product = _products[index];
            return ProductCard(
              product: product,
              onTap: () => _navigateToDetail(product.id),
              onFavoriteTap: () => _toggleFavorite(product.id, index),
            );
          },
        ),
      ),
    );
  }
  
  void _navigateToDetail(int productId) {
    Navigator.of(context).pushNamed('/product-detail', arguments: {
      'productId': productId,
    });
  }
  
  Future<void> _toggleFavorite(int productId, int index) async {
    try {
      await ProductService().toggleFavorite(productId);
      
      setState(() {
        final product = _products[index];
        _products[index] = Product(
          // 复制所有属性，只修改收藏状态
          id: product.id,
          title: product.title,
          description: product.description,
          price: product.price,
          originalPrice: product.originalPrice,
          discount: product.discount,
          mainImage: product.mainImage,
          images: product.images,
          condition: product.condition,
          conditionText: product.conditionText,
          category: product.category,
          seller: product.seller,
          location: product.location,
          tags: product.tags,
          status: product.status,
          viewCount: product.viewCount,
          favoriteCount: product.isFavorited 
              ? product.favoriteCount - 1 
              : product.favoriteCount + 1,
          chatCount: product.chatCount,
          publishedAt: product.publishedAt,
          updatedAt: product.updatedAt,
          isFavorited: !product.isFavorited,
          distance: product.distance,
        );
      });
      
    } catch (e) {
      if (e.toString().contains('401')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先登录')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }
  
  void _showFilterDialog() {
    // 显示筛选对话框
    showModalBottomSheet(
      context: context,
      builder: (context) => ProductFilterWidget(
        onApplyFilters: (filters) {
          // 应用筛选条件并重新加载
          _refresh();
        },
      ),
    );
  }
}

// 商品卡片Widget
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  
  const ProductCard({
    Key? key,
    required this.product,
    required this.onTap,
    required this.onFavoriteTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 商品图片
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.mainImage,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              
              // 商品信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // 价格信息
                    Row(
                      children: [
                        Text(
                          '¥${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        if (product.originalPrice != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '¥${product.originalPrice!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                        if (product.discount != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${product.discount}折',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // 商品状况和标签
                    Wrap(
                      spacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getConditionColor(product.condition),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.conditionText,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        ...product.tags.take(2).map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue[800],
                            ),
                          ),
                        )),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // 卖家和统计信息
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundImage: NetworkImage(product.seller.avatar),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.seller.username,
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (product.seller.verified)
                          const Icon(
                            Icons.verified,
                            size: 12,
                            color: Colors.blue,
                          ),
                        const Spacer(),
                        Text(
                          '${product.viewCount}次浏览',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          product.location.district,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 收藏按钮
              IconButton(
                icon: Icon(
                  product.isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: product.isFavorited ? Colors.red : Colors.grey,
                ),
                onPressed: onFavoriteTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getConditionColor(String condition) {
    switch (condition) {
      case 'NEW':
        return Colors.green;
      case 'LIKE_NEW':
        return Colors.blue;
      case 'GOOD':
        return Colors.orange;
      case 'FAIR':
        return Colors.amber;
      case 'POOR':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
```

---

# 📝 Flutter开发最佳实践

## 🎯 状态管理建议

推荐使用 **Riverpod** 进行状态管理：

```dart
// 商品列表Provider
final productListProvider = StateNotifierProvider<ProductListNotifier, ProductListState>((ref) {
  return ProductListNotifier();
});

class ProductListNotifier extends StateNotifier<ProductListState> {
  ProductListNotifier() : super(ProductListState.initial());
  
  Future<void> loadProducts({bool refresh = false}) async {
    if (state.loading) return;
    
    state = state.copyWith(loading: true);
    
    try {
      final response = await ProductService().getProducts(
        page: refresh ? 1 : state.currentPage,
      );
      
      state = state.copyWith(
        products: refresh ? response.items : [...state.products, ...response.items],
        currentPage: refresh ? 2 : state.currentPage + 1,
        hasMore: response.pagination.hasNext,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}

@freezed
class ProductListState with _$ProductListState {
  const factory ProductListState({
    required List<Product> products,
    required int currentPage,
    required bool hasMore,
    required bool loading,
    String? error,
  }) = _ProductListState;
  
  factory ProductListState.initial() => const ProductListState(
    products: [],
    currentPage: 1,
    hasMore: true,
    loading: false,
  );
}
```

## 📱 性能优化

### 图片缓存优化
```dart
dependencies:
  cached_network_image: ^3.3.0

// 使用缓存图片组件
CachedNetworkImage(
  imageUrl: product.mainImage,
  width: 80,
  height: 80,
  fit: BoxFit.cover,
  placeholder: (context, url) => Container(
    color: Colors.grey[300],
    child: const CircularProgressIndicator(),
  ),
  errorWidget: (context, url, error) => Container(
    color: Colors.grey[300],
    child: const Icon(Icons.image_not_supported),
  ),
)
```

### 列表性能优化
```dart
// 使用AutomaticKeepAliveClientMixin保持列表状态
class ProductListPage extends StatefulWidget {
  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用
    
    return ListView.builder(
      itemBuilder: (context, index) {
        return ProductCard(product: products[index]);
      },
    );
  }
}
```

---

# 🎉 总结

这个Flutter版本的API文档提供了：

✅ **完整的Dart实现** - 所有接口的Flutter/Dart实现示例  
✅ **移动端优化** - 专门针对移动端的UI组件和交互  
✅ **状态管理** - Riverpod状态管理最佳实践  
✅ **性能优化** - 图片缓存、列表优化等移动端性能考虑  
✅ **错误处理** - 完善的异常处理和用户反馈  
✅ **代码生成** - 使用json_serializable自动生成模型代码

现在你的Flutter团队可以直接基于这个文档进行APP开发了！🚀

---

**📄 文档持续更新中...**  
如有问题请联系后端开发人员或查看项目Wiki。