import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  File? _selectedImage;
  Uint8List? _webImage;
  String? _photoUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser!;
    _nameController.text = user.displayName ?? '';
    _emailController.text = user.email ?? '';
    _photoUrl = user.photoURL;
    debugPrint('🟣 Loaded EditProfilePage for UID: ${user.uid}');
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) {
      debugPrint('⚠️ No image selected.');
      return;
    }

    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      setState(() {
        _webImage = bytes;
        _selectedImage = null;
      });
    } else {
      setState(() {
        _selectedImage = File(image.path);
        _webImage = null;
      });
    }
  }

  Future<String?> _uploadImage(User user) async {
    try {
      if (_selectedImage == null && _webImage == null) return _photoUrl;

      final fileName =
          'profile_pictures/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);

      UploadTask uploadTask;
      if (kIsWeb && _webImage != null) {
        uploadTask = storageRef.putData(
          _webImage!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        uploadTask = storageRef.putFile(
          _selectedImage!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      }

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ Image uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint("❌ Upload error: $e");
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser!;
    setState(() => _isSaving = true);

    try {
      final newPhotoUrl = await _uploadImage(user);

      await user.updateDisplayName(_nameController.text);
      if (newPhotoUrl != null && newPhotoUrl.isNotEmpty) {
        await user.updatePhotoURL(newPhotoUrl);
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'displayName': _nameController.text.trim(),
        'email': user.email,
        'photoUrl': newPhotoUrl ?? _photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await user.reload();

      if (mounted) {
        setState(() {
          _photoUrl = newPhotoUrl ?? _photoUrl;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Profile updated successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('❌ Error updating profile: $e');
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to update profile: $e')),
      );
    }
  }

  Widget _buildProfileImage(User? user) {
    try {
      if (_webImage != null) {
        return CircleAvatar(radius: 60, backgroundImage: MemoryImage(_webImage!));
      } else if (_selectedImage != null) {
        return CircleAvatar(radius: 60, backgroundImage: FileImage(_selectedImage!));
      } else if (_photoUrl != null && _photoUrl!.isNotEmpty) {
        return ClipOval(
          child: Stack(
            alignment: Alignment.center,
            children: [
              const SizedBox(
                width: 120,
                height: 120,
                child: Center(child: CircularProgressIndicator()), // ✅ Loader shown while loading image
              ),
              Image.network(
                _photoUrl!,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    width: 120,
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('🚨 Network image error: $error');
                  return CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[400],
                    child: const Icon(Icons.person, size: 60, color: Colors.white),
                  );
                },
              ),
            ],
          ),
        );
      } else {
        return CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey[400],
          child: Text(
            (user?.displayName?.isNotEmpty == true
                ? user!.displayName![0].toUpperCase()
                : '?'),
            style: const TextStyle(fontSize: 50, color: Colors.white),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error building profile image: $e');
      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.grey[400],
        child: const Icon(Icons.person, size: 60, color: Colors.white),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Stack(
                  children: [
                    _buildProfileImage(user),
                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.blue),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _emailController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 30),
                _isSaving
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Changes'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
