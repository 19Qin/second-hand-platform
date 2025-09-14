# 🚀 Fliliy Second-Hand Trading Platform API Documentation [Frontend Developer Version]

## 📖 Documentation Overview

**Version**: v2.2 [Frontend Developer Specialized Version]  
**Last Updated**: 2025-09-09  
**Target Users**: Frontend Developers  
**Document Features**: Focus on practicality, includes complete examples and error handling

---

## 🎯 Frontend Developer Quick Start Guide

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

```javascript
// Basic configuration
const API_BASE_URL = 'http://localhost:8080/api/v1';

// Unified request wrapper
const apiRequest = async (url, options = {}) => {
  const token = localStorage.getItem('accessToken');
  
  const config = {
    headers: {
      'Content-Type': 'application/json',
      ...(token && { 'Authorization': `Bearer ${token}` })
    },
    ...options
  };
  
  const response = await fetch(`${API_BASE_URL}${url}`, config);
  const result = await response.json();
  
  // Unified error handling
  if (result.code !== 200) {
    throw new Error(result.message);
  }
  
  return result.data;
};

// Quick usage examples
const login = (mobile, password) => 
  apiRequest('/auth/login/password', {
    method: 'POST',
    body: JSON.stringify({ mobile, password })
  });

const getProducts = (params = {}) => {
  const query = new URLSearchParams(params).toString();
  return apiRequest(`/products?${query}`);
};
```

### 3. **Authentication Setup**

```javascript
// Store tokens after login
const handleLoginSuccess = (authData) => {
  localStorage.setItem('accessToken', authData.accessToken);
  localStorage.setItem('refreshToken', authData.refreshToken);
  localStorage.setItem('userId', authData.user.id);
};

// Auto token refresh
const refreshAccessToken = async () => {
  const refreshToken = localStorage.getItem('refreshToken');
  if (!refreshToken) throw new Error('No refresh token');
  
  const data = await apiRequest('/auth/refresh', {
    method: 'POST',
    body: JSON.stringify({ refreshToken })
  });
  
  localStorage.setItem('accessToken', data.accessToken);
  return data.accessToken;
};
```

---

## 🔐 Authentication Module

### Login with Password

**Endpoint**: `POST /auth/login/password`

```javascript
const loginWithPassword = async (mobile, password) => {
  try {
    const data = await apiRequest('/auth/login/password', {
      method: 'POST',
      body: JSON.stringify({ mobile, password })
    });
    
    handleLoginSuccess(data);
    return data;
  } catch (error) {
    console.error('Login failed:', error.message);
    throw error;
  }
};

// Usage
await loginWithPassword('13800138000', 'password123');
```

### Send SMS Verification Code

**Endpoint**: `POST /auth/sms/send`

```javascript
const sendSmsCode = async (mobile, type = 'login') => {
  return await apiRequest('/auth/sms/send', {
    method: 'POST',
    body: JSON.stringify({ mobile, type })
  });
};

// Usage
const smsData = await sendSmsCode('13800138000', 'register');
console.log('SMS ID:', smsData.smsId); // Use this for verification
```

### User Registration

**Endpoint**: `POST /auth/register`

```javascript
const register = async (userData) => {
  return await apiRequest('/auth/register', {
    method: 'POST',
    body: JSON.stringify({
      username: userData.username,
      mobile: userData.mobile,
      password: userData.password,
      confirmPassword: userData.password,
      smsCode: userData.smsCode,
      smsId: userData.smsId,
      agreeTerms: true
    })
  });
};

// Usage
await register({
  username: 'John Doe',
  mobile: '13800138000',
  password: 'password123',
  smsCode: '1234',
  smsId: 'sms_1640995200000'
});
```

---

## 🛒 Product Management Module

### Get Products List (with Filtering)

**Endpoint**: `GET /products`

