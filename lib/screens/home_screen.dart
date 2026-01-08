import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:app/screens/settings/language_screen.dart';
import 'package:app/widgets/government_jobs_section.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/service_subscription_sheet.dart';

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
    if (serviceType == 'Job Post') {
      if (userData != null &&
          userData['company'] == null &&
          userData['skippedCompanyInfo'] != true) {
        final result = await Navigator.pushNamed(context, '/company-info');
        if (result == true && context.mounted) {
          await authProvider.refreshUserData();
          _handleCardTap(context, serviceType);
        }
        return;
      }
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
              sub['type'] == serviceType.toUpperCase().replaceAll(' ', '_') &&
              DateTime.parse(sub['endDate']).isAfter(DateTime.now()),  // Add this line
        );
      }

      // Handle Service Post
      if (serviceType == 'Service Post') {
        if (userData != null &&
            userData['company'] == null &&
            userData['skippedCompanyInfo'] != true) {
          final result = await Navigator.pushNamed(context, '/company-info');
          if (result == true && context.mounted) {
            await authProvider.refreshUserData();
            _handleCardTap(context, serviceType);
          }
          return;
        }
        Navigator.pushNamed(context, '/service-post');
        return;
      }

      // Handle Service Search and Job Search
      if ((serviceType == 'Service Search' || serviceType == 'Job Search') &&
          (hasServicePostSubscription || hasCurrentServiceSubscription)) {
        Navigator.pushNamed(
          context,
          '/${serviceType.toLowerCase().replaceAll(' ', '-')}',
        );
        return;
      }
    } catch (e) {
      print('Error checking subscription: $e');
    }

    if (!context.mounted) return;

    // Show subscription sheet for users without required subscription
    switch (serviceType) {
      case 'Service Search':
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
      case 'Job Search':
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
      case 'Service Post':
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
      decoration: theme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleCardTap(context, title),
          borderRadius: BorderRadius.circular(ThemeStyle.cardBorderRadius),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isDesktop ? 24 : 16),
                decoration: theme.iconBoxDecoration(context),
                child: Icon(
                  icon,
                  size:
                      isDesktop
                          ? ThemeStyle.iconSize * 1.5
                          : ThemeStyle.iconSize,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.titleStyle.copyWith(
                  fontSize:
                      isDesktop
                          ? theme.titleStyle.fontSize! * 1.2
                          : theme.titleStyle.fontSize,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = authProvider.userData;

    // Debug prints for user data and company status
    print('User Data: $userData');
    print('Company Info: ${userData?['company']}');
    print('Skipped Company Info: ${userData?['skippedCompanyInfo']}');

    final theme = AppTheme.style;
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return theme.buildPageBackground(
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            title: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Serviceinfo',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: isDesktop ? 24 : 20,
                    ),
                  ),
                  TextSpan(
                    text: 'tek',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: isDesktop ? 24 : 20,
                    ),
                  ),
                ],
              ),
            ),
            centerTitle: true,
          ),
          drawer: const AppDrawer(),
          body: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal:
                  isDesktop
                      ? (MediaQuery.of(context).size.width - 1200) / 2
                      : 0,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(
                      isDesktop ? 32.0 : ThemeStyle.defaultPadding,
                    ),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Welcome to Serviceinfo',
                            style: TextStyle(
                              fontSize: isDesktop ? 32 : 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(
                            text: 'tek',
                            style: TextStyle(
                              fontSize: isDesktop ? 32 : 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          isDesktop ? 32.0 : ThemeStyle.defaultPadding - 4,
                    ),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: isDesktop ? 4 : 2,
                      crossAxisSpacing: isDesktop ? 32 : 20,
                      mainAxisSpacing: isDesktop ? 32 : 20,
                      childAspectRatio: isDesktop ? 1.2 : 0.9,
                      children: [
                        _buildCard(
                          context,
                          'Service Search',
                          Icons.search,
                          '/service-search',
                        ),
                        _buildCard(
                          context,
                          'Service Post',
                          Icons.post_add,
                          '/service-post',
                        ),
                        _buildCard(
                          context,
                          'Job Search',
                          Icons.search_outlined,
                          '/job-search',
                        ),
                        _buildCard(
                          context,
                          'Job Post',
                          Icons.work,
                          '/job-post',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const GovernmentJobsSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
