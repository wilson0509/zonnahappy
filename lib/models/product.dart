class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final String description;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.description = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category': category,
      'description': description,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      category: map['category'],
      description: map['description'] ?? '',
    );
  }
}