```javascript
const getProducts = async (filters = {}) => {
  const params = {
    page: filters.page || 1,
    size: filters.size || 4,
    ...(filters.filter && { filter: filters.filter }), // all, popular, discount, brand, accessories
    ...(filters.category && { categoryId: filters.category }),
    ...(filters.keyword && { keyword: filters.keyword }),
    ...(filters.minPrice && { minPrice: filters.minPrice }),
    ...(filters.maxPrice && { maxPrice: filters.maxPrice }),
    ...(filters.sort && { sort: filters.sort })
  };

  const query = new URLSearchParams(params).toString();
  return await apiRequest(`/products?${query}`);
};

// Usage Examples
const allProducts = await getProducts({ filter: 'all' });
const discountProducts = await getProducts({ filter: 'discount' });
const brandProducts = await getProducts({ filter: 'brand' });
const accessoriesProducts = await getProducts({ filter: 'accessories' });
const popularProducts = await getProducts({ filter: 'popular' });

// Search with filters
const searchResults = await getProducts({
  keyword: 'iPhone',
  filter: 'brand',
  minPrice: 1000,
  maxPrice: 5000,
  page: 1,
  size: 10
});
```

### Filter Types Explanation

```javascript
const FILTER_TYPES = {
  'all': 'Show all products (default behavior)',
  'discount': 'Products with original price and current price < original price',
  'brand': 'Products with brand keywords (Apple, Samsung, Sony, Nike, iPhone, PS5, etc.)',
  'popular': 'Popular products (viewCount > 50 OR favoriteCount > 5)',
  'accessories': 'Electronic accessories (headphones, chargers, cables, cases, etc.)'
};

// Filter usage in UI
const FilterButton = ({ type, active, onClick }) => (
  <button 
    className={`filter-btn ${active ? 'active' : ''}`}
    onClick={() => onClick(type)}
  >
    {type.charAt(0).toUpperCase() + type.slice(1)}
  </button>
);
```

### Get Product Details

**Endpoint**: `GET /products/{id}`

```javascript
const getProductDetail = async (productId) => {
  return await apiRequest(`/products/${productId}`);
};

// Usage
const product = await getProductDetail('1963907136069177344');
console.log('Product details:', product);
```

### Toggle Favorite

**Endpoint**: `POST /products/{id}/favorite`

```javascript
const toggleFavorite = async (productId) => {
  return await apiRequest(`/products/${productId}/favorite`, {
    method: 'POST'
  });
};

// Usage
const result = await toggleFavorite('1963907136069177344');
console.log('Is favorited:', result.isFavorited);
console.log('Total favorites:', result.favoriteCount);
```

### Upload Product Images

**Endpoint**: `POST /products/upload`

```javascript
const uploadProductImage = async (file) => {
  const formData = new FormData();
  formData.append('file', file);
  
  const token = localStorage.getItem('accessToken');
  const response = await fetch(`${API_BASE_URL}/products/upload`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`
    },
    body: formData
  });
  
  const result = await response.json();
  if (result.code !== 200) {
    throw new Error(result.message);
  }
  
  return result.data;
};

// Usage
const handleFileUpload = async (event) => {
  const file = event.target.files[0];
  if (!file) return;
  
  try {
    const uploadData = await uploadProductImage(file);
    console.log('Upload successful:', uploadData.fileName);
    console.log('File URL:', uploadData.url);
  } catch (error) {
    console.error('Upload failed:', error.message);
  }
};
```

### Publish Product

**Endpoint**: `POST /products`

```javascript
const publishProduct = async (productData) => {
  return await apiRequest('/products', {
    method: 'POST',
    body: JSON.stringify({
      title: productData.title,
      description: productData.description,
      price: productData.price,
      originalPrice: productData.originalPrice,
      condition: productData.condition, // NEW, LIKE_NEW, GOOD, FAIR, POOR
      categoryId: productData.categoryId,
      images: productData.images, // Array of uploaded image file names
      tags: productData.tags,
      location: {
        province: productData.location.province,
        city: productData.location.city,
        district: productData.location.district,
        detailAddress: productData.location.detailAddress,
        longitude: productData.location.longitude,
        latitude: productData.location.latitude
      },
      warranty: productData.warranty && {
        hasWarranty: productData.warranty.hasWarranty,
        warrantyType: productData.warranty.warrantyType,
        remainingMonths: productData.warranty.remainingMonths,
        description: productData.warranty.description
      },
      usageInfo: productData.usageInfo && {
        type: productData.usageInfo.type, // TIME, COUNT, NONE
        value: productData.usageInfo.value,
        unit: productData.usageInfo.unit // MONTH, YEAR, DAY
      }
    })
  });
};

