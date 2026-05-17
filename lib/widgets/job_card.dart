import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class JobCard extends StatelessWidget {
  final String jobTitle;
  final String organizationName;
  final DateTime lastDateToApply;
  final String applyLink;
  final String jobType;

  const JobCard({
    super.key,
    required this.jobTitle,
    required this.organizationName,
    required this.lastDateToApply,
    required this.applyLink,
    required this.jobType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.style;
    final authProvider = Provider.of<AuthProvider>(context);
    final isAuthenticated = authProvider.isAuthenticated;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jobTitle,
                      style: theme.titleStyle.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.account_balance_rounded, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            organizationName,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: ThemeStyle.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  jobType,
                  style: const TextStyle(
                    color: ThemeStyle.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoItem(Icons.calendar_today_rounded, 'Last Date', lastDateToApply.toString().split(' ')[0]),
            ],
          ),
          const SizedBox(height: 20),
          theme.buildPrimaryButton(
            text: isAuthenticated 
                ? (applyLink.startsWith('tel:') ? 'Call Now' : 'Apply Now') 
                : 'Login or Register',
            onPressed: () async {
              if (!isAuthenticated) {
                Navigator.pushNamed(context, '/login');
                return;
              }
              if (applyLink.isNotEmpty) {
                final Uri uri = Uri.parse(applyLink);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  if (applyLink.startsWith('tel:')) {
                    await launchUrl(uri);
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ThemeStyle.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: ThemeStyle.textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: ThemeStyle.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
