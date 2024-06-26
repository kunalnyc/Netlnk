import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../Authentication/Controller/auth_controller.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart'; // For generating unique filenames

class AddProfileScreen extends StatefulWidget {
  @override
  _AddProfileScreenState createState() => _AddProfileScreenState();
}

class _AddProfileScreenState extends State<AddProfileScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _usernameController = TextEditingController();
  File? _profileImage;

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      Get.snackbar(
        'Error',
        'Failed to pick an image. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _uploadProfile() async {
    if (_profileImage == null) {
      Get.snackbar(
        'Error',
        'Please select a profile photo.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    String username = _usernameController.text.trim();
    if (username.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a username.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    bool isUsernameTaken = await _isUsernameTaken(username);
    if (isUsernameTaken) {
      Get.snackbar(
        'Error',
        'Username is already taken. Please choose a different one.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    String profileImageUrl = await _uploadProfileImage(_profileImage!);
    if (profileImageUrl.isEmpty) {
      Get.snackbar(
        'Error',
        'Failed to upload profile photo. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      await _authController.signup(
        username,
        _authController.user!.email ?? 'Unknown',
        '', // Placeholder for password (not needed in this step)
      );

      String uid = _authController.user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'username': username,
        'profileImageUrl': profileImageUrl,
      });

      Get.offAllNamed('/emailVerification');
    } catch (e) {
      print('Error uploading profile details: $e');
      Get.snackbar(
        'Error',
        'Failed to upload profile details. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<bool> _isUsernameTaken(String username) async {
    QuerySnapshot<Map<String, dynamic>> query = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  Future<String> _uploadProfileImage(File imageFile) async {
    try {
      String uid = _authController.user!.uid;
      String fileName = Uuid().v4(); // Generate a unique filename
      Reference storageRef =
          FirebaseStorage.instance.ref().child('profile_images/$uid/$fileName');

      UploadTask uploadTask = storageRef.putFile(imageFile);

      TaskSnapshot taskSnapshot = await uploadTask;
      String imageUrl = await taskSnapshot.ref.getDownloadURL();

      return imageUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return '';
    }
  }

  Future<void> _signOut() async {
    await _authController.signout();
    Get.offAllNamed('/login'); // Redirect to login screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(38, 38, 52, 1.0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Add Profile'),
        actions: [
          IconButton(
            onPressed: _uploadProfile,
            icon: Icon(Icons.check),
            color: Colors.red,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Center(
                        child: _profileImage == null
                            ? Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.red,
                                    width: 4.0,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  child: Icon(Icons.camera_alt),
                                  backgroundColor:
                                      const Color.fromARGB(255, 66, 64, 64),
                                ),
                              )
                            : Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.red,
                                    width: 4.0,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundImage: FileImage(_profileImage!),
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                TextButton(
                  onPressed: _signOut,
                  child: Text(
                    'Log Out',
                    style:
                        TextStyle(color: const Color.fromARGB(255, 209, 3, 3)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