// Usage
const newProduct = await publishProduct({
  title: 'iPhone 13 Pro Max',
  description: 'Excellent condition iPhone',
  price: 899.99,
  originalPrice: 1099.99,
  condition: 'LIKE_NEW',
  categoryId: 1,
  images: ['image1.jpg', 'image2.jpg'],
  tags: ['iPhone', 'Apple', 'Smartphone'],
  location: {
    province: 'California',
    city: 'San Francisco',
    district: 'Downtown',
    detailAddress: 'Market Street 123',
    longitude: -122.4194,
    latitude: 37.7749
  }
});
```

---

## 🏷️ Category Management

### Get Categories

**Endpoint**: `GET /categories`

```javascript
const getCategories = async () => {
  return await apiRequest('/categories');
};

// Usage
const categories = await getCategories();
console.log('Available categories:', categories);
```

---

## 💬 Chat System

### Get Chat List

**Endpoint**: `GET /chats`

```javascript
const getChatList = async () => {
  return await apiRequest('/chats');
};

// Usage
const chats = await getChatList();
console.log('Chat rooms:', chats);
```

### Create Chat Room

**Endpoint**: `POST /chats/rooms`

```javascript
const createChatRoom = async (productId) => {
  const params = new URLSearchParams({ productId }).toString();
  return await apiRequest(`/chats/rooms?${params}`, {
    method: 'POST'
  });
};

// Usage
const chatRoom = await createChatRoom('1963907136069177344');
console.log('Chat room ID:', chatRoom.id);
```

### Send Message

**Endpoint**: `POST /chats/{roomId}/messages`

```javascript
const sendMessage = async (roomId, message) => {
  return await apiRequest(`/chats/${roomId}/messages`, {
    method: 'POST',
    body: JSON.stringify({
      type: message.type || 'TEXT', // TEXT, IMAGE, FILE
      content: message.content,
      ...(message.imageUrl && { imageUrl: message.imageUrl }),
      ...(message.fileUrl && { fileUrl: message.fileUrl }),
      ...(message.fileName && { fileName: message.fileName })
    })
  });
};

// Usage
await sendMessage('1965087856607236096', {
  type: 'TEXT',
  content: 'Hello, is this item still available?'
});
```

### Get Chat Messages

**Endpoint**: `GET /chats/{roomId}/messages`

```javascript
const getChatMessages = async (roomId, page = 1, size = 20) => {
  const params = new URLSearchParams({ page, size }).toString();
  return await apiRequest(`/chats/${roomId}/messages?${params}`);
};

// Usage
const messages = await getChatMessages('1965087856607236096');
console.log('Chat history:', messages.content);
```

---

## 👤 User Management

### Get User Favorites

**Endpoint**: `GET /user/favorites`

```javascript
const getUserFavorites = async (page = 1, size = 10) => {
  const params = new URLSearchParams({ page, size }).toString();
  return await apiRequest(`/user/favorites?${params}`);
};

// Usage
const favorites = await getUserFavorites();
console.log('User favorites:', favorites.content);
```

### Get User Products

**Endpoint**: `GET /user/products`

```javascript
const getUserProducts = async (page = 1, size = 10) => {
  const params = new URLSearchParams({ page, size }).toString();
  return await apiRequest(`/user/products?${params}`);
};

// Usage
const userProducts = await getUserProducts();
console.log('User published products:', userProducts.content);
```

---

## 🎨 Frontend Integration Examples

### React Hook for Product Filtering

```javascript
import { useState, useEffect } from 'react';

const useProductFiltering = () => {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(false);
  const [filter, setFilter] = useState('all');
  
  const loadProducts = async (newFilter = filter) => {
    setLoading(true);
    try {
      const data = await getProducts({ filter: newFilter });
      setProducts(data.content);
    } catch (error) {
      console.error('Failed to load products:', error);
    } finally {
      setLoading(false);
    }
  };
  
  useEffect(() => {
    loadProducts();
  }, [filter]);
  
  return {
    products,
    loading,
    filter,
    setFilter: (newFilter) => {
      setFilter(newFilter);
      loadProducts(newFilter);
    }
  };
};

