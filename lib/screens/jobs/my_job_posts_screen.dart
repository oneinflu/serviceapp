import 'package:app/screens/jobs/edit_job_post_screen.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_drawer.dart';

class MyJobPostsScreen extends StatefulWidget {
  const MyJobPostsScreen({super.key});

  @override
  State<MyJobPostsScreen> createState() => _MyJobPostsScreenState();
}

class _MyJobPostsScreenState extends State<MyJobPostsScreen> {
  List<dynamic> jobs = [];
  List<dynamic> filteredJobs = [];
  bool isLoading = true;
  String? error;
  final TextEditingController _searchController = TextEditingController();

  String? selectedCategory;
  String? selectedState;
  String? selectedCity;

  @override
  void initState() {
    super.initState();
    fetchMyJobs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchMyJobs() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      var response = await Dio().get(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/jobs/my-jobs',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        setState(() {
          jobs = response.data['data']['jobs'] ?? [];
          filteredJobs = jobs;
          isLoading = false;
        });
      }
    } catch (e) {
      // Enhanced error handling
      if (e is DioException) {
        setState(() {
          error = e.response?.data?['message'] ?? e.message ?? e.toString();
          isLoading = false;
        });
        print('Error response data: ${e.response?.data}');
        print('Error response headers: ${e.response?.headers}');
      } else {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  void applyFilters() {
    setState(() {
      filteredJobs =
          jobs.where((job) {
            final location = job['location'] ?? {};
            final categories = job['categories'] as List? ?? [];
            final searchQuery = _searchController.text.toLowerCase();

            // Check if any category matches the selected category
            bool categoryMatches =
                selectedCategory == null ||
                categories.any((cat) => cat['name'] == selectedCategory);

            return (searchQuery.isEmpty) &&
                categoryMatches &&
                (selectedState == null || location['state'] == selectedState) &&
                (selectedCity == null || location['city'] == selectedCity);
          }).toList();
    });
  }

  void _deleteJob(String jobId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await Dio().delete(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/jobs/$jobId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job post deleted successfully')),
        );
        fetchMyJobs(); // Refresh the list
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting job post: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.style;

    return theme.buildPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: theme.buildAppBar(context, 'My Job Posts'),
        drawer: const AppDrawer(),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: theme.searchDropdownDecoration(
                        labelText: 'Search jobs',
                        prefixIcon: Icons.search,
                        context: context,
                      ),
                      onChanged: (value) => applyFilters(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder:
                            (context) => StatefulBuilder(
                              builder:
                                  (context, setModalState) => Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Filter Jobs',
                                          style: theme.headingStyle(context),
                                        ),
                                        const SizedBox(height: 16),
                                        DropdownButtonFormField<String>(
                                          value: selectedCategory,
                                          decoration: theme.dropdownDecoration(
                                            labelText: 'Category',
                                            prefixIcon: Icons.category,
                                            context: context,
                                          ),
                                          items:
                                              jobs
                                                  .expand((job) {
                                                    final categories =
                                                        job['categories']
                                                            as List? ??
                                                        [];
                                                    return categories
                                                        .map(
                                                          (cat) =>
                                                              cat['name']
                                                                  as String?,
                                                        )
                                                        .whereType<String>();
                                                  })
                                                  .toSet()
                                                  .map(
                                                    (category) =>
                                                        DropdownMenuItem(
                                                          value: category,
                                                          child: Text(category),
                                                        ),
                                                  )
                                                  .toList(),
                                          onChanged: (value) {
                                            setModalState(
                                              () => selectedCategory = value,
                                            );
                                            applyFilters();
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                        DropdownButtonFormField<String>(
                                          value: selectedState,
                                          decoration: theme.dropdownDecoration(
                                            labelText: 'State',
                                            prefixIcon: Icons.location_on,
                                            context: context,
                                          ),
                                          items:
                                              jobs
                                                  .map(
                                                    (job) =>
                                                        job['location']?['state'],
                                                  )
                                                  .whereType<String>()
                                                  .toSet()
                                                  .map(
                                                    (state) => DropdownMenuItem(
                                                      value: state,
                                                      child: Text(state),
                                                    ),
                                                  )
                                                  .toList(),
                                          onChanged: (value) {
                                            setModalState(
                                              () => selectedState = value,
                                            );
                                            applyFilters();
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                        DropdownButtonFormField<String>(
                                          value: selectedCity,
                                          decoration: theme.dropdownDecoration(
                                            labelText: 'City',
                                            prefixIcon: Icons.location_city,
                                            context: context,
                                          ),
                                          items:
                                              jobs
                                                  .map(
                                                    (job) =>
                                                        job['location']?['city'],
                                                  )
                                                  .whereType<String>()
                                                  .toSet()
                                                  .map(
                                                    (city) => DropdownMenuItem(
                                                      value: city,
                                                      child: Text(city),
                                                    ),
                                                  )
                                                  .toList(),
                                          onChanged: (value) {
                                            setModalState(
                                              () => selectedCity = value,
                                            );
                                            applyFilters();
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  selectedCategory = null;
                                                  selectedState = null;
                                                  selectedCity = null;
                                                  filteredJobs = jobs;
                                                });
                                                Navigator.pop(context);
                                              },
                                              style: theme.secondaryButtonStyle(
                                                context,
                                              ),
                                              child: const Text(
                                                'Clear Filters',
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed:
                                                  () => Navigator.pop(context),
                                              style: theme.primaryButtonStyle(
                                                context,
                                              ),
                                              child: const Text('Apply'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                            ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  isLoading
                      ? Center(
                        child: theme.loadingIndicator(
                          color: Theme.of(context).primaryColor,
                        ),
                      )
                      : error != null
                      ? Center(
                        child: Text('Error: $error', style: theme.titleStyle),
                      )
                      : filteredJobs.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.work_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text('No job posts found', style: theme.titleStyle),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed:
                                  () =>
                                      Navigator.pushNamed(context, '/job-post'),
                              icon: const Icon(Icons.add),
                              label: const Text(
                                'Create Job Post',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: theme.primaryButtonStyle(context),
                            ),
                          ],
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: fetchMyJobs,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredJobs.length,
                          itemBuilder: (context, index) {
                            final job = filteredJobs[index];
                            final location = job['location'] ?? {};

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: theme.cardDecoration,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (job['isCompanyPost'] == true)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                        .primaryColor
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'Company Post',
                                                    style: TextStyle(
                                                      color:
                                                          Theme.of(
                                                            context,
                                                          ).primaryColor,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              const SizedBox(height: 8),
                                              // Display categories as chips
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  ...((job['categories']
                                                              as List?)
                                                          ?.map(
                                                            (category) => Chip(
                                                              label: Text(
                                                                category['name'] ??
                                                                    '',
                                                              ),
                                                              backgroundColor:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .primaryColor
                                                                      .withOpacity(
                                                                        0.1,
                                                                      ),
                                                              labelStyle: TextStyle(
                                                                color:
                                                                    Theme.of(
                                                                      context,
                                                                    ).primaryColor,
                                                              ),
                                                            ),
                                                          )
                                                          .toList() ??
                                                      []),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert),
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              // Navigate to edit page
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) =>
                                                          EditJobPostScreen(
                                                            job: job,
                                                          ),
                                                ),
                                              ).then((result) {
                                                // Refresh the list if edit was successful
                                                if (result == true) {
                                                  fetchMyJobs();
                                                }
                                              });
                                            } else if (value == 'delete') {
                                              // Show confirmation dialog
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (context) => AlertDialog(
                                                      title: const Text(
                                                        'Delete Job Post',
                                                      ),
                                                      content: const Text(
                                                        'Are you sure you want to delete this job post?',
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed:
                                                              () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                  ),
                                                          child: const Text(
                                                            'Cancel',
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                              context,
                                                            );
                                                            _deleteJob(
                                                              job['_id'],
                                                            );
                                                          },
                                                          style:
                                                              TextButton.styleFrom(
                                                                foregroundColor:
                                                                    Colors.red,
                                                              ),
                                                          child: const Text(
                                                            'Delete',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                              );
                                            }
                                          },
                                          itemBuilder:
                                              (context) => [
                                                const PopupMenuItem<String>(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.edit),
                                                      SizedBox(width: 8),
                                                      Text('Edit'),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuItem<String>(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'Delete',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${location['city'] ?? ''}, ${location['state'] ?? ''}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        for (var tag in job['tags'] ?? [])
                                          Chip(
                                            label: Text(tag),
                                            backgroundColor:
                                                Colors.blue.shade50,
                                            labelStyle: TextStyle(
                                              color: Colors.blue.shade700,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              // View details or statistics
                                            },
                                            icon: const Icon(Icons.visibility),
                                            label: const Text('View Details'),
                                            style: theme.secondaryButtonStyle(
                                              context,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              // Share job post
                                            },
                                            icon: const Icon(
                                              Icons.share,
                                              color: Colors.white,
                                            ),
                                            label: const Text(
                                              'Share',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            style: theme.primaryButtonStyle(
                                              context,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/job-post'),
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
