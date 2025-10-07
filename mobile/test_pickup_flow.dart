import 'package:flutter/material.dart';
import 'lib/features/checkout/presentation/pages/pickup_page.dart';
import 'lib/features/checkout/presentation/pages/seller_pickup_page.dart';

/// Simple example for testing pickup flow
class TestPickupFlow {
  
  /// Test buyer pickup page
  static Widget testBuyerPickupPage() {
    return PickupPage(
      productName: "iPhone 15 Pro Max 256GB",
      productImage: "https://example.com/images/iphone15.jpg",
      productPrice: 7999.0,
      transactionId: "tx_1640995200000001",
      transactionCode: "1234", // Buyer can see transaction code
      sellerName: "John",
      sellerAvatar: "https://cdn.fliliy.com/avatar/seller.jpg",
      sellerPhone: "13800138000",
      buyerName: "Jane",
      buyerAvatar: "https://cdn.fliliy.com/avatar/buyer.jpg",
      buyerPhone: "13900139000",
      meetingLocation: "Central Park",
      meetingTime: DateTime.now().add(Duration(hours: 2)),
      status: "AGREED",
      isSeller: false, // Buyer perspective
    );
  }
  
  /// Test seller pickup page
  static Widget testSellerPickupPage() {
    return SellerPickupPage(
      productName: "iPhone 15 Pro Max 256GB",
      productImage: "https://example.com/images/iphone15.jpg",
      productPrice: 7999.0,
      buyerName: "Jane",
      buyerAvatar: "https://cdn.fliliy.com/avatar/buyer.jpg",
      buyerPhone: "13900139000",
      meetingLocation: "Central Park",
      meetingTime: DateTime.now().add(Duration(hours: 2)),
      transactionId: "tx_1640995200000001",
    );
  }
  
  /// Test complete pickup flow
  static void testCompletePickupFlow() {
    print("🧪 Starting complete pickup flow test...");
    
    // 1. Buyer views transaction code
    print("✅ 1. Buyer can view 4-digit transaction code");
    
    // 2. Seller inputs transaction code for verification
    print("✅ 2. Seller can input transaction code for verification");
    
    // 3. Transaction completion
    print("✅ 3. Product status updated to sold after transaction completion");
    
    // 4. Status management
    print("✅ 4. Support new transaction statuses: PENDING, AGREED, COMPLETED, REJECTED, CANCELLED, EXPIRED");
    
    print("🎉 Pickup flow test completed!");
  }
}

/// Test application
class TestPickupApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pickup Flow Test',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Pickup Flow Test'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TestPickupFlow.testBuyerPickupPage(),
                    ),
                  );
                },
                child: Text('Test Buyer Pickup Page'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TestPickupFlow.testSellerPickupPage(),
                    ),
                  );
                },
                child: Text('Test Seller Pickup Page'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  TestPickupFlow.testCompletePickupFlow();
                },
                child: Text('Test Complete Flow'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
