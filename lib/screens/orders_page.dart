import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../services/database_service.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final DatabaseService _databaseService = DatabaseService();
  List<Order> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final loadedOrders = await _databaseService.getOrders();
      setState(() {
        orders = loadedOrders;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar pedidos: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(child: Text('No hay pedidos registrados'))
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return ListTile(
                      title: Text('Pedido de ${order.customerName}'),
                      subtitle: Text('Total: \$${order.total.toStringAsFixed(2)}'),
                      trailing: Text(order.status),
                      onTap: () {
                        _showOrderDetails(order);
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _createNewOrder();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showOrderDetails(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pedido de ${order.customerName}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text('Fecha: ${order.date.toString().substring(0, 16)}'),
              Text('Estado: ${order.status}'),
              const Divider(),
              // Usamos spread operator con una lista vacía si items es null
              ...(order.items.map((item) => ListTile(
                    dense: true,
                    title: Text(item.product.name),
                    subtitle: Text('Cantidad: ${item.quantity}'),
                    trailing: Text('\$${item.total.toStringAsFixed(2)}'),
                  )).toList()),
              const Divider(),
              Text(
                'Total: \$${order.total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _changeOrderStatus(order);
            },
            child: const Text('Cambiar Estado'),
          ),
        ],
      ),
    );
  }

  void _changeOrderStatus(Order order) {
    final statusOptions = ['Pendiente', 'En preparación', 'Listo', 'Entregado', 'Cancelado'];
    String newStatus = order.status;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Estado del Pedido'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return DropdownButton<String>(
              value: newStatus,
              isExpanded: true,
              items: statusOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    newStatus = value;
                  });
                }
              },
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final updatedOrder = Order(
                  id: order.id,
                  customerName: order.customerName,
                  items: order.items,
                  date: order.date,
                  status: newStatus,
                );
                await _databaseService.updateOrder(updatedOrder);
                await _loadOrders();
                Navigator.of(context).pop();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al actualizar estado: $e')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _createNewOrder() async {
    final customerNameController = TextEditingController();
    List<Product> products = [];
    List<OrderItem> orderItems = [];
    
    try {
      products = await _databaseService.getProducts();
      
      if (products.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay productos disponibles para crear un pedido'),
          ),
        );
        return;
      }
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nuevo Pedido'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: customerNameController,
                      decoration: const InputDecoration(labelText: 'Nombre del Cliente'),
                    ),
                    const SizedBox(height: 20),
                    const Text('Productos:'),
                    // Usamos map con una lista no nula garantizada
                    ...products.map((product) {
                      final orderItem = orderItems.firstWhere(
                        (item) => item.product.id == product.id,
                        orElse: () => OrderItem(product: product, quantity: 0),
                      );
                      
                      return ListTile(
                        title: Text(product.name),
                        subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
                        trailing: SizedBox(
                          width: 100,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: orderItem.quantity > 0
                                    ? () {
                                        setState(() {
                                          final index = orderItems.indexWhere(
                                            (item) => item.product.id == product.id,
                                          );
                                          if (index != -1) {
                                            orderItems[index].quantity--;
                                            if (orderItems[index].quantity == 0) {
                                              orderItems.removeAt(index);
                                            }
                                          }
                                        });
                                      }
                                    : null,
                              ),
                              Text('${orderItem.quantity}'),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  setState(() {
                                    final index = orderItems.indexWhere(
                                      (item) => item.product.id == product.id,
                                    );
                                    if (index != -1) {
                                      orderItems[index].quantity++;
                                    } else {
                                      orderItems.add(OrderItem(
                                        product: product,
                                        quantity: 1,
                                      ));
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 20),
                    Text(
                      'Total: \$${_calculateTotal(orderItems).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                if (customerNameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor, ingresa el nombre del cliente'),
                    ),
                  );
                  return;
                }

                if (orderItems.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor, selecciona al menos un producto'),
                    ),
                  );
                  return;
                }

                final newOrder = Order(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  customerName: customerNameController.text,
                  items: orderItems,
                  date: DateTime.now(),
                  status: 'Pendiente',
                );

                try {
                  await _databaseService.addOrder(newOrder);
                  await _loadOrders();
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al crear pedido: $e')),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar productos: $e')),
      );
    }
  }
  
  // Método auxiliar para calcular el total
  double _calculateTotal(List<OrderItem> items) {
    double total = 0;
    for (var item in items) {
      total += item.total;
    }
    return total;
  }
}