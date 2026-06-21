import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSaving = false;
  bool _isUploadingPic = false;
  String? _profilePicUrl;
  File? _pickedImageFile;

  @override
  void initState() {
    super.initState();
    final userData = Provider.of<AuthProvider>(context, listen: false).userData;
    _nameController.text = userData?['name'] ?? '';
    _emailController.text = userData?['email'] ?? '';
    _phoneController.text = userData?['phone'] ?? '';
    _profilePicUrl = userData?['profilePicUrl'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (picked == null) return;

    setState(() {
      _pickedImageFile = File(picked.path);
      _isUploadingPic = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    try {
      final formData = FormData.fromMap({
        'profilePic': await MultipartFile.fromFile(
          picked.path,
          filename: 'profile_pic.jpg',
        ),
      });

      final response = await Dio().post(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/uploads/profile-pic',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final url = response.data['data']['url'] as String;
        setState(() => _profilePicUrl = url);
        // Update local user data so the drawer refreshes
        await authProvider.refreshUserData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPic = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    try {
      final response = await Dio().put(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/auth/profile',
        data: {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        await authProvider.refreshUserData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.style;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ThemeStyle.iconColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Edit Profile', style: theme.appBarTitleStyle(context)),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: theme.backgroundGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ThemeStyle.defaultPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // Profile picture
                Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _isUploadingPic ? null : _pickAndUploadImage,
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor: ThemeStyle.primaryColor.withOpacity(0.12),
                          backgroundImage: _pickedImageFile != null
                              ? FileImage(_pickedImageFile!) as ImageProvider
                              : (_profilePicUrl != null && _profilePicUrl!.isNotEmpty
                                  ? NetworkImage(_profilePicUrl!)
                                  : null),
                          child: (_pickedImageFile == null &&
                                  (_profilePicUrl == null || _profilePicUrl!.isEmpty))
                              ? Text(
                                  _nameController.text.isNotEmpty
                                      ? _nameController.text[0].toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w800,
                                    color: ThemeStyle.primaryColor,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUploadingPic ? null : _pickAndUploadImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: ThemeStyle.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: _isUploadingPic
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _isUploadingPic ? null : _pickAndUploadImage,
                    child: const Text('Change Profile Photo'),
                  ),
                ),
                const SizedBox(height: 24),

                theme.buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Personal Information', style: theme.titleStyle),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Email is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: theme.primaryButtonStyle(context),
                  child: _isSaving
                      ? theme.loadingIndicator()
                      : Text('Save Changes', style: theme.buttonTextStyle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
