import 'package:app/providers/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.style;
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return theme.buildPageBackground(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal:
              isDesktop
                  ? (MediaQuery.of(context).size.width - 400) / 2
                  : ThemeStyle.defaultPadding,
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
                'Welcome Back!',
                style: theme
                    .headingStyle(context)
                    .copyWith(fontSize: isDesktop ? 32 : 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please sign in to continue',
                style: theme.titleStyle.copyWith(fontSize: isDesktop ? 18 : 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Container(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 400 : double.infinity,
                ),
                child: theme.buildCard(
                  child: Column(
                    children: [
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
                                isDesktop ? 20 : 16,
                              ),
                            ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
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
                                isDesktop ? 20 : 16,
                              ),
                            ),
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: isDesktop ? 50 : 44,
                        child: ElevatedButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : () async {
                                    if (_formKey.currentState!.validate()) {
                                      setState(() => _isLoading = true);
                                      try {
                                        final authProvider =
                                            Provider.of<AuthProvider>(
                                              context,
                                              listen: false,
                                            );
                                        final success = await authProvider
                                            .login(
                                              _emailController.text,
                                              _passwordController.text,
                                            );

                                        // Inside the login button onPressed callback, replace the existing success navigation with:
                                        if (success && mounted) {
                                          // Ensure we have the latest user data
                                          await authProvider.refreshUserData();

                                          // First check if user has companies
                                          try {
                                            var dio = Dio();
                                            final response = await dio.get(
                                              'https://servicebackendnew-e2d8v.ondigitalocean.app/api/companies/my-companies',
                                              options: Options(
                                                headers: {
                                                  'Authorization':
                                                      'Bearer ${authProvider.token}',
                                                },
                                              ),
                                            );

                                            if (response.statusCode == 200) {
                                              final data = response.data;
                                              final hasCompanies =
                                                  data['status'] == 'success' &&
                                                  data['results'] > 0 &&
                                                  data['data']['companies']
                                                      is List &&
                                                  (data['data']['companies']
                                                          as List)
                                                      .isNotEmpty;

                                              // Check if user has skipped company info
                                              final userData =
                                                  authProvider.userData;
                                              final hasSkippedCompanyInfo =
                                                  userData != null &&
                                                  userData['skippedCompanyInfo'] ==
                                                      true;

                                              if (hasCompanies ||
                                                  hasSkippedCompanyInfo) {
                                                // User either has companies or has skipped company info
                                                Navigator.pushReplacementNamed(
                                                  context,
                                                  '/home',
                                                );
                                              } else {
                                                // User has no companies and hasn't skipped company info
                                                Navigator.pushReplacementNamed(
                                                  context,
                                                  '/company-info',
                                                );
                                              }
                                            } else {
                                              // If API call fails, fall back to checking userData
                                              _fallbackNavigation(
                                                authProvider,
                                                context,
                                              );
                                            }
                                          } catch (e) {
                                            print(
                                              'Error checking companies: $e',
                                            );
                                            // If API call fails, fall back to checking userData
                                            _fallbackNavigation(
                                              authProvider,
                                              context,
                                            );
                                          }
                                        }
                                      } finally {
                                        if (mounted)
                                          setState(() => _isLoading = false);
                                      }
                                    }
                                  },
                          style: theme.primaryButtonStyle(context),
                          child:
                              _isLoading
                                  ? theme.loadingIndicator()
                                  : Text(
                                    'Login',
                                    style: theme.buttonTextStyle.copyWith(
                                      fontSize: isDesktop ? 18 : 16,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: theme.subtitleStyle.copyWith(
                      fontSize: isDesktop ? 16 : 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/register');
                    },
                    child: Text(
                      'Register',
                      style: theme
                          .linkStyle(context)
                          .copyWith(fontSize: isDesktop ? 16 : 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Add this helper method in the _LoginScreenState class
void _fallbackNavigation(AuthProvider authProvider, BuildContext context) {
  final userData = authProvider.userData;
  final hasCompanyInfo =
      userData != null &&
      userData['company'] != null &&
      userData['company'].isNotEmpty;
  final hasSkippedCompanyInfo =
      userData != null && userData['skippedCompanyInfo'] == true;

  if (hasCompanyInfo || hasSkippedCompanyInfo) {
    Navigator.pushReplacementNamed(context, '/home');
  } else {
    Navigator.pushReplacementNamed(context, '/company-info');
  }
}
