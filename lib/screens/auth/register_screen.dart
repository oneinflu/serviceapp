import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _referralCodeController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _fullNameController.dispose();
    _referralCodeController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dio = Dio();
      final data = {
        "name": _fullNameController.text,
        "email": _emailController.text,
        "phone": _phoneController.text,
        "password": _passwordController.text,
        "referral_code": _referralCodeController.text,
      };

      final response = await dio.post(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/auth/register',
        data: data,
      );

      if (response.statusCode == 201) {
        // Dio automatically parses JSON response
        final responseData = response.data;

        if (responseData['status'] == "success" && mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context, 'registration_successful')),
              backgroundColor: Colors.green,
            ),
          );

          // Try to login automatically
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          final loginSuccess = await authProvider.login(
            _emailController.text,
            _passwordController.text,
          );

          // After successful registration and login:
          if (loginSuccess && mounted) {
            Navigator.pushReplacementNamed(context, '/company-info');
          } else {
            // Navigate to login screen after a short delay if auto-login fails
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            });
          }
        }
      }
    } catch (e) {
      // Handle error with user feedback
      if (mounted) {
        String errorMessage = AppLocalizations.of(context, 'registration_failed');

        // Try to extract more specific error message if available
        if (e is DioException && e.response != null) {
          final responseData = e.response?.data;
          if (responseData != null && responseData['message'] != null) {
            errorMessage = responseData['message'];
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.style;
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, ThemeStyle.backgroundColor],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Brand Logo
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: ThemeStyle.primaryColor.withOpacity(0.15),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ThemeStyle.primaryColor.withOpacity(0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(
                          'assets/logo.jpeg',
                          height: 223,
                          width: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Header
                    Text(
                      AppLocalizations.of(context, 'create_account'),
                      style: theme.headingStyle(context),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context, 'join_us_today'),
                      style: TextStyle(
                        color: ThemeStyle.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Form Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: theme.cardDecoration,
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _fullNameController,
                            label: AppLocalizations.of(context, 'full_name'),
                            icon: Icons.person_outline_rounded,
                            theme: theme,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _emailController,
                            label: AppLocalizations.of(context, 'email_address'),
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            theme: theme,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _phoneController,
                            label: AppLocalizations.of(context, 'phone_number'),
                            icon: Icons.phone_android_rounded,
                            keyboardType: TextInputType.phone,
                            theme: theme,
                            isOptional: true,
                          ),
                          const SizedBox(height: 20),
                          _buildPasswordField(
                            controller: _passwordController,
                            label: AppLocalizations.of(context, 'password'),
                            obscureText: _obscurePassword,
                            onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                            theme: theme,
                          ),
                          const SizedBox(height: 20),
                          _buildPasswordField(
                            controller: _confirmPasswordController,
                            label: AppLocalizations.of(context, 'confirm_password'),
                            obscureText: _obscureConfirmPassword,
                            onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            theme: theme,
                            validator: (value) {
                              if (value == null || value.isEmpty) return AppLocalizations.of(context, 'please_confirm_password');
                              if (value != _passwordController.text) return AppLocalizations.of(context, 'passwords_do_not_match');
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _referralCodeController,
                            label: AppLocalizations.of(context, 'referral_code_optional'),
                            icon: Icons.card_giftcard_rounded,
                            theme: theme,
                            isLast: true,
                            isOptional: true,
                          ),
                          const SizedBox(height: 32),
                          
                          theme.buildPrimaryButton(
                            text: AppLocalizations.of(context, 'register'),
                            isLoading: _isLoading,
                            onPressed: _register,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context, 'already_have_account'),
                          style: TextStyle(color: ThemeStyle.textSecondary, fontSize: 15),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                          child: Text(
                            AppLocalizations.of(context, 'login'),
                            style: TextStyle(
                              color: ThemeStyle.primaryColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeStyle theme,
    TextInputType keyboardType = TextInputType.text,
    bool isLast = false,
    bool isOptional = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: theme.inputDecoration(
        labelText: label,
        prefixIcon: icon,
      ),
      keyboardType: keyboardType,
      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
      validator: (value) {
        if (!isOptional && (value == null || value.isEmpty)) return '${AppLocalizations.of(context, 'please_enter')} $label';
        return null;
      },
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    required ThemeStyle theme,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: theme.inputDecoration(
        labelText: label,
        prefixIcon: Icons.lock_outline_rounded,
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: ThemeStyle.primaryColor,
          ),
          onPressed: onToggle,
        ),
      ),
      obscureText: obscureText,
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) return '${AppLocalizations.of(context, 'please_enter')} $label';
        return null;
      },
    );
  }
}
