import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'job_card.dart';

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

      setState(() {
        govtJobs = fetchedGovt;
        userJobs = fetchedUser;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching jobs: $e');
    }
  }

  List<dynamic> getFilteredJobs() {
    if (selectedJobType == 'Govt Jobs' || selectedJobType == 'Semi Govt Jobs') {
      return govtJobs
          .where((job) => job['jobType'].toString().trim() == selectedJobType.trim())
          .toList();
    } else if (selectedJobType == 'Private Jobs') {
      return userJobs
          .where((job) => job['company'] != null)
          .toList();
    } else if (selectedJobType == 'Individual Jobs') {
      return userJobs
          .where((job) => job['company'] == null)
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
                
                final company = job['company'];
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
