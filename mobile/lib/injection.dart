import 'core/network/api_client.dart';
import 'core/config/app_config.dart';

// Health
import 'features/health/data/datasources/health_remote_data_source.dart';
import 'features/health/data/repositories/health_repository_impl.dart';
import 'features/health/domain/repositories/health_repository.dart';
import 'features/health/domain/usecases/get_health.dart';
import 'features/health/presentation/state/health_store.dart';

// Product
import 'features/product/data/datasources/product_remote_data_source.dart';
import 'features/product/data/repositories/product_repository_impl.dart';
import 'features/product/data/repositories/product_repository_fake.dart';
import 'features/product/domain/repositories/product_repository.dart';
import 'features/product/domain/usecases/get_products.dart';
import 'features/product/domain/usecases/get_product_detail.dart';
import 'features/product/domain/usecases/search_products.dart';
import 'features/product/domain/usecases/get_user_favorites.dart';
import 'features/product/domain/usecases/toggle_favorite.dart';
import 'features/product/presentation/state/home_store.dart';

// Banner
import 'features/banner/data/data_sources/banner_remote_data_source.dart';
import 'features/banner/data/repositories/banner_repository_impl.dart';
import 'features/banner/domain/repositories/banner_repository.dart';
import 'features/banner/domain/usecases/get_banners.dart';

// Category
import 'features/category/data/datasources/category_remote_data_source.dart';
import 'features/category/data/repositories/category_repository_impl.dart';
import 'features/category/domain/repositories/category_repository.dart';
import 'features/category/domain/usecases/get_categories.dart';

// Auth
import 'features/auth/data/datasources/auth_remote_data_source.dart';

// File Upload
import 'features/file/data/datasources/file_remote_data_source.dart';
import 'package:http/http.dart' as http;


// Transaction
import 'features/transaction/data/datasources/transaction_remote_data_source.dart';
import 'features/transaction/data/datasources/transaction_remote_data_source_impl.dart';
import 'features/transaction/data/datasources/transaction_mock_data_source.dart';
import 'features/transaction/data/repositories/transaction_repository_impl.dart';
import 'features/transaction/domain/repositories/transaction_repository.dart';
import 'features/transaction/domain/usecases/create_inquiry.dart';
import 'features/transaction/domain/usecases/create_transaction_request.dart';
import 'features/transaction/domain/usecases/respond_to_transaction_request.dart';
import 'features/transaction/domain/usecases/agree_offline_transaction.dart';
import 'features/transaction/domain/usecases/complete_transaction.dart';
import 'features/transaction/domain/usecases/get_transactions.dart';
import 'features/transaction/domain/usecases/get_transaction_code.dart';
import 'features/transaction/domain/usecases/get_transaction_detail.dart';

// Chat
import 'features/chat/data/datasources/chat_remote_data_source.dart';
import 'features/chat/data/datasources/chat_remote_data_source_impl.dart';
import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/chat/domain/repositories/chat_repository.dart';
import 'features/chat/domain/usecases/get_chat_list.dart';
import 'features/chat/domain/usecases/get_chat_messages.dart';
import 'features/chat/domain/usecases/send_message.dart';
import 'features/chat/domain/usecases/mark_as_read.dart';
import 'features/chat/domain/usecases/recall_message.dart';
import 'features/chat/domain/usecases/upload_chat_file.dart';
import 'features/chat/domain/usecases/create_chat_room.dart';
import 'features/chat/domain/usecases/start_product_discussion.dart';
import 'features/chat/domain/usecases/get_total_unread_count.dart';
import 'features/chat/data/services/chat_websocket_service.dart';
import 'features/chat/data/services/chat_service.dart';

// Profile - User Products
import 'features/profile/data/datasources/user_products_remote_data_source.dart';
import 'features/profile/data/repositories/user_products_repository_impl.dart';
import 'features/profile/domain/repositories/user_products_repository.dart';
import 'features/profile/domain/usecases/get_user_products_usecase.dart';

