import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sportify1/providers/user_provider.dart';
import 'package:sportify1/resources/firestore_methods.dart';
import 'package:sportify1/utils/colors.dart';
import 'package:sportify1/utils/utils.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  List<Uint8List>? _selectedFiles;
  bool isLoading = false;
  final TextEditingController _descriptionController = TextEditingController();

  Future<void> _selectImage(BuildContext parentContext) async {
    return showDialog(
      context: parentContext,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Create a Post'),
          children: <Widget>[
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text('Take a photo'),
              onPressed: () async {
                Navigator.pop(context);
                Uint8List file = await pickImage(ImageSource.camera); // Ensure this is ImageSource.camera
                setState(() {
                  _selectedFiles = [file];
                });
                            },
            ),
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text('Choose from Gallery'),
              onPressed: () async {
                Navigator.of(context).pop();
                List<Uint8List>? images = await pickImages(ImageSource.gallery);
                if (images != null && images.isNotEmpty) {
                  setState(() {
                    _selectedFiles = images;
                  });
                }
              },
            ),
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            )
          ],
        );
      },
    );
  }

  Future<void> postImage(String uid, String username, String profImage) async {
    setState(() {
      isLoading = true;
    });
    try {
      if (_selectedFiles != null && _selectedFiles!.isNotEmpty) {
        String res = await FireStoreMethods().uploadPost(
          _descriptionController.text,
          _selectedFiles!, // Pass the list of selected files
          uid,
          username,
          profImage,
        );

        if (res != "success") {
          if (context.mounted) {
            showSnackBar(context, res);
          }
        } else {
          setState(() {
            isLoading = false;
          });
          if (context.mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      }
    } catch (err) {
      setState(() {
        isLoading = false;
      });
      if (context.mounted) {
        showSnackBar(context, err.toString());
      }
    }
  }


  @override
  void dispose() {
    super.dispose();
    _descriptionController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.getUser;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.black,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Create Post',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: <Widget>[
            TextField(
              style: const TextStyle(color: Colors.black),
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: "Write a caption...",
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.black),
                ),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 20),
            if (_selectedFiles != null && _selectedFiles!.isNotEmpty)
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _selectedFiles!.length,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: MemoryImage(_selectedFiles![index]),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  },
                ),
              )
            else
              const Text('No image selected'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _selectImage(context),
              child: const Text(
                'Select Image',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _selectedFiles != null && _selectedFiles!.isNotEmpty
                  ? () => postImage(
                user.uid,
                user.username,
                user.photoUrl,
              )
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedFiles != null && _selectedFiles!.isNotEmpty
                    ? Colors.black
                    : Colors.grey,
              ),
              child: const Text(
                'Post',
                style: TextStyle(color: Colors.white),
              ),
            ),
            if (isLoading)
              const SizedBox(height: 20),
            if (isLoading)
              const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
