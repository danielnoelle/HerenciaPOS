import 'dart:convert';

class SaleOrderItem {
  String menuItemId;
  String name;
  double priceAtSale;
  int quantity;
  String? selectedVariety;
  String? notes;

  SaleOrderItem({
    required this.menuItemId,
    required this.name,
    required this.priceAtSale,
    required this.quantity,
    this.selectedVariety,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'priceAtSale': priceAtSale,
      'quantity': quantity,
      'selectedVariety': selectedVariety,
      'notes': notes,
    };
  }

  factory SaleOrderItem.fromMap(Map<String, dynamic> map) {
    return SaleOrderItem(
      menuItemId: map['menuItemId'],
      name: map['name'],
      priceAtSale: map['priceAtSale'],
      quantity: map['quantity'],
      selectedVariety: map['selectedVariety'],
      notes: map['notes'],
    );
  }
}

class SaleModel {
  int? id;
  String? firebaseDocId;
  List<SaleOrderItem> items;
  double totalAmount;
  int saleTimestamp;
  String cashierId;
  bool isSynced;
  String orderType;

  SaleModel({
    this.id,
    this.firebaseDocId,
    required this.items,
    required this.totalAmount,
    required this.saleTimestamp,
    required this.cashierId,
    this.isSynced = false,
    required this.orderType,
  });

  SaleModel copyWith({
    int? id,
    String? firebaseDocId,
    List<SaleOrderItem>? items,
    double? totalAmount,
    int? saleTimestamp,
    String? cashierId,
    bool? isSynced,
    String? orderType,
  }) {
    return SaleModel(
      id: id ?? this.id,
      firebaseDocId: firebaseDocId ?? this.firebaseDocId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      saleTimestamp: saleTimestamp ?? this.saleTimestamp,
      cashierId: cashierId ?? this.cashierId,
      isSynced: isSynced ?? this.isSynced,
      orderType: orderType ?? this.orderType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firebase_doc_id': firebaseDocId,
      'items_json': jsonEncode(items.map((item) => item.toMap()).toList()),
      'total_amount': totalAmount,
      'sale_timestamp': saleTimestamp,
      'cashier_id': cashierId,
      'is_synced': isSynced ? 1 : 0,
      'order_type': orderType,
    };
  }

  factory SaleModel.fromMap(Map<String, dynamic> map) {
    return SaleModel(
      id: map['id'],
      firebaseDocId: map['firebase_doc_id'],
      items: (jsonDecode(map['items_json'] as String) as List)
          .map((itemMap) => SaleOrderItem.fromMap(itemMap as Map<String, dynamic>))
          .toList(),
      totalAmount: map['total_amount'],
      saleTimestamp: map['sale_timestamp'],
      cashierId: map['cashier_id'],
      isSynced: map['is_synced'] == 1,
      orderType: map['order_type'] ?? 'Dine In',
    );
  }
} 