import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/product.dart';
import '../models/order.dart';
import 'dart:convert';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    // Make sure sqflite is properly initialized
    WidgetsFlutterBinding.ensureInitialized();
    
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'restaurant_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        category TEXT NOT NULL,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        customer_name TEXT NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        items TEXT NOT NULL
      )
    ''');
  }

  // Métodos para Productos
  Future<List<Product>> getProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) {
      return Product(
        id: maps[i]['id'],
        name: maps[i]['name'],
        price: maps[i]['price'],
        category: maps[i]['category'],
        description: maps[i]['description'] ?? '',
      );
    });
  }

  Future<void> addProduct(Product product) async {
    final db = await database;
    await db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> deleteProduct(String productId) async {
    final db = await database;
    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  // Métodos para Pedidos
  Future<List<Order>> getOrders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('orders');
    return _parseOrders(maps);
  }

  Future<List<Order>> getOrdersByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startStr, endStr],
    );
    
    return _parseOrders(maps);
  }

  List<Order> _parseOrders(List<Map<String, dynamic>> maps) {
    return List.generate(maps.length, (i) {
      final itemsJson = jsonDecode(maps[i]['items']) as List;
      final items = itemsJson.map((itemMap) {
        final product = Product(
          id: itemMap['productId'],
          name: itemMap['productName'],
          price: itemMap['price'],
          category: '',
        );
        return OrderItem(
          product: product,
          quantity: itemMap['quantity'],
        );
      }).toList();

      return Order(
        id: maps[i]['id'],
        customerName: maps[i]['customer_name'],
        items: items,
        date: DateTime.parse(maps[i]['date']),
        status: maps[i]['status'],
      );
    });
  }

  Future<void> addOrder(Order order) async {
    final db = await database;
    final orderMap = {
      'id': order.id,
      'customer_name': order.customerName,
      'date': order.date.toIso8601String(),
      'status': order.status,
      'items': jsonEncode(order.items.map((item) => item.toMap()).toList()),
    };
    await db.insert(
      'orders',
      orderMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateOrder(Order order) async {
    final db = await database;
    final orderMap = {
      'id': order.id,
      'customer_name': order.customerName,
      'date': order.date.toIso8601String(),
      'status': order.status,
      'items': jsonEncode(order.items.map((item) => item.toMap()).toList()),
    };
    await db.update(
      'orders',
      orderMap,
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  Future<void> deleteOrder(String orderId) async {
    final db = await database;
    await db.delete(
      'orders',
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }
}