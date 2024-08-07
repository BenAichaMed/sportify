import 'package:flutter/material.dart';
import 'package:sportify1/utils/colors.dart';

Widget authBackground() {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: authBackgroundColor, // Assuming authBackgroundColor is accessible here
      ),
    ),
  );
}