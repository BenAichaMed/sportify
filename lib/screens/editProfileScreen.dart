import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sportify1/resources/storage_methods.dart';

class EditProfileScreen extends StatefulWidget {
  final String uid;

  const EditProfileScreen({super.key, required this.uid});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  String email = '';
  String photoUrl = '';
  bool isLoading = false;
  Uint8List? _image;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  getUserData() async {
    setState(() {
      isLoading = true;
    });
    try {
      var userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      if (userSnap.exists) {
        var userData = userSnap.data()!;
        usernameController.text = userData['username'];
        bioController.text = userData['bio'];
        email = userData['email'];
        photoUrl = userData['photoUrl'];
      } else {
        showSnackBar(context, "User not found");
      }
    } catch (e) {
      showSnackBar(context, e.toString());
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _updateProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    // Convert the File to a Uint8List
    Uint8List imageBytes = await image.readAsBytes();

    try {
      // Upload image to Firebase storage
      String newPhotoUrl = await StorageMethods().uploadImageToStorage('profilePics', imageBytes, false);

      // Update user profile with new photo URL
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({'photoUrl': newPhotoUrl});

      // Update the state with the new photo URL
      setState(() {
        photoUrl = newPhotoUrl;
      });


    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  void _saveProfile() async {
    setState(() {
      isLoading = true;
    });
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
        'username': usernameController.text,
        'bio': bioController.text,
      });
      showSnackBar(context, "Profile updated successfully");
    } catch (e) {
      showSnackBar(context, e.toString());
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrangeAccent,
        title: const Text('Edit Profile'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Make sure to save your profile before quitting.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _image != null
                      ? MemoryImage(_image!)
                      : NetworkImage(photoUrl) as ImageProvider,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.grey),
                    onPressed: _updateProfilePicture,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _updateProfilePicture,
              child: const Text('Change Profile Photo'),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: email,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            enabled: false,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: bioController,
            decoration: const InputDecoration(
              labelText: 'Tell us about yourself',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveProfile,
            child: const Text('Save', style: TextStyle(color: Colors.white,fontSize: 20,fontWeight: FontWeight.normal)),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
              backgroundColor: Colors.deepOrange,
              padding: const EdgeInsets.all(15),
          ),
          ),
        ],
      ),
    );
  }

  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}