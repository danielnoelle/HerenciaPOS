import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'transaction_detail_screen.dart';

class MenuItem {
  final String id;
  final String name;
  final double price;
  final String imageUrl;

  const MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
  });
}

class OrderItem {
  final MenuItem menuItem;
  int quantity;
  String? selectedVariety;
  String? notes;

  OrderItem({
    required this.menuItem,
    this.quantity = 1,
    this.selectedVariety,
    this.notes,
  });

  double get totalPrice => menuItem.price * quantity;
}

class Transaction {
  final String id;
  final DateTime date;
  final List<OrderItem> items;
  final double totalAmount;
  final String orderType;

  const Transaction({
    required this.id,
    required this.date,
    required this.items,
    required this.totalAmount,
    required this.orderType,
  });
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  static void addTransactionEntry(Transaction transaction) {
    _HistoryScreenState._transactions.insert(0, transaction);
  }

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static final List<Transaction> _transactions = [];
  String _currentSortOrder = 'date_desc';

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        toolbarHeight: 90.0,
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Transaction History',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 22.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            iconSize: 28.0,
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, size: 28.0),
            tooltip: 'Sort History',
            onSelected: (String value) {
              setState(() {
                _currentSortOrder = value;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'date_desc', child: Text('Time (Newest First)')),
              const PopupMenuItem<String>(value: 'date_asc', child: Text('Time (Oldest First)')),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(value: 'id_asc', child: Text('ID (Ascending)')),
              const PopupMenuItem<String>(value: 'id_desc', child: Text('ID (Descending)')),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(value: 'type_asc', child: Text('Order Type (A-Z)')),
              const PopupMenuItem<String>(value: 'type_desc', child: Text('Order Type (Z-A)')),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(value: 'price_desc', child: Text('Price (High to Low)')),
              const PopupMenuItem<String>(value: 'price_asc', child: Text('Price (Low to High)')),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _transactions.isEmpty
          ? _buildEmptyState()
          : _buildTransactionList(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'No Transactions Yet',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          SizedBox(height: 10),
          Text(
            'Completed orders will appear here.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    List<Transaction> sortedTransactions = List.from(_transactions);
    switch (_currentSortOrder) {
      case 'date_desc':
        sortedTransactions.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'date_asc':
        sortedTransactions.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'id_asc':
        sortedTransactions.sort((a, b) => a.id.compareTo(b.id));
        break;
      case 'id_desc':
        sortedTransactions.sort((a, b) => b.id.compareTo(a.id));
        break;
      case 'type_asc':
        sortedTransactions.sort((a, b) => a.orderType.toLowerCase().compareTo(b.orderType.toLowerCase()));
        break;
      case 'type_desc':
        sortedTransactions.sort((a, b) => b.orderType.toLowerCase().compareTo(a.orderType.toLowerCase()));
        break;
      case 'price_desc':
        sortedTransactions.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        break;
      case 'price_asc':
        sortedTransactions.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
        break;
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: sortedTransactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final transaction = sortedTransactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final DateFormat dateFormat = DateFormat('MMM d, yyyy \'at\' h:mm a');

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailScreen(transaction: transaction),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order ID: ${transaction.id}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: transaction.orderType == 'Dine In' ? Colors.blue.shade100 : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      transaction.orderType,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: transaction.orderType == 'Dine In' ? Colors.blue.shade800 : Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                dateFormat.format(transaction.date),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              Text(
                'Items (${transaction.items.length}):',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              ...transaction.items.map((orderItem) => Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${orderItem.quantity}x ${orderItem.menuItem.name}${orderItem.selectedVariety != null ? " (${orderItem.selectedVariety})" : ""}',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '₱${(orderItem.menuItem.price * orderItem.quantity).toStringAsFixed(2)}', // Price for this line item
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                        ),
                      ],
                    ),
                  )),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Total: ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '₱${transaction.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange.shade700),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}