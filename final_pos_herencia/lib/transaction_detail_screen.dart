import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'history_screen.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('MMM d, yyyy \'at\' h:mm a');
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90.0,
        title: const Text(
          'Transaction Details',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 22.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, size: 28.0),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildDetailRow('Transaction ID:', transaction.id, context),
                const SizedBox(height: 12),
                _buildDetailRow('Date:', dateFormat.format(transaction.date), context),
                const SizedBox(height: 12),
                _buildDetailRow('Order Type:', transaction.orderType, context),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  'Items Ordered (${transaction.items.length}):',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transaction.items.length,
                  itemBuilder: (context, index) {
                    final orderItem = transaction.items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  '${orderItem.quantity}x ${orderItem.menuItem.name}${orderItem.selectedVariety != null ? " (${orderItem.selectedVariety})" : ""}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  currencyFormat.format(orderItem.menuItem.price * orderItem.quantity),
                                  textAlign: TextAlign.right,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                          if (orderItem.notes != null && orderItem.notes!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                'Note: ${orderItem.notes}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey.shade700),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 20),
                _buildTotalRow('Subtotal:', _calculateSubtotal(transaction.items, currencyFormat), context, isBold: false),
                _buildTotalRow('Tax (10%):', _calculateTax(transaction.items, currencyFormat), context, isBold: false),
                const SizedBox(height: 8),
                _buildTotalRow('Total Amount:', currencyFormat.format(transaction.totalAmount), context, isBold: true, fontSize: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ],
    );
  }

  String _calculateSubtotal(List<OrderItem> items, NumberFormat format) {
    double subtotal = items.fold(0, (sum, item) => sum + (item.menuItem.price * item.quantity));
    return format.format(subtotal);
  }

  String _calculateTax(List<OrderItem> items, NumberFormat format) {
    double subtotal = items.fold(0, (sum, item) => sum + (item.menuItem.price * item.quantity));
    double tax = subtotal * 0.10;
    return format.format(tax);
  }

  Widget _buildTotalRow(String label, String amount, BuildContext context, {bool isBold = false, double fontSize = 16.0}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: fontSize,
                ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: fontSize,
                  color: isBold ? Theme.of(context).colorScheme.primary : null,
                ),
          ),
        ],
      ),
    );
  }
} 