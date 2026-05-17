import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:app/screens/settings/language_screen.dart';
import 'package:app/widgets/government_jobs_section.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../../widgets/service_subscription_sheet.dart';
import '../../l10n/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showSubscriptionSheet(
    BuildContext context, {
    required String serviceType,
    required int price,
    required List<String> benefits,
    bool isPremium = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ThemeStyle.cardBorderRadius),
        ),
      ),
      builder:
          (context) => ServiceSubscriptionSheet(
            serviceType: serviceType,
            price: price,
            benefits: benefits,
            isPremium: isPremium,
          ),
    );
  }

  void _handleCardTap(BuildContext context, String serviceType) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool isAuthenticated = authProvider.isAuthenticated;

    if (!isAuthenticated) {
      final result = await Navigator.pushNamed(context, '/login');
      if (result != true) return;
    }

    final token = authProvider.token;
    final userData = authProvider.userData;
    var dio = Dio();

    // Handle Job Post (free service)
    if (serviceType == 'job-post') {
      Navigator.pushNamed(context, '/job-post');
      return;
    }

    try {
      final response = await dio.request(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/subscriptions/my-subscriptions',
        options: Options(
          method: 'GET',
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      bool hasServicePostSubscription = false;
      bool hasCurrentServiceSubscription = false;

      if (response.statusCode == 200) {
        final subscriptions = response.data['data']['subscriptions'] as List;
        
        hasServicePostSubscription = subscriptions.any(
          (sub) =>
              sub['type'] == 'SERVICE_POST' &&
              DateTime.parse(sub['endDate']).isAfter(DateTime.now()),
        );

        hasCurrentServiceSubscription = subscriptions.any(
          (sub) =>
              sub['type'] == serviceType.toUpperCase().replaceAll('-', '_') &&
              DateTime.parse(sub['endDate']).isAfter(DateTime.now()),  // Add this line
        );
      }

      // Handle Service Post
      if (serviceType == 'service-post') {
        Navigator.pushNamed(context, '/service-post');
        return;
      }

      // Handle Service Search and Job Search
      if ((serviceType == 'service-search' || serviceType == 'job-search') &&
          (hasServicePostSubscription || hasCurrentServiceSubscription)) {
        Navigator.pushNamed(
          context,
          '/$serviceType',
        );
        return;
      }
    } catch (e) {
      print('Error checking subscription: $e');
    }

    if (!context.mounted) return;

    // Show subscription sheet for users without required subscription
    switch (serviceType) {
      case 'service-search':
        _showSubscriptionSheet(
          context,
          serviceType: serviceType,
          price: 100,
          benefits: [
            'Unlimited service search for 365 days',
            'Direct booking with service providers',
            'Verified service providers only',
          ],
          isPremium: true,
        );
        break;
      case 'job-search':
        _showSubscriptionSheet(
          context,
          serviceType: serviceType,
          price: 100,
          benefits: [
            'Access to all job listings for 365 days',
            'Direct application to jobs',
            'Early access to new job postings',
            'Resume builder and job alerts',
          ],
          isPremium: true,
        );
        break;
      case 'service-post':
        _showSubscriptionSheet(
          context,
          serviceType: serviceType,
          price: 500,
          benefits: [
            'Post unlimited services for 365 days',
            'Business profile customization',
            'Priority listing in search results',
            'Analytics and insights',
            'Includes access to Job & Service search feature',
          ],
          isPremium: true,
        );
        break;
    }
  }

  Widget _buildCard(
    BuildContext context,
    String title,
    IconData icon,
    String route,
  ) {
    final theme = AppTheme.style;
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Container(
      decoration: isDesktop
          ? theme.cardDecoration
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ThemeStyle.cardBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: ThemeStyle.primaryColor.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleCardTap(context, route.replaceAll('/', '')),
          borderRadius: BorderRadius.circular(isDesktop ? ThemeStyle.cardBorderRadius : 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(isDesktop ? 18 : 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.15),
                        Theme.of(context).primaryColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(isDesktop ? 20 : 14),
                  ),
                  child: Icon(
                    icon,
                    size: isDesktop ? 32 : 24,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: isDesktop ? 36 : 28,
                  child: Center(
                    child: Text(
                      title.replaceAll(' ', '\n'),
                      style: theme.titleStyle.copyWith(
                        fontSize: isDesktop ? 14 : 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = authProvider.userData;
    final theme = AppTheme.style;
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return theme.buildPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context, 'app_name_main'),
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
              ),
              Text(
                AppLocalizations.of(context, 'app_name_suffix'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        drawer: const AppDrawer(),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modern Hero Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isDesktop ? 40 : 20),
                margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                decoration: BoxDecoration(
                  gradient: theme.mainGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: ThemeStyle.primaryColor.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppLocalizations.of(context, 'welcome_back')}${userData?['name'] ?? 'User'}! 👋',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context, 'create_profile_desc'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to profile creation or settings
                        Navigator.pushNamed(context, '/profile'); // Adjust route if needed
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: ThemeStyle.primaryColor,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context, 'complete_profile'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              theme.buildSectionHeader(AppLocalizations.of(context, 'explore_services')),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  crossAxisSpacing: isDesktop ? 20 : 10,
                  mainAxisSpacing: isDesktop ? 20 : 10,
                  childAspectRatio: isDesktop ? 1.0 : 0.72,
                  children: [
                    _buildCard(
                      context,
                      AppLocalizations.of(context, 'service_search'),
                      Icons.search_rounded,
                      '/service-search',
                    ),
                    _buildCard(
                      context,
                      AppLocalizations.of(context, 'service_post'),
                      Icons.add_business_rounded,
                      '/service-post',
                    ),
                    _buildCard(
                      context,
                      AppLocalizations.of(context, 'job_search'),
                      Icons.work_outline_rounded,
                      '/job-search',
                    ),
                    _buildCard(
                      context,
                      AppLocalizations.of(context, 'job_post'),
                      Icons.post_add_rounded,
                      '/job-post',
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              const GovernmentJobsSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
