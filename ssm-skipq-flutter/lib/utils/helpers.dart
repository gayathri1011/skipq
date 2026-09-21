import 'package:flutter/material.dart';
import '../models/order.dart';

class StudentAuthValidation {
  static String? nameError(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Name is required';
    if (trimmed.length < 2) return 'Name must be at least 2 characters';
    if (!RegExp(r'^[A-Za-z ]+$').hasMatch(trimmed)) {
      return 'Name must contain only letters and spaces';
    }
    return null;
  }

  static String? mobileError(String mobile) {
    final trimmed = mobile.trim();
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(trimmed)) {
      return 'Mobile must be 10 digits starting with 6, 7, 8, or 9';
    }
    return null;
  }
}

String timeGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

String formatIstDateTime(DateTime dt) {
  final local = dt.toLocal();
  return '${local.day}/${local.month}/${local.year} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

String formatIstTime(DateTime dt) {
  final local = dt.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

bool isTodayIst(DateTime dt) {
  final now = DateTime.now();
  return dt.year == now.year && dt.month == now.month && dt.day == now.day;
}

String? studentStatusToastTitle(OrderStatus status) {
  switch (status) {
    case OrderStatus.confirmed:
    case OrderStatus.preparing:
      return 'Order Accepted';
    case OrderStatus.ready:
      return 'Ready for Pickup';
    default:
      return null;
  }
}

IconData getCategoryIcon(String categoryName) {
  switch (categoryName) {
    case "All":
      return Icons.restaurant_menu;
    case "Rice Varieties":
      return Icons.rice_bowl;
    case "Parotta":
      return Icons.local_pizza;
    case "Fried Rice":
      return Icons.ramen_dining;
    case "Chapati":
      return Icons.bakery_dining;
    case "Side Dishes":
      return Icons.tapas;
    case "Gravies":
      return Icons.soup_kitchen;
    case "Puffs":
      return Icons.cookie;
    case "Snacks":
      return Icons.fastfood;
    case "Desserts":
      return Icons.cake;
    case "Noodles":
      return Icons.ramen_dining;
    default:
      return Icons.restaurant;
  }
}
