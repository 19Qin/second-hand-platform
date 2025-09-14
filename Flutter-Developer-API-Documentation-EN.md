# 🚀 Fliliy Second-Hand Platform API Documentation [Flutter Developer Version]

## 📖 Documentation Overview

**Version**: v2.2 [Flutter Developer Specialized Version]  
**Last Updated**: 2025-09-09  
**Target Users**: Flutter/Dart Developers  
**Document Features**: Focus on mobile development, includes complete Dart examples

---

## 🎯 Flutter Developer Quick Start Guide

### 1. **Quick Overview in 30 Seconds**

This is a **RESTful API** where all endpoints return **unified JSON format**:

```json
{
  "code": 200,
  "message": "Operation successful",
  "data": { /* Specific data */ },
  "timestamp": 1640995200000
}
```

### 2. **Start Development in 5 Minutes**

```dart
// pubspec.yaml dependencies
dependencies:
  dio: ^5.3.2
  json_annotation: ^4.8.1
  shared_preferences: ^2.2.2
  get: ^4.6.6

dev_dependencies:
  json_serializable: ^6.7.1
  build_runner: ^2.4.7

// API service basic configuration
class ApiService {
  static const String baseUrl = 'http://localhost:8080/api/v1';
  late final Dio _dio;
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    
    // Add interceptors
    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }
  
  // Generic request method
  Future<T> request<T>(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic) fromJson,
  }) async {
    try {
      final response = await _dio.request(
        path,
        options: Options(method: method),
        data: data,
        queryParameters: queryParameters,
      );
      
      final apiResponse = ApiResponse.fromJson(response.data);
      
      if (apiResponse.code == 200) {
        return fromJson(apiResponse.data);
      } else {
        throw ApiException(apiResponse.message, apiResponse.code);
      }
    } on DioException catch (e) {
      throw ApiException(_handleDioError(e), e.response?.statusCode ?? -1);
    }
  }
  
  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout';
      case DioExceptionType.sendTimeout:
        return 'Send timeout';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout';
      case DioExceptionType.badResponse:
        return 'Server error: ${error.response?.statusCode}';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      default:
        return 'Network error';
    }
  }
}

// API response model
@JsonSerializable()
class ApiResponse {
  final int code;
  final String message;
  final dynamic data;
  final int timestamp;
  
  ApiResponse({
    required this.code,
    required this.message,
    this.data,
    required this.timestamp,
  });
  
  factory ApiResponse.fromJson(Map<String, dynamic> json) =>
      _$ApiResponseFromJson(json);
  
  Map<String, dynamic> toJson() => _$ApiResponseToJson(this);
}

// Custom exception
class ApiException implements Exception {
  final String message;
  final int code;
  
  ApiException(this.message, this.code);
  
  @override
  String toString() => 'ApiException: $message (Code: $code)';
}
```

### 3. **Authentication Setup**

```dart
// Auth interceptor
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await TokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Retry the original request
        final response = await Dio().fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } else {
        // Redirect to login
        Get.offAllNamed('/login');
      }
    }
    handler.next(err);
  }
  
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken == null) return false;
      
      final dio = Dio();
      final response = await dio.post(
        '${ApiService.baseUrl}/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      
      final apiResponse = ApiResponse.fromJson(response.data);
      if (apiResponse.code == 200) {
        await TokenStorage.saveTokens(
          apiResponse.data['accessToken'],
          apiResponse.data['refreshToken'],
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

// Token storage
class TokenStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }
  
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }
  
  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }
  
  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
  }
}
```

---

## 🔐 Authentication Module

### Login with Password

