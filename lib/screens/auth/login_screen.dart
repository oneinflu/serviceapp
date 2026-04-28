import 'package:app/providers/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, ThemeStyle.backgroundColor],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand Logo
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: ThemeStyle.primaryColor.withOpacity(0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Image.asset('assets/logo.jpeg', height: 100, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Welcome Text
                    Text(
                      AppLocalizations.of(context, 'welcome_back_header'),
                      style: theme.headingStyle(context),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context, 'glad_to_see_you_again'),
                      style: TextStyle(
                        color: ThemeStyle.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Input Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: theme.cardDecoration,
                      child: Column(
                        children: [
                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            decoration: theme.inputDecoration(
                              labelText: AppLocalizations.of(context, 'email_address'),
                              prefixIcon: Icons.alternate_email_rounded,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) return AppLocalizations.of(context, 'please_enter_email');
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            decoration: theme.inputDecoration(
                              labelText: AppLocalizations.of(context, 'password'),
                              prefixIcon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: ThemeStyle.primaryColor,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) return AppLocalizations.of(context, 'please_enter_password');
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          
                          // Login Button
                          theme.buildPrimaryButton(
                            text: AppLocalizations.of(context, 'login'),
                            isLoading: _isLoading,
                            onPressed: _handleLogin,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context, 'dont_have_account'),
                          style: TextStyle(color: ThemeStyle.textSecondary, fontSize: 15),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
                          child: Text(
                            AppLocalizations.of(context, 'register_now'),
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

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        await authProvider.refreshUserData();
        
        // Navigation logic
        try {
          var dio = Dio();
          final response = await dio.get(
            'https://servicebackendnew-e2d8v.ondigitalocean.app/api/companies/my-companies',
            options: Options(
              headers: {'Authorization': 'Bearer ${authProvider.token}'},
            ),
          );

          if (response.statusCode == 200) {
            final data = response.data;
            final hasCompanies = data['status'] == 'success' && 
                                data['results'] > 0 && 
                                (data['data']['companies'] as List).isNotEmpty;

            final userData = authProvider.userData;
            final hasSkipped = userData != null && userData['skippedCompanyInfo'] == true;

            if (hasCompanies || hasSkipped) {
              Navigator.pushReplacementNamed(context, '/home');
            } else {
              Navigator.pushReplacementNamed(context, '/company-info');
            }
          } else {
            _fallbackNavigation(authProvider, context);
          }
        } catch (e) {
          _fallbackNavigation(authProvider, context);
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _fallbackNavigation(AuthProvider authProvider, BuildContext context) {
    final userData = authProvider.userData;
    final hasCompanyInfo = userData != null && userData['company'] != null && userData['company'].isNotEmpty;
    final hasSkipped = userData != null && userData['skippedCompanyInfo'] == true;

    if (hasCompanyInfo || hasSkipped) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/company-info');
    }
  }
}
