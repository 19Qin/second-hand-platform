import 'dart:async';
import 'package:flutter/material.dart';
import 'complete_page.dart';
import '../../../../injection.dart';
import '../../../transaction/domain/usecases/complete_transaction.dart';
import '../../../transaction/domain/usecases/get_transactions.dart';
import '../../../transaction/domain/usecases/get_transaction_code.dart';

class SellerPickupPage extends StatefulWidget {
  final String productName;
  final String productImage;
  final double productPrice;
  final String buyerName;
  final String? buyerAvatar;
  final String buyerPhone;
  final String meetingLocation;
  final DateTime meetingTime;
  final String? transactionId;

  const SellerPickupPage({
    Key? key,
    required this.productName,
    required this.productImage,
    required this.productPrice,
    required this.buyerName,
    this.buyerAvatar,
    required this.buyerPhone,
    required this.meetingLocation,
    required this.meetingTime,
    this.transactionId,
  }) : super(key: key);

  @override
  _SellerPickupPageState createState() => _SellerPickupPageState();
}

class _SellerPickupPageState extends State<SellerPickupPage> {
  late Timer _timer;
  Duration remaining = Duration(days: 7); // Default countdown from 7 days
  List<String> transactionCode = ['', '', '', '']; // 4-digit transaction code that seller needs to input
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  bool _isCodeValid = false;
  
  // Drag related state
  double _mapHeight = 400.0; // Initial map height
  final double _minMapHeight = 200.0; // Minimum map height
  final double _maxMapHeight = 600.0; // Maximum map height
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers and focus nodes
    for (int i = 0; i < 4; i++) {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
    }

    // Start countdown
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remaining.inSeconds > 0) {
        setState(() {
          remaining = remaining - Duration(seconds: 1);
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final days = d.inDays;
    final hours = twoDigits(d.inHours.remainder(24));
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    if (days > 0) {
      return "$days days $hours:$minutes:$seconds";
    }
    return "$hours:$minutes:$seconds";
  }

  String _formatMeetingTime(DateTime dateTime) {
    return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  void _onCodeChanged(int index, String value) {
    setState(() {
      transactionCode[index] = value;
    });
    
    // Check if all digits are filled
    bool allFilled = transactionCode.every((digit) => digit.isNotEmpty);
    setState(() {
      _isCodeValid = allFilled;
    });
    
    // Auto jump to next input field
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _verifyTransactionCode() async {
    String enteredCode = transactionCode.join('');
    
    if (enteredCode.length != 4) {
      _showErrorDialog('Please enter complete 4-digit transaction code');
      return;
    }
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Verifying transaction code...'),
          ],
        ),
      ),
    );
    
    try {
      // Get transaction ID
      String? transactionId = widget.transactionId;
      
      if (transactionId == null) {
        // Try to get from other sources
        final getTransactions = ServiceLocator().get<GetTransactions>();
        final transactions = await getTransactions.call(
          type: 'all',
          status: 'AGREED',
          page: 1,
          size: 10,
        );
        
        for (final transaction in transactions) {
          if (transaction['status'] == 'AGREED') {
            transactionId = transaction['id']?.toString();
            break;
          }
        }
      }
      
      if (transactionId == null) {
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog('Transaction ID not found. Please try refreshing the page.');
        return;
      }
      
      // Complete the transaction with the entered code
      await _completeTransaction(transactionId, enteredCode);
      
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog('Failed to verify transaction code: $e');
    }
  }

  // Complete transaction with verified code
  Future<void> _completeTransaction(String transactionId, String transactionCode) async {
    try {
      final completeTransaction = ServiceLocator().get<CompleteTransaction>();
      final result = await completeTransaction.call(
        transactionId: transactionId,
        transactionCode: transactionCode,
        feedback: 'Transaction completed successfully',
        rating: 5,
      );

      Navigator.pop(context); // Close loading dialog
      _showSuccessDialog();
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog('Failed to complete transaction: $e');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: 40,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Transaction code verified successfully!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Transaction completed, product status updated to sold',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to previous page
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF32C286),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Complete Transaction',
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
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Verification Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Top map area
          Container(
            height: _mapHeight,
            child: Stack(
              children: [
                Image.asset(
                  "assets/images/pickup_map.png",
                  width: double.infinity,
                  height: _mapHeight,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "${remaining.inHours} hours\nPickup Time",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Drag handle
          GestureDetector(
            onPanStart: (details) {
              setState(() {
                _isDragging = true;
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _mapHeight = (_mapHeight + details.delta.dy).clamp(_minMapHeight, _maxMapHeight);
              });
            },
            onPanEnd: (details) {
              setState(() {
                _isDragging = false;
              });
            },
            child: Container(
              width: double.infinity,
              height: 20,
              color: Colors.grey.shade100,
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _isDragging ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),

          // Bottom content area
          Expanded(
            child: Container(
              width: double.infinity,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Buyer information
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Buyer Information",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: widget.buyerAvatar != null 
                                    ? NetworkImage(widget.buyerAvatar!)
                                    : AssetImage("assets/images/buyer.png") as ImageProvider,
                                radius: 20,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.buyerName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      widget.buyerPhone,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "Buyer",
                                  style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1),

                    // Transaction details
                    Container(
                      padding: EdgeInsets.all(16),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Transaction Details",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 12),
                          _buildDetailRow("Product", widget.productName),
                          _buildDetailRow("Price", "\$${widget.productPrice}"),
                          _buildDetailRow("Meeting Time", _formatMeetingTime(widget.meetingTime)),
                          _buildDetailRow("Meeting Location", widget.meetingLocation),
                        ],
                      ),
                    ),
                    Divider(height: 1),

                    // Transaction code input
                    Container(
                      padding: EdgeInsets.all(16),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Enter Transaction Code",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 8),
                          Text("Please ask the buyer for the 4-digit transaction code and enter it",
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(4, (index) => 
                              Container(
                                width: 50,
                                height: 50,
                                child: TextField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  maxLength: 1,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Color(0xFF32C286)),
                                    ),
                                  ),
                                  onChanged: (value) => _onCodeChanged(index, value),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Transaction code is provided by buyer to confirm transaction completion",
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1                    ),

                    // Input field
                    Container(
                      padding: EdgeInsets.all(12),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: "Type a message...",
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          Icon(Icons.notifications_none, color: Colors.grey),
                          SizedBox(width: 12),
                          Icon(Icons.phone, color: Colors.grey),
                        ],
                      ),
                    ),

                    // Complete Transaction button
                    Container(
                      padding: EdgeInsets.all(16),
                      color: Colors.white,
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isCodeValid ? _verifyTransactionCode : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isCodeValid 
                                ? Color(0xFF32C286) 
                                : Colors.grey.shade300,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            "Complete Transaction",
                            style: TextStyle(
                              color: _isCodeValid ? Colors.white : Colors.grey.shade600, 
                              fontSize: 16
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