```dart
// Login request model
@JsonSerializable()
class LoginRequest {
  final String mobile;
  final String password;
  
  LoginRequest({required this.mobile, required this.password});
  
  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

// Auth response model
@JsonSerializable()
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserModel user;
  
  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });
  
  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
}

// Auth service
class AuthService {
  final ApiService _apiService;
  
  AuthService(this._apiService);
  
  Future<AuthResponse> loginWithPassword(String mobile, String password) async {
    return await _apiService.request(
      '/auth/login/password',
      method: 'POST',
      data: LoginRequest(mobile: mobile, password: password).toJson(),
      fromJson: (data) => AuthResponse.fromJson(data),
    );
  }
  
  Future<void> handleLoginSuccess(AuthResponse authData) async {
    await TokenStorage.saveTokens(
      authData.accessToken,
      authData.refreshToken,
    );
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', authData.user.id);
    await prefs.setString('username', authData.user.username);
  }
}

// Usage in widget
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = Get.find<AuthService>();
  bool _isLoading = false;
  
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authData = await _authService.loginWithPassword(
        _mobileController.text,
        _passwordController.text,
      );
      
      await _authService.handleLoginSuccess(authData);
      Get.offAllNamed('/home');
    } on ApiException catch (e) {
      Get.snackbar('Login Failed', e.message);
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _mobileController,
                decoration: InputDecoration(labelText: 'Mobile Number'),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter mobile number';
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter password';
                  return null;
                },
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : Text('Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Send SMS Verification Code

```dart
@JsonSerializable()
class SmsRequest {
  final String mobile;
  final String type; // register, login, reset
  
  SmsRequest({required this.mobile, required this.type});
  
  factory SmsRequest.fromJson(Map<String, dynamic> json) =>
      _$SmsRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SmsRequestToJson(this);
}

@JsonSerializable()
class SmsResponse {
  final String smsId;
  final int expireTime;
  
  SmsResponse({required this.smsId, required this.expireTime});
  
  factory SmsResponse.fromJson(Map<String, dynamic> json) =>
      _$SmsResponseFromJson(json);
}

class SmsService {
  final ApiService _apiService;
  
  SmsService(this._apiService);
  
  Future<SmsResponse> sendSmsCode(String mobile, String type) async {
    return await _apiService.request(
      '/auth/sms/send',
      method: 'POST',
      data: SmsRequest(mobile: mobile, type: type).toJson(),
      fromJson: (data) => SmsResponse.fromJson(data),
    );
  }
}

// SMS verification widget
class SmsVerificationWidget extends StatefulWidget {
  final String mobile;
  final String type;
  final Function(String smsCode, String smsId) onVerified;
  
  SmsVerificationWidget({
    required this.mobile,
    required this.type,
    required this.onVerified,
  });
  
  @override
  _SmsVerificationWidgetState createState() => _SmsVerificationWidgetState();
}

class _SmsVerificationWidgetState extends State<SmsVerificationWidget> {
  final _smsController = TextEditingController();
  final _smsService = Get.find<SmsService>();
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
      final response = await _smsService.sendSmsCode(widget.mobile, widget.type);
      setState(() {
        _smsId = response.smsId;
        _countdown = 60;
      });
      _startCountdown();
      
      Get.snackbar('Success', 'Verification code sent');
    } on ApiException catch (e) {
      Get.snackbar('Error', e.message);
    }
  }
  
  void _startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }
  
  void _verify() {
    if (_smsController.text.length == 4 && _smsId != null) {
      widget.onVerified(_smsController.text, _smsId!);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _smsController,
          decoration: InputDecoration(
            labelText: 'Enter 4-digit code',
            suffix: _countdown > 0
                ? Text('${_countdown}s')
                : TextButton(
                    onPressed: _sendSmsCode,
                    child: Text('Resend'),
                  ),
          ),
          keyboardType: TextInputType.number,
          maxLength: 4,
          onChanged: (value) {
            if (value.length == 4) _verify();
          },
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
```

### User Registration

```dart
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
    this.agreeTerms = true,
  });
  
  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}

// Registration service
Future<AuthResponse> register(RegisterRequest request) async {
  return await _apiService.request(
    '/auth/register',
    method: 'POST',
    data: request.toJson(),
    fromJson: (data) => AuthResponse.fromJson(data),
  );
}
```

---

## 🛒 Product Management Module

### Product Models

```dart
@JsonSerializable()
class ProductModel {
  final String id;
  final String title;
  final double price;
  final double? originalPrice;
  final String? discount;
  final String mainImage;
  final String condition;
  final String conditionText;
  final String location;
  final String? distance;
  final String publishTime;
  final bool hasWarranty;
  final String? warrantyText;
  final UserModel seller;
  final ProductStats stats;
  final List<String> tags;
  
  ProductModel({
    required this.id,
    required this.title,
    required this.price,
    this.originalPrice,
    this.discount,
    required this.mainImage,
    required this.condition,
    required this.conditionText,
    required this.location,
    this.distance,
    required this.publishTime,
    required this.hasWarranty,
    this.warrantyText,
    required this.seller,
    required this.stats,
    required this.tags,
  });
  
  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
}

