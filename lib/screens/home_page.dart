import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurante App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Sistema de gestión de restaurante',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            _buildMenuButton(
              context,
              'Productos',
              Icons.fastfood,
              () => Navigator.pushNamed(context, '/products'),
            ),
            const SizedBox(height: 20),
            _buildMenuButton(
              context,
              'Pedidos',
              Icons.receipt,
              () => Navigator.pushNamed(context, '/orders'),
            ),
            const SizedBox(height: 20),
            _buildMenuButton(
              context,
              'Contabilidad',
              Icons.account_balance,
              () => Navigator.pushNamed(context, '/accounting'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
      BuildContext context, String title, IconData icon, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}