import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

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
            const SnackBar(
              content: Text('Registration successful! Please login.'),
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
        String errorMessage = 'Registration failed';

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
    final isDesktop = MediaQuery.of(context).size.width > 768;
    final formWidth = isDesktop ? 500.0 : double.infinity;
    final horizontalPadding =
        isDesktop
            ? (MediaQuery.of(context).size.width - formWidth) / 2
            : ThemeStyle.defaultPadding;

    return theme.buildPageBackground(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: ThemeStyle.defaultPadding,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              Image.asset('assets/logo.jpeg', height: isDesktop ? 160 : 120),
              const SizedBox(height: 30),
              Text(
                'Create Account',
                style: theme
                    .headingStyle(context)
                    .copyWith(fontSize: isDesktop ? 32 : 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please fill in your details to create an account',
                style: theme.titleStyle.copyWith(
                  color: Colors.grey[600],
                  fontSize: isDesktop ? 18 : 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              theme.buildCard(
                child: Container(
                  width: formWidth,
                  padding: EdgeInsets.all(isDesktop ? 40 : 20),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _fullNameController,
                        decoration: theme
                            .inputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icons.person_outline,
                              context: context,
                            )
                            .copyWith(
                              contentPadding: EdgeInsets.all(
                                isDesktop ? 20 : 12,
                              ),
                            ),
                        style: TextStyle(fontSize: isDesktop ? 16 : 14),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: isDesktop ? 30 : 20),
                      TextFormField(
                        controller: _emailController,
                        decoration: theme
                            .inputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icons.email_outlined,
                              context: context,
                            )
                            .copyWith(
                              contentPadding: EdgeInsets.all(
                                isDesktop ? 20 : 12,
                              ),
                            ),
                        style: TextStyle(fontSize: isDesktop ? 16 : 14),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: isDesktop ? 30 : 20),
                      TextFormField(
                        controller: _phoneController,
                        decoration: theme
                            .inputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icons.phone_outlined,
                              context: context,
                            )
                            .copyWith(
                              contentPadding: EdgeInsets.all(
                                isDesktop ? 20 : 12,
                              ),
                            ),
                        style: TextStyle(fontSize: isDesktop ? 16 : 14),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: isDesktop ? 30 : 20),
                      TextFormField(
                        controller: _passwordController,
                        decoration: theme
                            .inputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icons.lock_outline,
                              context: context,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Theme.of(context).primaryColor,
                                  size: isDesktop ? 24 : 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            )
                            .copyWith(
                              contentPadding: EdgeInsets.all(
                                isDesktop ? 20 : 12,
                              ),
                            ),
                        style: TextStyle(fontSize: isDesktop ? 16 : 14),
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: isDesktop ? 30 : 20),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: theme
                            .inputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: Icons.lock_outline,
                              context: context,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Theme.of(context).primaryColor,
                                  size: isDesktop ? 24 : 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            )
                            .copyWith(
                              contentPadding: EdgeInsets.all(
                                isDesktop ? 20 : 12,
                              ),
                            ),
                        style: TextStyle(fontSize: isDesktop ? 16 : 14),
                        obscureText: _obscureConfirmPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: isDesktop ? 30 : 20),
                      TextFormField(
                        controller: _referralCodeController,
                        decoration: theme
                            .inputDecoration(
                              labelText: 'Referral Code (Optional)',
                              prefixIcon: Icons.card_giftcard_outlined,
                              context: context,
                            )
                            .copyWith(
                              contentPadding: EdgeInsets.all(
                                isDesktop ? 20 : 12,
                              ),
                            ),
                        style: TextStyle(fontSize: isDesktop ? 16 : 14),
                      ),
                      SizedBox(height: isDesktop ? 40 : 30),
                      SizedBox(
                        width: double.infinity,
                        height: isDesktop ? 56 : 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator()
                                  : Text(
                                    'Register',
                                    style: TextStyle(
                                      fontSize: isDesktop ? 18 : 16,
                                    ),
                                  ),
                        ),
                      ),
                      SizedBox(height: isDesktop ? 30 : 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(fontSize: isDesktop ? 16 : 14),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            child: Text(
                              'Login',
                              style: TextStyle(fontSize: isDesktop ? 16 : 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