@JsonSerializable()
class ProductStats {
  final int viewCount;
  final int favoriteCount;
  final int chatCount;
  final bool isOwn;
  final bool isFavorited;
  
  ProductStats({
    required this.viewCount,
    required this.favoriteCount,
    required this.chatCount,
    required this.isOwn,
    required this.isFavorited,
  });
  
  factory ProductStats.fromJson(Map<String, dynamic> json) =>
      _$ProductStatsFromJson(json);
}

@JsonSerializable()
class PagedResponse<T> {
  final List<T> content;
  final PaginationInfo pagination;
  final Map<String, dynamic>? filters;
  
  PagedResponse({
    required this.content,
    required this.pagination,
    this.filters,
  });
  
  factory PagedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return PagedResponse<T>(
      content: (json['content'] as List)
          .map((item) => fromJsonT(item))
          .toList(),
      pagination: PaginationInfo.fromJson(json['pagination']),
      filters: json['filters'],
    );
  }
}
```

### Product Service with Filtering

```dart
enum ProductFilter {
  all,
  discount,
  brand,
  popular,
  accessories,
}

extension ProductFilterExtension on ProductFilter {
  String get value {
    switch (this) {
      case ProductFilter.all:
        return 'all';
      case ProductFilter.discount:
        return 'discount';
      case ProductFilter.brand:
        return 'brand';
      case ProductFilter.popular:
        return 'popular';
      case ProductFilter.accessories:
        return 'accessories';
    }
  }
  
  String get displayName {
    switch (this) {
      case ProductFilter.all:
        return 'All';
      case ProductFilter.discount:
        return 'Discount';
      case ProductFilter.brand:
        return 'Brand';
      case ProductFilter.popular:
        return 'Popular';
      case ProductFilter.accessories:
        return 'Accessories';
    }
  }
}

class ProductService {
  final ApiService _apiService;
  
  ProductService(this._apiService);
  
  Future<PagedResponse<ProductModel>> getProducts({
    int page = 1,
    int size = 4,
    ProductFilter? filter,
    int? categoryId,
    String? keyword,
    double? minPrice,
    double? maxPrice,
    String? sort,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'size': size,
    };
    
    if (filter != null) queryParameters['filter'] = filter.value;
    if (categoryId != null) queryParameters['categoryId'] = categoryId;
    if (keyword != null) queryParameters['keyword'] = keyword;
    if (minPrice != null) queryParameters['minPrice'] = minPrice;
    if (maxPrice != null) queryParameters['maxPrice'] = maxPrice;
    if (sort != null) queryParameters['sort'] = sort;
    
    return await _apiService.request(
      '/products',
      queryParameters: queryParameters,
      fromJson: (data) => PagedResponse.fromJson(
        data,
        (json) => ProductModel.fromJson(json),
      ),
    );
  }
  
  Future<ProductModel> getProductDetail(String productId) async {
    return await _apiService.request(
      '/products/$productId',
      fromJson: (data) => ProductModel.fromJson(data),
    );
  }
  
  Future<FavoriteResult> toggleFavorite(String productId) async {
    return await _apiService.request(
      '/products/$productId/favorite',
      method: 'POST',
      fromJson: (data) => FavoriteResult.fromJson(data),
    );
  }
}

@JsonSerializable()
class FavoriteResult {
  final bool isFavorited;
  final int favoriteCount;
  
  FavoriteResult({required this.isFavorited, required this.favoriteCount});
  
  factory FavoriteResult.fromJson(Map<String, dynamic> json) =>
      _$FavoriteResultFromJson(json);
}
```

### Product List Widget with Filtering

```dart
class ProductListPage extends StatefulWidget {
  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final ProductService _productService = Get.find<ProductService>();
  final ScrollController _scrollController = ScrollController();
  
