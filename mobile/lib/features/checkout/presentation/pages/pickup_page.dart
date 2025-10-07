import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'complete_page.dart';
import '../../../../injection.dart';
import '../../../transaction/domain/usecases/complete_transaction.dart';
import '../../../transaction/domain/usecases/get_transactions.dart';
import '../../../transaction/domain/usecases/get_transaction_detail.dart';
import '../../../transaction/domain/usecases/get_transaction_code.dart';

class PickupPage extends StatefulWidget {
  final String productName;
  final String productImage;
  final double productPrice;
  final String? transactionId;
  final String? transactionCode;
  final String? sellerName;
  final String? sellerAvatar;
  final String? sellerPhone;
  final String? buyerName;
  final String? buyerAvatar;
  final String? buyerPhone;
  final String? meetingLocation;
  final DateTime? meetingTime;
  final String? status;
  final bool? isSeller;

  const PickupPage({
    Key? key,
    required this.productName,
    required this.productImage,
    required this.productPrice,
    this.transactionId,
    this.transactionCode,
    this.sellerName,
    this.sellerAvatar,
    this.sellerPhone,
    this.buyerName,
    this.buyerAvatar,
    this.buyerPhone,
    this.meetingLocation,
    this.meetingTime,
    this.status,
    this.isSeller,
  }) : super(key: key);

  @override
  _PickupPageState createState() => _PickupPageState();
}

class _PickupPageState extends State<PickupPage> {
  late Timer _timer;
  Duration remaining = Duration(days: 7); // ✅ Default countdown from 7 days
  List<int> pin = [];
  
  // Drag related states
  double _mapHeight = 400.0; // Initial map height
  final double _minMapHeight = 200.0; // Minimum map height
  final double _maxMapHeight = 600.0; // Maximum map height
  bool _isDragging = false;

  // Transaction code input related
  final TextEditingController _transactionCodeController = TextEditingController();
  bool _isCompletingTransaction = false;

