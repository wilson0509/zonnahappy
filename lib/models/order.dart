import 'product.dart';

class OrderItem {
  final Product product;
  int quantity;

  OrderItem({
    required this.product,
    this.quantity = 1,
  });

  double get total => product.price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': product.id,
      'productName': product.name,
      'price': product.price,
      'quantity': quantity,
      'total': total,
    };
  }
}

class Order {
  final String id;
  final String customerName;
  final List<OrderItem> items;
  final DateTime date;
  String status;

  Order({
    required this.id,
    required this.customerName,
    required this.items,
    required this.date,
    this.status = 'Pendiente',
  });

  double get total => items.fold(0, (sum, item) => sum + item.total);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'items': items.map((item) => item.toMap()).toList(),
      'date': date.toIso8601String(),
      'status': status,
      'total': total,
    };
  }
}