  List<ProductModel> _products = [];
  ProductFilter _currentFilter = ProductFilter.all;
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  
  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(_onScroll);
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent &&
        !_isLoading &&
        _hasMore) {
      _loadMoreProducts();
    }
  }
  
  Future<void> _loadProducts({bool refresh = false}) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      if (refresh) {
        _products.clear();
        _currentPage = 1;
        _hasMore = true;
      }
    });
    
    try {
      final response = await _productService.getProducts(
        page: _currentPage,
        filter: _currentFilter,
      );
      
      setState(() {
        if (refresh) {
          _products = response.content;
        } else {
          _products.addAll(response.content);
        }
        _hasMore = response.pagination.hasNext;
        _currentPage++;
      });
    } on ApiException catch (e) {
      Get.snackbar('Error', e.message);
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _loadMoreProducts() async {
    await _loadProducts();
  }
  
  void _onFilterChanged(ProductFilter filter) {
    if (_currentFilter != filter) {
      setState(() => _currentFilter = filter);
      _loadProducts(refresh: true);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Products')),
      body: Column(
        children: [
          // Filter tabs
          Container(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: ProductFilter.values.length,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final filter = ProductFilter.values[index];
                final isActive = _currentFilter == filter;
                
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter.displayName),
                    selected: isActive,
                    onSelected: (_) => _onFilterChanged(filter),
                  ),
                );
              },
            ),
          ),
          
          // Product list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadProducts(refresh: true),
              child: _products.isEmpty && _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _products.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _products.length) {
                          return Center(child: CircularProgressIndicator());
                        }
                        
                        return ProductCard(
                          product: _products[index],
                          onTap: () => _navigateToDetail(_products[index]),
                          onFavorite: () => _toggleFavorite(_products[index]),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _navigateToDetail(ProductModel product) {
    Get.toNamed('/product-detail', arguments: product);
  }
  
  Future<void> _toggleFavorite(ProductModel product) async {
    try {
      final result = await _productService.toggleFavorite(product.id);
      
      setState(() {
        final index = _products.indexWhere((p) => p.id == product.id);
        if (index >= 0) {
          _products[index] = _products[index].copyWith(
            stats: _products[index].stats.copyWith(
              isFavorited: result.isFavorited,
              favoriteCount: result.favoriteCount,
            ),
          );
        }
      });
      
      Get.snackbar(
        'Success',
        result.isFavorited ? 'Added to favorites' : 'Removed from favorites',
      );
    } on ApiException catch (e) {
      Get.snackbar('Error', e.message);
    }
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
```

### Product Card Widget

```dart
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  
  const ProductCard({
    Key? key,
    required this.product,
    this.onTap,
    this.onFavorite,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    child: CachedNetworkImage(
                      imageUrl: _getImageUrl(product.mainImage),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.error),
                      ),
                    ),
                  ),
                  
                  // Favorite button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          product.stats.isFavorited
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: product.stats.isFavorited
                              ? Colors.red
                              : Colors.grey,
                        ),
                        onPressed: onFavorite,
                        padding: EdgeInsets.all(4),
                        constraints: BoxConstraints(),
                      ),
                    ),
                  ),
                  
                  // Discount badge
                  if (product.discount != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.discount!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Product info
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      product.title,
                      style: TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: 4),
                    
                    // Price
                    Row(
                      children: [
                        Text(
                          '¥${product.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (product.originalPrice != null) ...[
                          SizedBox(width: 4),
                          Text(
                            '¥${product.originalPrice!.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    SizedBox(height: 4),
                    
                    // Location and condition
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 12, color: Colors.grey),
                        Expanded(
                          child: Text(
                            product.location,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    Text(
                      product.conditionText,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    
                    // Stats
                    Row(
                      children: [
                        Icon(Icons.visibility, size: 12, color: Colors.grey),
                        Text(
                          ' ${product.stats.viewCount}',
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.favorite, size: 12, color: Colors.grey),
                        Text(
                          ' ${product.stats.favoriteCount}',
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getImageUrl(String imageName) {
    // Replace with your actual CDN URL
    return 'https://cdn.fliliy.com/products/medium/$imageName';
  }
}
```

---

## 💬 Chat System

### Chat Models

```dart
@JsonSerializable()
class ChatRoomModel {
  final String id;
  final ProductModel product;
  final UserModel otherUser;
  final ChatMessageModel? lastMessage;
  final int unreadCount;
  final String lastActiveTime;
  
  ChatRoomModel({
    required this.id,
    required this.product,
    required this.otherUser,
    this.lastMessage,
    required this.unreadCount,
    required this.lastActiveTime,
  });
  
  factory ChatRoomModel.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomModelFromJson(json);
}

@JsonSerializable()
class ChatMessageModel {
  final String id;
  final String senderId;
  final String type; // TEXT, IMAGE, FILE
  final String content;
  final String? imageUrl;
  final String? fileUrl;
  final String? fileName;
  final String createdAt;
  final bool isRead;
  
  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.type,
    required this.content,
    this.imageUrl,
    this.fileUrl,
    this.fileName,
    required this.createdAt,
    required this.isRead,
  });
  
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$ChatMessageModelToJson(this);
}
```

### Chat Service

```dart
class ChatService {
  final ApiService _apiService;
  
  ChatService(this._apiService);
  
  Future<List<ChatRoomModel>> getChatList() async {
    return await _apiService.request(
      '/chats',
      fromJson: (data) => (data as List)
          .map((json) => ChatRoomModel.fromJson(json))
          .toList(),
    );
  }
  
  Future<ChatRoomModel> createChatRoom(String productId) async {
    return await _apiService.request(
      '/chats/rooms',
      method: 'POST',
      queryParameters: {'productId': productId},
      fromJson: (data) => ChatRoomModel.fromJson(data),
    );
  }
  
  Future<ChatMessageModel> sendMessage(String roomId, {
    required String type,
    required String content,
    String? imageUrl,
    String? fileUrl,
    String? fileName,
  }) async {
    final messageData = {
      'type': type,
      'content': content,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (fileName != null) 'fileName': fileName,
    };
    
    return await _apiService.request(
      '/chats/$roomId/messages',
      method: 'POST',
      data: messageData,
      fromJson: (data) => ChatMessageModel.fromJson(data),
    );
  }
  
  Future<PagedResponse<ChatMessageModel>> getChatMessages(
    String roomId, {
    int page = 1,
    int size = 20,
  }) async {
    return await _apiService.request(
      '/chats/$roomId/messages',
      queryParameters: {'page': page, 'size': size},
      fromJson: (data) => PagedResponse.fromJson(
        data,
        (json) => ChatMessageModel.fromJson(json),
      ),
    );
  }
}
```

### Chat Screen

```dart
class ChatScreen extends StatefulWidget {
  final ChatRoomModel chatRoom;
  
  const ChatScreen({Key? key, required this.chatRoom}) : super(key: key);
  
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = Get.find<ChatService>();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  String? _currentUserId;
  
  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
    _loadMessages();
  }
  
  Future<void> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('user_id');
  }
  
  Future<void> _loadMessages() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final response = await _chatService.getChatMessages(widget.chatRoom.id);
      setState(() {
        _messages = response.content.reversed.toList();
      });
      _scrollToBottom();
    } on ApiException catch (e) {
      Get.snackbar('Error', e.message);
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    
    _messageController.clear();
    
    try {
      final message = await _chatService.sendMessage(
        widget.chatRoom.id,
        type: 'TEXT',
        content: content,
      );
      
      setState(() {
        _messages.add(message);
      });
      _scrollToBottom();
    } on ApiException catch (e) {
      Get.snackbar('Error', e.message);
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatRoom.otherUser.username),
        actions: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () => _showProductInfo(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Product info bar
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: _getImageUrl(widget.chatRoom.product.mainImage),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.chatRoom.product.title,
                        style: TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '¥${widget.chatRoom.product.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Messages
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message.senderId == _currentUserId;
                      
                      return MessageBubble(
                        message: message,
                        isMe: isMe,
                      );
                    },
                  ),
          ),
          
          // Input
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  child: Icon(Icons.send),
                  mini: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _showProductInfo() {
    Get.toNamed('/product-detail', arguments: widget.chatRoom.product);
  }
  
  String _getImageUrl(String imageName) {
    return 'https://cdn.fliliy.com/products/thumb/$imageName';
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  
  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue : Colors.grey[300],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black,
                ),
              ),
            ),
            SizedBox(height: 2),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatTime(String dateTimeStr) {
    final dateTime = DateTime.parse(dateTimeStr);
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
```

---

## 📱 State Management with GetX

### Product Controller

```dart
class ProductController extends GetxController {
  final ProductService _productService = Get.find<ProductService>();
  
  // Observable state
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasMore = true.obs;
  final Rx<ProductFilter> currentFilter = ProductFilter.all.obs;
  final RxInt currentPage = 1.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }
  
  Future<void> loadProducts({bool refresh = false}) async {
    if (isLoading.value) return;
    
    isLoading.value = true;
    
    if (refresh) {
      products.clear();
      currentPage.value = 1;
      hasMore.value = true;
    }
    
    try {
      final response = await _productService.getProducts(
        page: currentPage.value,
        filter: currentFilter.value,
      );
      
      if (refresh) {
        products.value = response.content;
      } else {
        products.addAll(response.content);
      }
      
      hasMore.value = response.pagination.hasNext;
      currentPage.value++;
    } on ApiException catch (e) {
      Get.snackbar('Error', e.message);
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> changeFilter(ProductFilter filter) async {
    if (currentFilter.value != filter) {
      currentFilter.value = filter;
      await loadProducts(refresh: true);
    }
  }
  
  Future<void> toggleFavorite(String productId) async {
    try {
      final result = await _productService.toggleFavorite(productId);
      
      final index = products.indexWhere((p) => p.id == productId);
      if (index >= 0) {
        products[index] = products[index].copyWith(
          stats: products[index].stats.copyWith(
            isFavorited: result.isFavorited,
            favoriteCount: result.favoriteCount,
          ),
        );
      }
      
      Get.snackbar(
        'Success',
        result.isFavorited ? 'Added to favorites' : 'Removed from favorites',
      );
    } on ApiException catch (e) {
      Get.snackbar('Error', e.message);
    }
  }
}

// Usage in widget
class ProductListWidget extends StatelessWidget {
  final ProductController controller = Get.find<ProductController>();
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter tabs
        Obx(() => SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: ProductFilter.values.length,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final filter = ProductFilter.values[index];
              final isActive = controller.currentFilter.value == filter;
              
              return Padding(
                padding: EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter.displayName),
                  selected: isActive,
                  onSelected: (_) => controller.changeFilter(filter),
                ),
              );
            },
          ),
        )),
        
        // Product grid
        Expanded(
          child: Obx(() => RefreshIndicator(
            onRefresh: () => controller.loadProducts(refresh: true),
            child: controller.products.isEmpty && controller.isLoading.value
                ? Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: controller.products.length + 
                               (controller.hasMore.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= controller.products.length) {
                        return Center(child: CircularProgressIndicator());
                      }
                      
                      final product = controller.products[index];
                      return ProductCard(
                        product: product,
                        onTap: () => Get.toNamed(
                          '/product-detail',
                          arguments: product,
                        ),
                        onFavorite: () => controller.toggleFavorite(product.id),
                      );
                    },
                  ),
          )),
        ),
      ],
    );
  }
}
```

---

## 🔧 Utility Classes

### Network Connectivity

```dart
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  final RxBool isConnected = true.obs;
  
  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }
  
  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      print('Connectivity check failed: $e');
    }
  }
  
  void _updateConnectionStatus(ConnectivityResult result) {
    isConnected.value = result != ConnectivityResult.none;
    if (!isConnected.value) {
      Get.snackbar(
        'No Internet',
        'Please check your internet connection',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
```

### Image Picker Helper

```dart
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();
  
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );
      return image;
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: $e');
      return null;
    }
  }
  
  Future<List<XFile>?> pickMultipleImages() async {
    try {
      final List<XFile>? images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );
      return images;
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick images: $e');
      return null;
    }
  }
}
```

### Responsive Design Helper

```dart
class ResponsiveHelper {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;
  
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;
  
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;
  
