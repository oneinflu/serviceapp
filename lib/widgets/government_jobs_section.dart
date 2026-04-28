import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
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
    'PSU Jobs',
    'MSME Jobs',
  ];
  String selectedJobType = 'Govt Jobs';
  List<dynamic> jobs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchJobs();
  }

  Future<void> fetchJobs() async {
    try {
      var dio = Dio();
      var response = await dio.get(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/government-jobs',
      );

      if (response.statusCode == 200) {
        setState(() {
          jobs = response.data['data']['governmentJobs'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching jobs: $e');
    }
  }

  List<dynamic> getFilteredJobs() {
    // Debug print to check job types
    print('Selected type: $selectedJobType');
    print('Available jobs: ${jobs.map((job) => job['jobType']).toList()}');

    return jobs
        .where(
          (job) => job['jobType'].toString().trim() == selectedJobType.trim(),
        )
        .toList();
  }

  Widget _buildJobTypePill(String label) {
    final bool isSelected = selectedJobType == label;
    final theme = AppTheme.style;
    
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
            itemBuilder:
                (context, index) => JobCard(
                  jobTitle: filteredJobs[index]['jobTitle'],
                  organizationName: filteredJobs[index]['organizationName'],
                  lastDateToApply: DateTime.parse(
                    filteredJobs[index]['lastDateToApply'],
                  ),
                  applyLink: filteredJobs[index]['applyLink'],
                  jobType: filteredJobs[index]['jobType'],
                ),
          ),
      ],
    );
  }
}
