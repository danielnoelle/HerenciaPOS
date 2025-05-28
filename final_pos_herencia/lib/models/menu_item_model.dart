import 'dart:convert';

class MenuItemModel {
  String id;
  String name;
  double price;
  String? description;
  String categoryId;
  List<String> varieties;
  String? imageUrl;
  int stock;
  String? firebaseDocId;
  int lastUpdated;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    required this.categoryId,
    this.varieties = const [],
    this.imageUrl,
    required this.stock,
    this.firebaseDocId,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'category_id': categoryId, // Matches columnMenuCategoryId
      'varieties': jsonEncode(varieties), // Store as JSON string
      'image_url': imageUrl,     // Matches columnMenuImageUrl
      'stock': stock,            // Added stock field
      'firebase_doc_id': firebaseDocId,
      'last_updated': lastUpdated, // Matches columnMenuLastUpdated
    };
  }

  factory MenuItemModel.fromMap(Map<String, dynamic> map) {
    return MenuItemModel(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unnamed Item',
      price: (map['price'] is int ? (map['price'] as int).toDouble() : map['price'] as double?) ?? 0.0,
      description: map['description'] as String?,
      categoryId: map['categoryId'] ?? map['category_id'] ?? 'uncategorized',
      varieties: map['varieties'] is String 
          ? List<String>.from(jsonDecode(map['varieties'])) 
          : (map['varieties'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      imageUrl: map['imageUrl'] ?? map['image_url'],
      stock: (map['stock'] as int?) ?? 0,
      firebaseDocId: map['firebase_doc_id'] as String?,
      lastUpdated: (map['last_updated'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  MenuItemModel copyWith({
    String? id,
    String? name,
    double? price,
    String? description,
    String? categoryId,
    List<String>? varieties,
    String? imageUrl,
    int? stock,
    String? firebaseDocId,
    int? lastUpdated,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      varieties: varieties ?? this.varieties,
      imageUrl: imageUrl ?? this.imageUrl,
      stock: stock ?? this.stock,
      firebaseDocId: firebaseDocId ?? this.firebaseDocId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}