  static int getGridCrossAxisCount(BuildContext context) {
    if (isDesktop(context)) return 4;
    if (isTablet(context)) return 3;
    return 2;
  }
  
  static double getCardAspectRatio(BuildContext context) {
    if (isDesktop(context)) return 0.8;
    if (isTablet(context)) return 0.75;
    return 0.7;
  }
}
```

---

## 🎯 Performance Optimization

### Lazy Loading Images

```dart
class LazyLoadImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  
  const LazyLoadImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[200],
        child: Icon(Icons.error, color: Colors.grey),
      ),
    );
  }
}
```

### Pagination Helper

```dart
mixin PaginationMixin<T extends StatefulWidget> on State<T> {
  ScrollController get scrollController;
  bool get isLoading;
  bool get hasMore;
  Future<void> loadMoreData();
  
  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
  }
  
  void _onScroll() {
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent &&
        !isLoading &&
        hasMore) {
      loadMoreData();
    }
  }
  
  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    super.dispose();
  }
}
```

---

## 📊 Analytics Integration

```dart
class AnalyticsService extends GetxService {
  Future<void> trackEvent(String eventName, Map<String, dynamic> parameters) async {
    try {
      // Replace with your analytics service (Firebase Analytics, etc.)
      print('Analytics Event: $eventName, Parameters: $parameters');
      
      // Example Firebase Analytics call:
      // await FirebaseAnalytics.instance.logEvent(
      //   name: eventName,
      //   parameters: parameters,
      // );
    } catch (e) {
      print('Analytics error: $e');
    }
  }
  
