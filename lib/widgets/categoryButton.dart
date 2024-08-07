import 'package:flutter/material.dart';

class CategoryButton extends StatelessWidget {
  final String category;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color unselectedColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;

  const CategoryButton({
    required this.category,
    required this.isSelected,
    required this.onTap,
    this.selectedColor = Colors.deepOrangeAccent,
    this.unselectedColor = Colors.white,
    this.selectedTextColor = Colors.white,
    this.unselectedTextColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : unselectedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.orangeAccent,
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 0,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ] : [],
        ),
        child: Text(
          category,
          style: TextStyle(
            color: isSelected ? selectedTextColor : unselectedTextColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}