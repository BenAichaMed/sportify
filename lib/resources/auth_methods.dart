import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sportify1/models/user.dart' as model;
import 'package:sportify1/resources/storage_methods.dart';

import '../utils/global_variable.dart';

class AuthMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user details
  Future<model.User> getUserDetails() async {
    User currentUser = _auth.currentUser!;

    DocumentSnapshot documentSnapshot =
    await _firestore.collection('users').doc(currentUser.uid).get();

    if (!documentSnapshot.exists) {
      throw Exception("User not found");
    }

    return model.User.fromSnap(documentSnapshot);
  }

  // Signing Up User
  Future<String> signUpUser({
    required String email,
    required String password,
    required String username,
    required String bio,
    required Uint8List file,
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty && username.isNotEmpty && bio.isNotEmpty && file.isNotEmpty) {
        // Registering user in auth with email and password
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        String photoUrl = await StorageMethods().uploadImageToStorage('profilePics', file, false);

        model.User user = model.User(
          username: username,
          uid: cred.user!.uid,
          photoUrl: photoUrl,
          email: email,
          bio: bio,
          followers: [],
          following: [],
        );

        // Adding user to the database
        await _firestore.collection("users").doc(cred.user!.uid).set(user.toJson());

        res = "success";
      } else {
        res = "Please enter all the fields";
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        res = 'The email address is already in use by another account.';
      } else if (e.code == 'weak-password') {
        res = 'The password provided is too weak.';
      } else {
        res = e.message ?? "An unknown error occurred";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Logging in user
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        // Logging in user with email and password
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        res = "success";

      } else {
        res = "Please enter all the fields";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }
  Future<String> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();

      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        final UserCredential authResult = await _auth.signInWithCredential(credential);
        final User? user = authResult.user;

        if (user != null) {
          // Check if user already exists in Firestore
          final DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
          if (!userDoc.exists) {
            // User doesn't exist, so create a new user in Firestore
            await _firestore.collection("users").doc(user.uid).set({
              'uid': user.uid,
              'email': user.email,
              'username': user.displayName,
              'photoUrl': user.photoURL,
              // Add other fields as necessary
            });
          }
        }
      }
      return "success";
    }

    catch (e) {
      return e.toString();
    }

  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