  Future<void> trackProductView(ProductModel product) async {
    await trackEvent('product_view', {
      'product_id': product.id,
      'product_title': product.title,
      'product_price': product.price,
      'product_category': product.stats.toString(), // Replace with actual category
    });
  }
  
  Future<void> trackSearch(String query, ProductFilter? filter) async {
    await trackEvent('search', {
      'query': query,
      'filter': filter?.value,
    });
  }
  
  Future<void> trackFavorite(String productId, bool isFavorited) async {
    await trackEvent('favorite_toggle', {
      'product_id': productId,
      'action': isFavorited ? 'add' : 'remove',
    });
  }
}
```

---

## 📱 App Structure Example

### main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependencies
  await initDependencies();
  
  runApp(MyApp());
}

Future<void> initDependencies() async {
  // Core services
  Get.put(ApiService());
  Get.put(NetworkService());
  Get.put(AnalyticsService());
  
  // Business services
  Get.put(AuthService(Get.find()));
  Get.put(ProductService(Get.find()));
  Get.put(ChatService(Get.find()));
  Get.put(SmsService(Get.find()));
  
  // Controllers
  Get.put(ProductController());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Fliliy Second-Hand Platform',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/splash',
      getPages: AppRoutes.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

### Routes

```dart
class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String productDetail = '/product-detail';
  static const String chat = '/chat';
  static const String profile = '/profile';
  
  static List<GetPage> routes = [
    GetPage(name: splash, page: () => SplashPage()),
    GetPage(name: login, page: () => LoginPage()),
    GetPage(name: register, page: () => RegisterPage()),
    GetPage(name: home, page: () => HomePage()),
    GetPage(name: productDetail, page: () => ProductDetailPage()),
    GetPage(name: chat, page: () => ChatListPage()),
    GetPage(name: profile, page: () => ProfilePage()),
  ];
}
```

---

## 🚀 Build Configuration

### pubspec.yaml

```yaml
name: fliliy_app
description: Fliliy Second-Hand Trading Platform

