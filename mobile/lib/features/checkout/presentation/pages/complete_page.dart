import 'package:flutter/material.dart';
import 'package:mobile/root_shell.dart';

class CompletePage extends StatelessWidget {
  final String productName;
  final String productImage;
  final double productPrice;
  final bool isDelivery; // Whether it is a delivery order
  final bool isSeller; // Whether it is a seller completion page

  const CompletePage({
    Key? key,
    this.productName = "Unknown Product",
    this.productImage = "assets/placeholder.png",
    this.productPrice = 0.0,
    this.isDelivery = false, // Default to pickup order
    this.isSeller = false, // Default to buyer page
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        centerTitle: true,
        backgroundColor: Color(0xFF32C286),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Color(0xFF32C286), size: 100),
              const SizedBox(height: 20),
              Text(
                _getSuccessMessage(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _getDescriptionText(),
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                productName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Image.asset(
                productImage,
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              Text(
                "\$${productPrice.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 18, color: Colors.red),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // ⚡ Return to main app and clear navigation stack (avoid returning to payment page)
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const RootShell()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF32C286),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Back to Home",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    if (isSeller) {
      return "Transaction Completed";
    } else if (isDelivery) {
      return "Order Completed";
    } else {
      return "Booking Completed";
    }
  }

  String _getSuccessMessage() {
    if (isSeller) {
      return "Transaction completed successfully!";
    } else if (isDelivery) {
      return "Order successful!";
    } else {
      return "Booking request sent successfully";
    }
  }

  String _getDescriptionText() {
    if (isSeller) {
      return "You have successfully sold:";
    } else if (isDelivery) {
      return "You have purchased:";
    } else {
      return "You have booked:";
    }
  }
}
