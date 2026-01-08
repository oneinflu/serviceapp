import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class MySubscriptionsScreen extends StatefulWidget {
  const MySubscriptionsScreen({super.key});

  @override
  State<MySubscriptionsScreen> createState() => _MySubscriptionsScreenState();
}

class _MySubscriptionsScreenState extends State<MySubscriptionsScreen> {
  List<Map<String, dynamic>> subscriptions = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchSubscriptions();
  }

  Future<void> _fetchSubscriptions() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      var dio = Dio();
      var response = await dio.request(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/subscriptions/my-subscriptions',
        options: Options(
          method: 'GET',
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          subscriptions = List<Map<String, dynamic>>.from(
            response.data['data']['subscriptions'],
          );
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Failed to load subscriptions';
        isLoading = false;
      });
    }
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _getRemainingDays(String endDateString) {
    final endDate = DateTime.parse(endDateString);
    final now = DateTime.now();
    final difference = endDate.difference(now);
    return '${difference.inDays} days remaining';
  }

  Color _getSubscriptionColor(String type) {
    switch (type) {
      case 'SERVICE_SEARCH':
        return Colors.blue;
      case 'SERVICE_POST':
        return Colors.green;
      case 'JOB_SEARCH':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatSubscriptionType(String type) {
    return type
        .split('_')
        .map((word) => word[0] + word.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.style;

    return theme.buildPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: theme.buildAppBar(context, 'My Subscriptions'),
        body:
            isLoading
                ? Center(
                  child: theme.loadingIndicator(
                    color: Theme.of(context).primaryColor,
                  ),
                )
                : error != null
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(error!, style: theme.titleStyle),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchSubscriptions,
                        style: theme.primaryButtonStyle(context),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
                : subscriptions.isEmpty
                ? Center(
                  child: Text(
                    'No active subscriptions',
                    style: theme.titleStyle,
                  ),
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(ThemeStyle.defaultPadding),
                  itemCount: subscriptions.length,
                  itemBuilder: (context, index) {
                    final subscription = subscriptions[index];
                    final type = subscription['type'] as String;
                    final endDate = subscription['endDate'] as String;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: theme.cardDecoration.copyWith(
                        border: Border.all(
                          color: _getSubscriptionColor(type),
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatSubscriptionType(type),
                                  style: theme
                                      .headingStyle(context)
                                      .copyWith(
                                        color: _getSubscriptionColor(type),
                                        fontSize: 20,
                                      ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getSubscriptionColor(
                                      type,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _getRemainingDays(endDate),
                                    style: TextStyle(
                                      color: _getSubscriptionColor(type),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            theme.buildDivider(verticalPadding: 8),
                            Text(
                              'Valid until ${_formatDate(endDate)}',
                              style: theme.titleStyle,
                            ),
                            if (type == 'SERVICE_POST')
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '* Includes access to Job & Service Search feature',
                                  style: theme.subtitleStyle.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
