import 'package:flutter/material.dart';
import '../../../checkout/presentation/pages/pickup_page.dart';
import '../../../checkout/presentation/pages/seller_pickup_page.dart';

class TransactionStatusPage extends StatefulWidget {
  final String transactionId;
  final String productName;
  final String productImage;
  final double productPrice;
  final String sellerName;
  final String sellerPhone;
  final String buyerName;
  final String buyerPhone;
  final String meetingLocation;
  final DateTime meetingTime;
  final String status; // PENDING, AGREED, COMPLETED, REJECTED, CANCELLED, EXPIRED
  final bool isSeller; // Whether it is seller perspective

  const TransactionStatusPage({
    Key? key,
    required this.transactionId,
    required this.productName,
    required this.productImage,
    required this.productPrice,
    required this.sellerName,
    required this.sellerPhone,
    required this.buyerName,
    required this.buyerPhone,
    required this.meetingLocation,
    required this.meetingTime,
    required this.status,
    required this.isSeller,
  }) : super(key: key);

  @override
  _TransactionStatusPageState createState() => _TransactionStatusPageState();
}

class _TransactionStatusPageState extends State<TransactionStatusPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction Status'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Transaction status card
            _buildStatusCard(),
            
            // Transaction details
            _buildTransactionDetails(),
            
            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStatusIcon(),
          SizedBox(height: 16),
          Text(
            _getStatusTitle(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _getStatusDescription(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    Color color;
    IconData icon;
    
    switch (widget.status) {
      case 'INQUIRY':
        color = Colors.orange;
        icon = Icons.help_outline;
        break;
      case 'AGREED':
        color = Colors.blue;
        icon = Icons.check_circle_outline;
        break;
      case 'COMPLETED':
        color = Colors.green;
        icon = Icons.done_all;
        break;
      case 'CANCELLED':
        color = Colors.red;
        icon = Icons.cancel_outlined;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info_outline;
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 40,
        color: color,
      ),
    );
  }

  Widget _buildTransactionDetails() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaction Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          _buildDetailRow('Product', widget.productName),
          _buildDetailRow('Price', '\$${widget.productPrice}'),
          _buildDetailRow('Meeting Time', _formatMeetingTime(widget.meetingTime)),
          _buildDetailRow('Meeting Location', widget.meetingLocation),
          _buildDetailRow(
            widget.isSeller ? 'Buyer' : 'Seller',
            widget.isSeller ? widget.buyerName : widget.sellerName,
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

  Widget _buildActionButtons() {
    if (widget.status == 'AGREED') {
      return Container(
        margin: EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _navigateToPickup,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF32C286),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(
              widget.isSeller ? 'Start Transaction Verification' : 'Start Pickup',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    } else if (widget.status == 'INQUIRY') {
      return Container(
        margin: EdgeInsets.all(16),
        child: Text(
          'Waiting for response...',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      return Container(
        margin: EdgeInsets.all(16),
        child: Text(
          _getCompletedMessage(),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
  }

  void _navigateToPickup() {
    if (widget.isSeller) {
      // Seller enters seller pickup page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SellerPickupPage(
            productName: widget.productName,
            productImage: widget.productImage,
            productPrice: widget.productPrice,
            buyerName: widget.buyerName,
            buyerAvatar: null, // TODO: 从实际数据获取买家头像
            buyerPhone: widget.buyerPhone,
            meetingLocation: widget.meetingLocation,
            meetingTime: widget.meetingTime,
          ),
        ),
      );
    } else {
      // Buyer enters buyer pickup page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PickupPage(
            productName: widget.productName,
            productImage: widget.productImage,
            productPrice: widget.productPrice,
            transactionId: widget.transactionId,
            sellerName: widget.sellerName,
            sellerAvatar: null, // TODO: 从实际数据获取卖家头像
            sellerPhone: widget.sellerPhone,
            buyerName: widget.buyerName,
            buyerAvatar: null, // TODO: 从实际数据获取买家头像
            buyerPhone: widget.buyerPhone,
            meetingLocation: widget.meetingLocation,
            meetingTime: widget.meetingTime,
            status: widget.status,
            isSeller: false,
          ),
        ),
      );
    }
  }

  String _getStatusTitle() {
    switch (widget.status) {
      case 'PENDING':
        return 'Pending Response';
      case 'AGREED':
        return 'Transaction Agreed';
      case 'COMPLETED':
        return 'Transaction Completed';
      case 'REJECTED':
        return 'Transaction Rejected';
      case 'CANCELLED':
        return 'Transaction Cancelled';
      case 'EXPIRED':
        return 'Transaction Expired';
      default:
        return 'Unknown Status';
    }
  }

  String _getStatusDescription() {
    switch (widget.status) {
      case 'PENDING':
        return 'Waiting for response to your transaction request';
      case 'AGREED':
        return 'Both parties have agreed to the transaction, you can now start the pickup process';
      case 'COMPLETED':
        return 'Transaction completed successfully';
      case 'REJECTED':
        return 'Transaction request has been rejected';
      case 'CANCELLED':
        return 'Transaction has been cancelled';
      case 'EXPIRED':
        return 'Transaction has expired';
      default:
        return 'Unknown status';
    }
  }

  String _getCompletedMessage() {
    if (widget.status == 'COMPLETED') {
      return 'Transaction completed successfully!';
    } else if (widget.status == 'CANCELLED') {
      return 'Transaction has been cancelled';
    } else if (widget.status == 'REJECTED') {
      return 'Transaction request has been rejected';
    } else if (widget.status == 'EXPIRED') {
      return 'Transaction has expired';
    }
    return '';
  }

  String _formatMeetingTime(DateTime dateTime) {
    return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }
}