  @override
  void initState() {
    super.initState();

    // ✅ Start countdown
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remaining.inSeconds > 0) {
        setState(() {
          remaining = remaining - Duration(seconds: 1);
        });
      } else {
        timer.cancel();
      }
    });

    // ✅ Load transaction code from API
    _loadTransactionCode();
  }

  // Load transaction code from API
  Future<void> _loadTransactionCode() async {
    if (widget.transactionId == null) return;
    
    try {
      final getTransactionCode = ServiceLocator().get<GetTransactionCode>();
      final codeResponse = await getTransactionCode.call(
        transactionId: widget.transactionId!,
      );
      
      final transactionCode = codeResponse['transactionCode']?.toString();
      if (transactionCode != null && transactionCode.length == 4) {
        setState(() {
          pin = transactionCode.split('').map((e) => int.parse(e)).toList();
        });
      }
    } catch (e) {
      print('❌ Failed to load transaction code: $e');
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _transactionCodeController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final days = d.inDays;
    final hours = twoDigits(d.inHours.remainder(24));
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    if (days > 0) {
      return "$days d $hours:$minutes:$seconds";
    }
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight = screenHeight - MediaQuery.of(context).padding.top;
    
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
          // ✅ Top map area
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
                      "${remaining.inHours} hours\nCollect within",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ✅ Drag handle
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

          // ✅ Bottom content area
          Expanded(
            child: Container(
              width: double.infinity,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                  // ✅ Pick-up Details
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Pick-up details",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 8),
                        Text(widget.meetingLocation ?? "Unit 1-602, 18 Gadigal street, Rosebery, NSW, 2015",
                            style: TextStyle(fontSize: 14)),
                        // Display different user info based on role
                        if (widget.isSeller == true) ...[
                          // Seller perspective: show buyer info
                          Text("${widget.buyerName ?? 'Buyer'}  ·  ${widget.buyerPhone ?? 'NSW'}",
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade600)),
                        ] else ...[
                          // Buyer perspective: show seller info
                          Text("${widget.sellerName ?? 'Seller'}  ·  ${widget.sellerPhone ?? 'NSW'}",
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade600)),
                        ],
                        SizedBox(height: 12),

                        Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: widget.isSeller == true 
                                  ? (widget.buyerAvatar != null 
                                      ? NetworkImage(widget.buyerAvatar!)
                                      : AssetImage("assets/images/buyer.png") as ImageProvider)
                                  : (widget.sellerAvatar != null 
                                      ? NetworkImage(widget.sellerAvatar!)
                                      : AssetImage("assets/images/seller.png") as ImageProvider),
                              radius: 14,
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.star, color: Colors.amber, size: 18),
                            Text(" 5.0", style: TextStyle(fontSize: 14)),
                            Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _formatDuration(remaining),
                                style: TextStyle(
                                    color: Colors.red,
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

                  // ✅ Transaction Code Section
                  Container(
                    padding: EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.isSeller == true) ...[
                          // Seller: show transaction code input field
                          Text("Enter the transaction code provided by the buyer",
                              style: TextStyle(fontSize: 14)),
                          SizedBox(height: 12),
                          TextField(
                            controller: _transactionCodeController,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            decoration: InputDecoration(
                              hintText: "Enter 4-digit code",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              counterText: "",
                            ),
                          ),
                          SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isCompletingTransaction ? null : _completeTransaction,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF32C286),
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isCompletingTransaction
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'Complete Transaction',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ] else ...[
                          // Buyer: show transaction code
                          Text("Show this code to the seller to complete the transaction",
                              style: TextStyle(fontSize: 14)),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: pin
                                .map((digit) => Container(
                                      width: 60,
                                      height: 60,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Color(0xFF32C286).withOpacity(0.1),
                                        border: Border.all(color: Color(0xFF32C286)),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "$digit",
                                        style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF32C286)),
                                      ),
                                    ))
                                .toList(),
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Please provide this code to the seller during the transaction",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Divider(height: 1),

                  // ✅ Input field
                  Container(
                    padding: EdgeInsets.all(12),
                    color: Colors.white,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Type your message ...",
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

                  // ✅ Display different buttons based on user role
                  Container(
                    padding: EdgeInsets.all(16),
                    color: Colors.white,
                    child: _buildActionButtons(),
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

  // Complete transaction method
  Future<void> _completeTransaction() async {
    String? transactionId = widget.transactionId;
    
    // If no transactionId in widget, try to get from other sources
    if (transactionId == null) {
      print('⚠️ No transactionId in Pickup page, trying to get from other sources');
      
      try {
        // Query latest transaction records
        final getTransactions = ServiceLocator().get<GetTransactions>();
        final transactions = await getTransactions.call(
          type: 'all',
          status: 'AGREED',
          page: 1,
          size: 10,
        );
        
        // Find transactions related to current product
        for (final transaction in transactions) {
          if (transaction['status'] == 'AGREED') {
            transactionId = transaction['id']?.toString();
            print('✅ Found transactionId from transaction records: $transactionId');
            break;
          }
        }
      } catch (e) {
        print('❌ Failed to query transaction records: $e');
      }
    }
    
    if (transactionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaction ID not found. Please try refreshing the page.'),
          action: SnackBarAction(
            label: 'Refresh',
            onPressed: () {
              // Refresh page
              setState(() {});
            },
          ),
        ),
      );
      return;
    }

    final transactionCode = _transactionCodeController.text.trim();
    if (transactionCode.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a 4-digit transaction code')),
      );
      return;
    }

    setState(() {
      _isCompletingTransaction = true;
    });

    try {
      final completeTransaction = ServiceLocator().get<CompleteTransaction>();
      final result = await completeTransaction.call(
        transactionId: transactionId,
        transactionCode: transactionCode,
        feedback: 'Transaction completed successfully',
        rating: 5,
      );

      // Show success dialog
      _showTransactionCompleteDialog(result);
    } catch (e) {
      setState(() {
        _isCompletingTransaction = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete transaction: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show transaction complete dialog
  void _showTransactionCompleteDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                  Icons.check_circle_outline,
                  size: 40,
                  color: Color(0xFF32C286),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Transaction Completed!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'The transaction has been successfully completed. The product status has been updated to SOLD.',
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
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Return to previous page
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF32C286),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Done',
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

  // Build action buttons
  Widget _buildActionButtons() {
    if (widget.isSeller == true) {
      // Seller perspective: input transaction code to complete transaction
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: _isCompletingTransaction ? null : _completeTransaction,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF32C286),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: _isCompletingTransaction
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Complete Transaction',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
        ),
      );
    } else {
      // Buyer perspective: show transaction code
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () {
            _showTransactionCodeDialog();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF32C286),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Text(
            'Show Transaction Code',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }
  }

  // Show transaction code dialog
  void _showTransactionCodeDialog() {
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
                  Icons.qr_code,
                  size: 40,
                  color: Color(0xFF32C286),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Your Transaction Code',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Show this code to the seller:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Color(0xFF32C286).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFF32C286)),
                ),
                child: Text(
                  widget.transactionCode ?? '1234', // Should actually be obtained from API
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF32C286),
                    letterSpacing: 2,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
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
}
