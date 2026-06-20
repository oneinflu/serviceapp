import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'job_card.dart';
import 'service_subscription_sheet.dart';

class GovernmentJobsSection extends StatefulWidget {
  const GovernmentJobsSection({super.key});

  @override
  State<GovernmentJobsSection> createState() => _GovernmentJobsSectionState();
}

class _GovernmentJobsSectionState extends State<GovernmentJobsSection> {
  final List<String> jobTypes = [
    'Govt Jobs',
    'Semi Govt Jobs',
    'Private Jobs',
    'Individual Jobs',
  ];
  String selectedJobType = 'Govt Jobs';
  List<dynamic> govtJobs = [];
  List<dynamic> userJobs = [];
  bool isLoading = true;
  bool hasJobSearchSubscription = false;

  @override
  void initState() {
    super.initState();
    fetchJobs();
  }

  Future<void> fetchJobs() async {
    try {
      var dio = Dio();
      
      // Fetch Government Jobs
      var responseGovt = await dio.get(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/government-jobs',
      );
      
      List<dynamic> fetchedGovt = [];
      if (responseGovt.statusCode == 200) {
        fetchedGovt = responseGovt.data['data']['governmentJobs'] ?? [];
      }

      // Fetch User-posted Jobs
      List<dynamic> fetchedUser = [];
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.token;
        
        Map<String, dynamic> headers = {};
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }
        
        var responseUser = await dio.get(
          'https://servicebackendnew-e2d8v.ondigitalocean.app/api/jobs',
          options: Options(headers: headers),
        );
        
        if (responseUser.statusCode == 200) {
          fetchedUser = responseUser.data['data']['jobs'] ?? [];
        }
      } catch (e) {
        print('Error fetching user jobs: $e');
      }

      // Fetch user's subscriptions
      bool subCheck = false;
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.token;
        if (token != null) {
          var responseSub = await dio.get(
            'https://servicebackendnew-e2d8v.ondigitalocean.app/api/subscriptions/my-subscriptions',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
          if (responseSub.statusCode == 200 && responseSub.data['status'] == 'success') {
            final List subscriptions = responseSub.data['data']['subscriptions'] ?? [];
            subCheck = subscriptions.any((sub) {
              final type = sub['type']?.toString().toUpperCase();
              final isExpired = DateTime.parse(sub['endDate']).isBefore(DateTime.now());
              return (type == 'JOB_SEARCH' || type == 'SERVICE_POST') && !isExpired;
            });
          }
        }
      } catch (e) {
        print('Error fetching subscriptions: $e');
      }

      setState(() {
        govtJobs = fetchedGovt;
        userJobs = fetchedUser;
        hasJobSearchSubscription = subCheck;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching jobs: $e');
    }
  }

  void _showSubscriptionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ThemeStyle.cardBorderRadius),
        ),
      ),
      builder: (context) => const ServiceSubscriptionSheet(
        serviceType: 'job-search',
        price: 100,
        benefits: [
          'Access to all job listings for 365 days',
          'Direct application to jobs',
          'Early access to new job postings',
          'Resume builder and job alerts',
        ],
        isPremium: true,
      ),
    ).then((_) {
      fetchJobs();
    });
  }

  Widget _buildSubscriptionCard() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final theme = AppTheme.style;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.shade100.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.withOpacity(0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amber.shade50,
                    ),
                    child: Icon(
                      Icons.lock_person_rounded,
                      size: 40,
                      color: Colors.amber.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unlock $selectedJobType',
                    style: theme.titleStyle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'An active Job Search subscription is required to view details and apply for direct private or individual job posts.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMiniBenefit(Icons.check_circle_outline, 'Direct Apply'),
                      const SizedBox(width: 16),
                      _buildMiniBenefit(Icons.phone_in_talk_outlined, 'Direct Contacts'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!authProvider.isAuthenticated) {
                          Navigator.pushNamed(context, '/login').then((res) {
                            if (res == true) {
                              fetchJobs();
                            }
                          });
                        } else {
                          _showSubscriptionSheet(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF002366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        authProvider.isAuthenticated
                            ? 'Subscribe Now • ₹100'
                            : 'Login to Subscribe',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBenefit(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.amber.shade800),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  List<dynamic> getFilteredJobs() {
    if (selectedJobType == 'Govt Jobs' || selectedJobType == 'Semi Govt Jobs') {
      return govtJobs
          .where((job) => job['jobType'].toString().trim() == selectedJobType.trim())
          .toList();
    } else if (selectedJobType == 'Private Jobs') {
      return userJobs
          .where((job) => job['isCompanyPost'] == true || job['companyId'] != null || job['company'] != null)
          .toList();
    } else if (selectedJobType == 'Individual Jobs') {
      return userJobs
          .where((job) => job['isCompanyPost'] != true && job['companyId'] == null && job['company'] == null)
          .toList();
    }
    return [];
  }

  Widget _buildJobTypePill(String label) {
    final bool isSelected = selectedJobType == label;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedJobType = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12.0),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? ThemeStyle.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? ThemeStyle.primaryColor : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: ThemeStyle.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : ThemeStyle.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredJobs = getFilteredJobs();
    final theme = AppTheme.style;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        theme.buildSectionHeader('Jobs in India'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Row(
            children: jobTypes.map((type) => _buildJobTypePill(type)).toList(),
          ),
        ),
        const SizedBox(height: 12),
        if (isLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(ThemeStyle.primaryColor),
              ),
            ),
          )
        else if ((selectedJobType == 'Private Jobs' || selectedJobType == 'Individual Jobs') && !hasJobSearchSubscription)
          _buildSubscriptionCard()
        else if (filteredJobs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40.0),
            child: Column(
              children: [
                Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No jobs found for $selectedJobType',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            itemCount: filteredJobs.length,
            itemBuilder: (context, index) {
              final job = filteredJobs[index];
              String title = '';
              String org = '';
              DateTime date = DateTime.now();
              String link = '';
              String type = '';

              if (selectedJobType == 'Govt Jobs' || selectedJobType == 'Semi Govt Jobs') {
                title = job['jobTitle'] ?? '';
                org = job['organizationName'] ?? '';
                date = job['lastDateToApply'] != null 
                    ? (DateTime.tryParse(job['lastDateToApply']) ?? DateTime.now())
                    : DateTime.now();
                link = job['applyLink'] ?? '';
                type = job['jobType'] ?? '';
              } else {
                final categories = job['categories'] as List? ?? [];
                title = categories.isNotEmpty ? (categories[0]['name'] ?? 'Job Opportunity') : 'Job Opportunity';
                
                final userObj = job['user'];
                final userName = (userObj is Map) ? (userObj['name'] ?? 'Individual Post') : 'Individual Post';
                
                final company = job['companyId'] ?? job['company'];
                if (company is Map && company['name'] != null) {
                  org = company['name'];
                } else {
                  org = userName;
                }

                date = job['updatedAt'] != null 
                    ? (DateTime.tryParse(job['updatedAt']) ?? DateTime.now()) 
                    : (job['createdAt'] != null 
                        ? (DateTime.tryParse(job['createdAt']) ?? DateTime.now()) 
                        : DateTime.now());
                
                final phone = (userObj is Map) ? userObj['phone'] : null;
                link = phone != null ? 'tel:$phone' : '';
                type = selectedJobType;
              }

              return JobCard(
                jobTitle: title,
                organizationName: org,
                lastDateToApply: date,
                applyLink: link,
                jobType: type,
              );
            },
          ),
      ],
    );
  }
}
