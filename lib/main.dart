import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'screens/products_page.dart';
import 'screens/orders_page.dart';
import 'screens/accounting_page.dart';

void main() {
  // Ensure Flutter is initialized before using any platform channels
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const RestaurantApp());
}

class RestaurantApp extends StatelessWidget {
  const RestaurantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurante App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
      routes: {
        '/products': (context) => const ProductsPage(),
        '/orders': (context) => const OrdersPage(),
        '/accounting': (context) => const AccountingPage(),
      },
    );
  }
}