version: 1.0.0+1

environment:
  sdk: '>=2.19.0 <4.0.0'
  flutter: ">=3.7.0"

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  get: ^4.6.6
  
  # HTTP & API
  dio: ^5.3.2
  
  # JSON Serialization
  json_annotation: ^4.8.1
  
  # Local Storage
  shared_preferences: ^2.2.2
  
  # Network Images
  cached_network_image: ^3.3.0
  
  # Image Picker
  image_picker: ^1.0.4
  
  # Connectivity
  connectivity_plus: ^5.0.1
  
  # UI Components
  cupertino_icons: ^1.0.6
  
  # Utils
  intl: ^0.18.1

dev_dependencies:
  flutter_test:
    sdk: flutter
    
  # JSON Code Generation
  json_serializable: ^6.7.1
  build_runner: ^2.4.7
  
  # Linting
  flutter_lints: ^2.0.0

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/icons/
```

---

## 🎯 Next Steps for Flutter Development

1. **Setup project structure** - Initialize Flutter project with dependencies
2. **Implement authentication flow** - Login, registration, and token management
3. **Create product filtering system** - Implement the 5 filter types
4. **Build product details screen** - Image gallery, seller info, chat integration
5. **Implement real-time chat** - WebSocket integration when backend is ready
6. **Add offline support** - Cache products and handle network connectivity
7. **Performance optimization** - Image caching, lazy loading, and pagination
8. **Testing** - Unit tests, widget tests, and integration tests

---

**Document Version**: v2.2  
**Last Updated**: 2025-09-09  
**Status**: Production Ready  
**Flutter SDK**: >=3.7.0  
**Dart SDK**: >=2.19.0