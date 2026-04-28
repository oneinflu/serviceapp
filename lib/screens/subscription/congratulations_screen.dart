import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../theme/app_theme.dart';

class CongratulationsScreen extends StatelessWidget {
  final String serviceType;
  final String nextRoute;

  const CongratulationsScreen({
    super.key,
    required this.serviceType,
    required this.nextRoute,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.style;
    
    // Determine which benefits to show based on serviceType
    final benefits = _getBenefitsForType(serviceType);

    return Scaffold( // Changed to Scaffold for better theme integration
      backgroundColor: Colors.white,
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, ThemeStyle.backgroundColor],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    theme.buildCard(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          // Lottie Celebration Placeholder or Icon
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 100,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          Text(
                            'Congratulations!',
                            style: theme.headingStyle(context),
                          ),
                          const SizedBox(height: 16),
                          
                          Text(
                            'Your $serviceType subscription is now active.',
                            textAlign: TextAlign.center,
                            style: theme.titleStyle.copyWith(
                              color: ThemeStyle.textPrimary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          Text(
                            'You now have full access to all premium features.',
                            textAlign: TextAlign.center,
                            style: theme.subtitleStyle,
                          ),
                          
                          theme.buildDivider(verticalPadding: 32),
                          
                          // Dynamic Benefits List
                          ...benefits.map((benefit) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildBenefitItem(context, benefit['text']!, benefit['icon'] as IconData),
                          )),
                          
                          const SizedBox(height: 40),
                          
                          // Continue Button
                          theme.buildPrimaryButton(
                            text: 'Get Started',
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, nextRoute);
                            },
                          ),
                        ],
                      ),
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

  List<Map<String, dynamic>> _getBenefitsForType(String type) {
    if (type.contains('Job')) {
      return [
        {'text': 'Access to all job listings', 'icon': Icons.work_outline},
        {'text': 'Direct application to jobs', 'icon': Icons.send_rounded},
        {'text': 'Early access to new postings', 'icon': Icons.speed_rounded},
      ];
    } else if (type.contains('Service Search')) {
      return [
        {'text': 'Unlimited provider search', 'icon': Icons.search_rounded},
        {'text': 'Direct contact info', 'icon': Icons.contact_mail_outlined},
        {'text': 'Verified providers only', 'icon': Icons.verified_user_outlined},
      ];
    } else {
      return [
        {'text': 'Unlimited profile visibility', 'icon': Icons.visibility},
        {'text': 'Priority search listing', 'icon': Icons.trending_up},
        {'text': 'Business analytics access', 'icon': Icons.analytics_outlined},
      ];
    }
  }
  
  Widget _buildBenefitItem(BuildContext context, String text, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ThemeStyle.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: ThemeStyle.primaryColor, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: ThemeStyle.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
