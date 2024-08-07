import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// for picking up image from gallery
import 'package:image_picker/image_picker.dart';

Future<List<Uint8List>?> pickImages(ImageSource source) async {
  final ImagePicker imagePicker = ImagePicker();
  try {
    List<XFile>? files = await imagePicker.pickMultiImage();
    if (files != null && files.isNotEmpty) {
      // Returning bytes of all selected images
      return Future.wait(files.map((file) => file.readAsBytes()));
    }
  } catch (e) {
    // Handle any errors that occur
    print("Error picking images: $e");
  }
  return null;
}



// for picking up image from gallery
pickImage(ImageSource source) async {
  final ImagePicker imagePicker = ImagePicker();
  List<XFile>? files = await imagePicker.pickMultiImage();
  if (files != null && files.isNotEmpty) {
    // Assuming you want to return the first file's bytes for compatibility with existing code
    // Adjust based on your actual requirements
    return await files.first.readAsBytes();
  }
}



// for displaying snackbars
showSnackBar(BuildContext context, String text) {
  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
    ),
  );
}

