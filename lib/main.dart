import 'package:flutter/material.dart';
import 'package:tech_product_searcher/screens/search_screen.dart';
import 'dart:core';

void main() {
  runApp(const ProductSearchApp());
}


class ProductSearchApp extends StatelessWidget {
  const ProductSearchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tech Hunt',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12)
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
      home: const SearchScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