// Usage in component
const ProductList = () => {
  const { products, loading, filter, setFilter } = useProductFiltering();
  
  return (
    <div>
      <div className="filter-buttons">
        {['all', 'discount', 'brand', 'popular', 'accessories'].map(type => (
          <FilterButton 
            key={type}
            type={type} 
            active={filter === type}
            onClick={setFilter}
          />
        ))}
      </div>
      
      {loading ? (
        <div>Loading...</div>
      ) : (
        <div className="products-grid">
          {products.map(product => (
            <ProductCard key={product.id} product={product} />
          ))}
        </div>
      )}
    </div>
  );
};
```

### Vue.js Composition API Example

```javascript
import { ref, computed, onMounted } from 'vue';

export const useProducts = () => {
  const products = ref([]);
  const loading = ref(false);
  const currentFilter = ref('all');
  
  const filteredProducts = computed(() => {
    return products.value;
  });
  
  const applyFilter = async (filterType) => {
    currentFilter.value = filterType;
    loading.value = true;
    
    try {
      const data = await getProducts({ filter: filterType });
      products.value = data.content;
    } catch (error) {
      console.error('Filter failed:', error);
    } finally {
      loading.value = false;
    }
  };
  
  onMounted(() => {
    applyFilter('all');
  });
  
  return {
    products: filteredProducts,
    loading,
    currentFilter,
    applyFilter
  };
};
```

---

## ⚡ Performance Optimization Tips

### 1. **Request Caching**

```javascript
class ApiCache {
  constructor(ttl = 5 * 60 * 1000) { // 5 minutes default
    this.cache = new Map();
    this.ttl = ttl;
  }
  
  get(key) {
    const item = this.cache.get(key);
    if (!item) return null;
    
    if (Date.now() > item.expiry) {
      this.cache.delete(key);
      return null;
    }
    
    return item.data;
  }
  
  set(key, data) {
    this.cache.set(key, {
      data,
      expiry: Date.now() + this.ttl
    });
  }
}

const apiCache = new ApiCache();

const cachedApiRequest = async (url, options = {}) => {
  const cacheKey = `${url}${JSON.stringify(options)}`;
  const cached = apiCache.get(cacheKey);
  
  if (cached && options.method !== 'POST') {
    return cached;
  }
  
  const data = await apiRequest(url, options);
  
  if (options.method !== 'POST') {
    apiCache.set(cacheKey, data);
  }
  
  return data;
};
```

### 2. **Image Lazy Loading**

```javascript
const LazyImage = ({ src, alt, className }) => {
  const [loaded, setLoaded] = useState(false);
  const [inView, setInView] = useState(false);
  
  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setInView(true);
          observer.disconnect();
        }
      },
      { threshold: 0.1 }
    );
    
    if (ref.current) {
      observer.observe(ref.current);
    }
    
    return () => observer.disconnect();
  }, []);
  
  return (
    <div className={className}>
      {inView && (
        <img
          src={src}
          alt={alt}
          onLoad={() => setLoaded(true)}
          style={{ opacity: loaded ? 1 : 0 }}
        />
      )}
    </div>
  );
};
```

---

## 🚨 Error Handling Best Practices

### 1. **Global Error Handler**

```javascript
const GlobalErrorHandler = {
  handle: (error, context = '') => {
    console.error(`[${context}] Error:`, error);
    
    // Log to monitoring service
    if (typeof analytics !== 'undefined') {
      analytics.track('API Error', {
        error: error.message,
        context,
        timestamp: Date.now()
      });
    }
    
    // Show user-friendly message
    switch (true) {
      case error.message.includes('401'):
        return 'Please log in again';
      case error.message.includes('403'):
        return 'You do not have permission for this action';
      case error.message.includes('404'):
        return 'The requested resource was not found';
      case error.message.includes('500'):
        return 'Server error, please try again later';
      default:
        return error.message || 'An unexpected error occurred';
    }
  }
};

// Usage
try {
  await someApiCall();
} catch (error) {
  const userMessage = GlobalErrorHandler.handle(error, 'Product Loading');
  showToast(userMessage);
}
```

### 2. **Network Status Handling**

```javascript
const useNetworkStatus = () => {
  const [isOnline, setIsOnline] = useState(navigator.onLine);
  
  useEffect(() => {
    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);
    
    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);
    
    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);
  
  return isOnline;
};