/// Dependency Injection Container
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  final Map<Type, dynamic> _services = {};

  /// Register Service
  void registerSingleton<T>(T service) {
    _services[T] = service;
  }

  /// Get Service
  T get<T>() {
    final service = _services[T];
    if (service == null) {
      throw Exception('Service of type $T is not registered');
    }
    return service as T;
  }

  /// Initialize All Services
  Future<void> init() async {
    // Core Services
    registerSingleton<ApiClient>(ApiClient());

    // Health Services
    registerSingleton<HealthRemoteDataSource>(
      HealthRemoteDataSourceImpl(get<ApiClient>()),
    );
    registerSingleton<HealthRepository>(
      HealthRepositoryImpl(get<HealthRemoteDataSource>()),
    );
    registerSingleton<GetHealth>(
      GetHealth(get<HealthRepository>()),
    );

    // Product Services
    if (AppConfig.useMock) {
      registerSingleton<ProductRepository>(ProductRepositoryFake());
    } else {
      registerSingleton<ProductRemoteDataSource>(
        ProductRemoteDataSourceImpl(get<ApiClient>()),
      );
      registerSingleton<ProductRepository>(
        ProductRepositoryImpl(get<ProductRemoteDataSource>()),
      );
    }
    registerSingleton<GetProducts>(
      GetProducts(get<ProductRepository>()),
    );
    registerSingleton<GetProductDetail>(
      GetProductDetail(get<ProductRepository>()),
    );
    registerSingleton<SearchProducts>(
      SearchProducts(get<ProductRepository>()),
    );
    registerSingleton<GetUserFavorites>(
      GetUserFavorites(get<ProductRepository>()),
    );
    registerSingleton<ToggleFavorite>(
      ToggleFavorite(get<ProductRepository>()),
    );

    // Banner Services
    registerSingleton<BannerRemoteDataSource>(
      BannerRemoteDataSourceImpl(get<ApiClient>()),
    );
    registerSingleton<BannerRepository>(
      BannerRepositoryImpl(get<BannerRemoteDataSource>()),
    );
    registerSingleton<GetBanners>(
      GetBanners(get<BannerRepository>()),
    );

    // Category Services
    registerSingleton<CategoryRemoteDataSource>(
      CategoryRemoteDataSourceImpl(get<ApiClient>()),
    );
    registerSingleton<CategoryRepository>(
      CategoryRepositoryImpl(get<CategoryRemoteDataSource>()),
    );
    registerSingleton<GetCategories>(
      GetCategories(get<CategoryRepository>()),
    );

    // Auth Services
    registerSingleton<AuthRemoteDataSource>(
      AuthRemoteDataSourceImpl(get<ApiClient>()),
    );

    // File Upload Services
    registerSingleton<FileRemoteDataSource>(
      FileRemoteDataSourceImpl(http.Client()),
    );


    // Transaction Services
    if (AppConfig.useMock) {
      registerSingleton<TransactionRemoteDataSource>(
        TransactionMockDataSource(),
      );
    } else {
      registerSingleton<TransactionRemoteDataSource>(
        TransactionRemoteDataSourceImpl(get<ApiClient>()),
      );
    }
    registerSingleton<TransactionRepository>(
      TransactionRepositoryImpl(get<TransactionRemoteDataSource>()),
    );
    registerSingleton<CreateInquiry>(
      CreateInquiry(get<TransactionRepository>()),
    );
    registerSingleton<CreateTransactionRequest>(
      CreateTransactionRequest(get<TransactionRepository>()),
    );
    registerSingleton<RespondToTransactionRequest>(
      RespondToTransactionRequest(get<TransactionRepository>()),
    );
    registerSingleton<AgreeOfflineTransaction>(
      AgreeOfflineTransaction(get<TransactionRepository>()),
    );
    registerSingleton<CompleteTransaction>(
      CompleteTransaction(get<TransactionRepository>()),
    );
    registerSingleton<GetTransactions>(
      GetTransactions(get<TransactionRepository>()),
    );
    registerSingleton<GetTransactionCode>(
      GetTransactionCode(get<TransactionRepository>()),
    );
    registerSingleton<GetTransactionDetail>(
      GetTransactionDetail(get<TransactionRepository>()),
    );

    // Chat Services
    registerSingleton<ChatRemoteDataSource>(
      ChatRemoteDataSourceImpl(get<ApiClient>()),
    );
    registerSingleton<ChatRepository>(
      ChatRepositoryImpl(get<ChatRemoteDataSource>()),
    );
    registerSingleton<GetChatList>(
      GetChatList(get<ChatRepository>()),
    );
    registerSingleton<GetChatMessages>(
      GetChatMessages(get<ChatRepository>()),
    );
    registerSingleton<SendMessage>(
      SendMessage(get<ChatRepository>()),
    );
    registerSingleton<MarkAsRead>(
      MarkAsRead(get<ChatRepository>()),
    );
    registerSingleton<RecallMessage>(
      RecallMessage(get<ChatRepository>()),
    );
    registerSingleton<UploadChatFile>(
      UploadChatFile(get<ChatRepository>()),
    );
    registerSingleton<GetTotalUnreadCount>(
      GetTotalUnreadCount(get<ChatRepository>()),
    );
    registerSingleton<CreateChatRoom>(
      CreateChatRoom(get<ChatRepository>()),
    );
    registerSingleton<StartProductDiscussion>(
      StartProductDiscussion(get<ChatRepository>()),
    );
    registerSingleton<ChatWebSocketService>(
      ChatWebSocketService(),
    );
    registerSingleton<ChatService>(
      ChatService(get<ChatRepository>(), get<ChatWebSocketService>()),
    );

    // Profile - User Products Services
    registerSingleton<UserProductsRemoteDataSource>(
      UserProductsRemoteDataSourceImpl(get<ApiClient>()),
    );
    registerSingleton<UserProductsRepository>(
      UserProductsRepositoryImpl(get<UserProductsRemoteDataSource>()),
    );
    registerSingleton<GetUserProductsUseCase>(
      GetUserProductsUseCase(get<UserProductsRepository>()),
    );

    // Initialize State Stores
    final healthStore = HealthStore(get<GetHealth>());
    registerSingleton<HealthStore>(healthStore);
    
    final homeStore = HomeStore(get<GetProducts>());
    registerSingleton<HomeStore>(homeStore);

    // Perform Initial Health Check
    if (!AppConfig.useMock) {
      await healthStore.checkHealth();
    }
  }

  /// Release Resources
  void dispose() {
    get<ApiClient>().dispose();
    get<ChatWebSocketService>().dispose();
    get<ChatService>().dispose();
    _services.clear();
  }
}
