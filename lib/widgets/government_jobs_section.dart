import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
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
    return Container(
      margin: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (bool selected) {
          if (selected) {
            setState(() {
              selectedJobType = label;
              print('Selected job type: $label'); // Debug print
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredJobs = getFilteredJobs();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Government Jobs',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: jobTypes.map((type) => _buildJobTypePill(type)).toList(),
          ),
        ),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (filteredJobs.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(child: Text('No jobs found for $selectedJobType')),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
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
