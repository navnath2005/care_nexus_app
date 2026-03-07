import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data'; // For Uint8List

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;

  bool _isLoading = false;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: user?.displayName);
    _phoneController = TextEditingController();
    _ageController = TextEditingController();
    _fetchExistingData();
  }

  // Fetch extra details (phone/age) from Firestore
  Future<void> _fetchExistingData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    if (doc.exists) {
      setState(() {
        _phoneController.text = doc.data()?['phone'] ?? "";
        _ageController.text = doc.data()?['age'] ?? "";
      });
    }
  }

  // Change File? _imageFile to:
  Uint8List? _webImage;
  File? _mobileImage;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      if (kIsWeb) {
        // For Web
        final bytes = await image.readAsBytes();
        setState(() => _webImage = bytes);
      } else {
        // For Mobile
        setState(() => _mobileImage = File(image.path));
      }
    }
  }

  Future<void> _saveProfileToFirebase() async {
    setState(() => _isLoading = true);
    try {
      String? finalPhotoUrl = user?.photoURL;

      // UPLOAD LOGIC
      if (_webImage != null || _mobileImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('user_profiles')
            .child('${user!.uid}.jpg');

        if (kIsWeb) {
          await ref.putData(_webImage!); // Use putData for Web
        } else {
          await ref.putFile(_mobileImage!); // Use putFile for Mobile
        }
        finalPhotoUrl = await ref.getDownloadURL();
      }

      // SAVE TO FIRESTORE
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'name': _nameController.text.trim(),
        'photoUrl': finalPhotoUrl,
      }, SetOptions(merge: true));

      // Update Local Auth Profile
      await user!.updatePhotoURL(finalPhotoUrl);

      Navigator.pop(context);
    } catch (e) {
      debugPrint("Upload Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (user == null) {
      _showError("User not logged in");
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final uid = user!.uid;
      String? photoUrl = user!.photoURL;

      // Upload image
      if (_imageFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('$uid.jpg');

        await ref.putFile(_imageFile!);
        photoUrl = await ref.getDownloadURL();
      }

      // Update Firebase Auth
      await user!.updateDisplayName(_nameController.text.trim());
      if (photoUrl != null) {
        await user!.updatePhotoURL(photoUrl);
      }

      // Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await user!.reload();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile"), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Picture Section
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.blue.shade100,
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : (user?.photoURL != null
                                          ? NetworkImage(user!.photoURL!)
                                          : null)
                                      as ImageProvider?,
                            child: _imageFile == null && user?.photoURL == null
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.blue,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Colors.blue.shade600,
                              radius: 18,
                              child: const Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Fields
                    _buildInput(
                      controller: _nameController,
                      label: "Full Name",
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 16),
                    _buildInput(
                      controller: _phoneController,
                      label: "Phone Number",
                      icon: Icons.phone,
                      type: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildInput(
                      controller: _ageController,
                      label: "Age",
                      icon: Icons.cake,
                      type: TextInputType.number,
                    ),

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          "SAVE CHANGES",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => v!.isEmpty ? "Required" : null,
    );
  }
}
