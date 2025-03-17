import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';


class AccountingPage extends StatefulWidget {
  const AccountingPage({super.key});

  @override
  State<AccountingPage> createState() => _AccountingPageState();
}

class _AccountingPageState extends State<AccountingPage> {
  final DatabaseService _databaseService = DatabaseService();
  List<Order> orders = [];
  bool isLoading = true;
  
  // Filtros de fecha
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    // Inicializar fechas al mes actual
    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, 1);
    endDate = DateTime(now.year, now.month + 1, 0);
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final loadedOrders = await _databaseService.getOrdersByDateRange(startDate!, endDate!);
      setState(() {
        orders = loadedOrders;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    }
  }

  double get totalSales => orders.fold(0, (sum, order) => sum + order.total);
  
  int get totalOrders => orders.length;
  
  double get averageOrderValue => totalOrders > 0 ? totalSales / totalOrders : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contabilidad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showDateRangeFilter,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Período: ${_formatDate(startDate!)} - ${_formatDate(endDate!)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          _buildSummaryTile(
                            'Ventas Totales',
                            '\$${totalSales.toStringAsFixed(2)}',
                            Icons.attach_money,
                          ),
                          const Divider(),
                          _buildSummaryTile(
                            'Número de Pedidos',
                            totalOrders.toString(),
                            Icons.receipt_long,
                          ),
                          const Divider(),
                          _buildSummaryTile(
                            'Valor Promedio por Pedido',
                            '\$${averageOrderValue.toStringAsFixed(2)}',
                            Icons.analytics,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Desglose de Pedidos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  orders.isEmpty
                      ? const Center(
                          child: Text('No hay pedidos en este período'),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text('Pedido de ${order.customerName}'),
                                subtitle: Text(
                                  'Fecha: ${_formatDateTime(order.date)} - ${order.status}',
                                ),
                                trailing: Text(
                                  '\$${order.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),onTap: () {
                                  _showOrderDetails(order);
                                },
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryTile(String title, String value, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 40, color: Theme.of(context).primaryColor),
      title: Text(title),
      trailing: Text(
        value,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  void _showDateRangeFilter() async {
    final initialDateRange = DateTimeRange(
      start: startDate!,
      end: endDate!,
    );

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != initialDateRange) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      _loadOrders();
    }
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
              Text('Fecha: ${_formatDateTime(order.date)}'),
              Text('Estado: ${order.status}'),
              const Divider(),
              ...order.items.map((item) => ListTile(
                    dense: true,
                    title: Text(item.product.name),
                    subtitle: Text('Cantidad: ${item.quantity}'),
                    trailing: Text('\$${item.total.toStringAsFixed(2)}'),
                  )),
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
        ],
      ),
    );
  }
}