// Enhanced API request with network check
const apiRequestWithNetworkCheck = async (url, options = {}) => {
  if (!navigator.onLine) {
    throw new Error('No internet connection');
  }
  
  return await apiRequest(url, options);
};
```

---

## 📱 Mobile Development Considerations

### 1. **Touch-Friendly Interactions**

```javascript
const TouchOptimizedButton = ({ onClick, children, disabled }) => {
  const [pressing, setPressing] = useState(false);
  
  const handleTouchStart = () => setPressing(true);
  const handleTouchEnd = () => {
    setPressing(false);
    if (!disabled) onClick();
  };
  
  return (
    <button
      className={`touch-btn ${pressing ? 'pressing' : ''} ${disabled ? 'disabled' : ''}`}
      onTouchStart={handleTouchStart}
      onTouchEnd={handleTouchEnd}
      onTouchCancel={() => setPressing(false)}
      disabled={disabled}
    >
      {children}
    </button>
  );
};
```

### 2. **Responsive Image Loading**

```javascript
const ResponsiveProductImage = ({ product }) => {
  const getImageUrl = (size = 'medium') => {
    const baseUrl = 'https://cdn.fliliy.com';
    switch (size) {
      case 'thumbnail': return `${baseUrl}/products/thumb/${product.mainImage}`;
      case 'medium': return `${baseUrl}/products/medium/${product.mainImage}`;
      case 'large': return `${baseUrl}/products/large/${product.mainImage}`;
      default: return `${baseUrl}/products/${product.mainImage}`;
    }
  };
  
  return (
    <picture>
      <source media="(max-width: 320px)" srcSet={getImageUrl('thumbnail')} />
      <source media="(max-width: 768px)" srcSet={getImageUrl('medium')} />
      <img src={getImageUrl('large')} alt={product.title} />
    </picture>
  );
};
```

---

## 🔧 Development Tools

### 1. **API Testing Helper**

```javascript
const ApiTester = {
  async testAllEndpoints() {
    const tests = [
      { name: 'Health Check', call: () => apiRequest('/health') },
      { name: 'Get Categories', call: () => apiRequest('/categories') },
      { name: 'Get Products', call: () => apiRequest('/products?filter=all') },
    ];
    
    for (const test of tests) {
      try {
        await test.call();
        console.log(`✅ ${test.name} - PASSED`);
      } catch (error) {
        console.error(`❌ ${test.name} - FAILED:`, error.message);
      }
    }
  }
};

// Run in development
if (process.env.NODE_ENV === 'development') {
  window.ApiTester = ApiTester;
}
```

### 2. **Debug Mode**

```javascript
const DEBUG_MODE = process.env.NODE_ENV === 'development';

const debugLog = (message, data) => {
  if (DEBUG_MODE) {
    console.group(`🔍 [API Debug] ${message}`);
    console.log('Data:', data);
    console.log('Timestamp:', new Date().toLocaleTimeString());
    console.groupEnd();
  }
};

// Usage
const debugApiRequest = async (url, options = {}) => {
  debugLog('Request', { url, options });
  
  try {
    const result = await apiRequest(url, options);
    debugLog('Response', result);
    return result;
  } catch (error) {
    debugLog('Error', error);
    throw error;
  }
};
```

---

## 📊 Status Codes Reference

| Code | Meaning | Frontend Action |
|------|---------|----------------|
| 200 | Success | Proceed normally |
| 400 | Bad Request | Show validation errors |
| 401 | Unauthorized | Redirect to login |
| 403 | Forbidden | Show permission denied message |
| 404 | Not Found | Show not found page |
| 429 | Rate Limited | Show "too many requests" message |
| 500 | Server Error | Show generic error message |

---

## 🎯 Next Steps for Frontend Development

1. **Set up authentication flow** - Implement login, registration, and token management
2. **Create product filtering UI** - Implement the 5 filter types (all, discount, brand, popular, accessories)
3. **Build product details page** - Include image gallery, seller info, and chat integration
4. **Implement chat system** - Real-time messaging interface
5. **Add user profile management** - Favorites, published products, and settings

---

**Document Version**: v2.2  
**Last Updated**: 2025-09-09  
**Status**: Production Ready  
**Next Update**: After WebSocket implementation
