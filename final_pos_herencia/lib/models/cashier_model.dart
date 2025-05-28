class CashierModel {
  String id;
  String? name;
  String? imageUrl;


  CashierModel({
    required this.id,
    this.name,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,   
      'name': name,
      'image_url': imageUrl,
    };
  }

  factory CashierModel.fromMap(Map<String, dynamic> map) {
    return CashierModel(
      id: map['id'],
      name: map['name'],
      imageUrl: map['image_url'],
    );
  }

  CashierModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
  }) {
    return CashierModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
} 