class SarprasRecord {
  final int id;
  final String itemName;
  final String category;
  final String itemCondition;
  final String location;
  final int quantity;

  const SarprasRecord({
    required this.id,
    required this.itemName,
    required this.category,
    required this.itemCondition,
    required this.location,
    required this.quantity,
  });

  factory SarprasRecord.fromJson(Map<String, dynamic> json) {
    return SarprasRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      itemName: '${json['item_name'] ?? json['itemName'] ?? ''}',
      category: '${json['category'] ?? ''}',
      itemCondition: '${json['item_condition'] ?? json['itemCondition'] ?? ''}',
      location: '${json['location'] ?? ''}',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_name': itemName,
      'category': category,
      'item_condition': itemCondition,
      'location': location,
      'quantity': quantity,
    };
  }

  SarprasRecord copyWith({
    int? id,
    String? itemName,
    String? category,
    String? itemCondition,
    String? location,
    int? quantity,
  }) {
    return SarprasRecord(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      itemCondition: itemCondition ?? this.itemCondition,
      location: location ?? this.location,
      quantity: quantity ?? this.quantity,
    );
  }
}
