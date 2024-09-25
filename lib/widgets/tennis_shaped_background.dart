import 'package:flutter/material.dart';

class ShapedBackground extends StatelessWidget {
  final String name;
  final String photoUrl;

  const ShapedBackground({Key? key, required this.name, required this.photoUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomPaint(
            painter: _ShapedBackgroundPainter(),
            child: Container(),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 100.0), // Adjust the padding as needed
              child: Column(
                children: [
                  ClipOval(
                    child: Image.network(
                      photoUrl, // Use the passed photoUrl
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name, // Use the passed name
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShapedBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.deepOrangeAccent
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.4, size.width, size.height * 0)
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}