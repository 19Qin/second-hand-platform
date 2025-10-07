import 'package:flutter/material.dart';
import 'transaction_status_page.dart';
import '../../../checkout/presentation/pages/seller_pickup_page.dart';

class TransactionFlowDemoPage extends StatelessWidget {
  const TransactionFlowDemoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction Flow Demo'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Transaction Flow Demo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Complete transaction flow: Inquiry → Agree → Pickup → Complete',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 32),
            _buildFlowStep(
              context,
              step: 1,
              title: 'Inquiry Stage',
              description: 'Buyer sends purchase inquiry, seller receives notification',
              status: 'INQUIRY',
              onTap: () => _navigateToStatus(context, 'INQUIRY', false),
            ),
            SizedBox(height: 16),
            _buildFlowStep(
              context,
              step: 2,
              title: 'Agree Transaction',
              description: 'Seller agrees to transaction, buyer can start pickup',
              status: 'AGREED',
              onTap: () => _navigateToStatus(context, 'AGREED', false),
            ),
            SizedBox(height: 16),
            _buildFlowStep(
              context,
              step: 3,
              title: 'Seller Perspective',
              description: 'Seller enters transaction verification page',
              status: 'AGREED',
              isSeller: true,
              onTap: () => _navigateToSellerPickup(context),
            ),
            SizedBox(height: 16),
            _buildFlowStep(
              context,
              step: 4,
              title: 'Transaction Completed',
              description: 'Both parties confirm transaction, status updated to completed',
              status: 'COMPLETED',
              onTap: () => _navigateToStatus(context, 'COMPLETED', false),
            ),
            SizedBox(height: 32),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      SizedBox(width: 8),
                      Text(
                        'Process Description',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Buyer sends purchase inquiry\n'
                    '2. Seller agrees to transaction in chat\n'
                    '3. Buyer enters pickup page (gets transaction code)\n'
                    '4. Seller enters verification page (inputs transaction code)\n'
                    '5. Both parties confirm and transaction completes',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowStep(
    BuildContext context, {
    required int step,
    required String title,
    required String description,
    required String status,
    bool isSeller = false,
    required VoidCallback onTap,
  }) {
    Color statusColor = _getStatusColor(status);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    step.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            _getStatusText(status),
                            style: TextStyle(
                              fontSize: 10,
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isSeller) ...[
                          SizedBox(width: 4),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Seller',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'INQUIRY':
        return Colors.orange;
      case 'AGREED':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'INQUIRY':
        return 'Inquiry';
      case 'AGREED':
        return 'Agreed';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  void _navigateToStatus(BuildContext context, String status, bool isSeller) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionStatusPage(
          transactionId: 'demo_tx_123',
          productName: 'iPhone 12 Pro Max',
          productImage: 'assets/images/ps5.png',
          productPrice: 5999.0,
          sellerName: 'John',
          sellerPhone: '13800138000',
          buyerName: 'Jane',
          buyerPhone: '13900139000',
          meetingLocation: 'Sanlitun Taikoo Li',
          meetingTime: DateTime.now().add(Duration(hours: 2)),
          status: status,
          isSeller: isSeller,
        ),
      ),
    );
  }

  void _navigateToSellerPickup(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellerPickupPage(
          productName: 'iPhone 12 Pro Max',
          productImage: 'assets/images/ps5.png',
          productPrice: 5999.0,
          buyerName: 'Jane',
          buyerPhone: '13900139000',
          meetingLocation: 'Sanlitun Taikoo Li',
          meetingTime: DateTime.now().add(Duration(hours: 2)),
        ),
      ),
    );
  }
}
