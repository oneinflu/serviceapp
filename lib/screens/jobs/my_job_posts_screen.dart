import 'package:app/screens/jobs/edit_job_post_screen.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_drawer.dart';
import '../../l10n/app_localizations.dart';

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
            // API returns categories as an array of objects
            final categories = job['categories'] as List? ?? [];
            final searchQuery = _searchController.text.toLowerCase();

            bool categoryMatches =
                selectedCategory == null ||
                categories.any((cat) => cat['name'] == selectedCategory);

            bool searchMatches = searchQuery.isEmpty ||
                categories.any((cat) =>
                    (cat['name'] ?? '').toString().toLowerCase().contains(searchQuery));

            return searchMatches &&
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context, 'job_deleted_success'))),
        );
        fetchMyJobs(); // Refresh the list
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context, 'error_deleting_job')}: ${e.toString()}')),
      );
    }
  }

  void _cloneJob(String jobId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await Dio().post(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/jobs/$jobId/clone',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context, 'job_cloned_success'))),
        );
        fetchMyJobs(); // Refresh the list
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context, 'error_cloning_job')}: ${e.toString()}')),
      );
    }
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.green;
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'expired':
        return Colors.red;
      case 'closed':
      case 'inactive':
        return Colors.grey;
      default:
        return Theme.of(context).primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.style;

    return theme.buildPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: theme.buildAppBar(context, AppLocalizations.of(context, 'my_job_posts')),
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
                        labelText: AppLocalizations.of(context, 'search_jobs_hint'),
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
                                          AppLocalizations.of(context, 'filter_jobs'),
                                          style: theme.headingStyle(context),
                                        ),
                                        const SizedBox(height: 16),
                                        DropdownButtonFormField<String>(
                                          value: selectedCategory,
                                          decoration: theme.dropdownDecoration(
                                            labelText: AppLocalizations.of(context, 'category'),
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
                                            labelText: AppLocalizations.of(context, 'state'),
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
                                            labelText: AppLocalizations.of(context, 'city'),
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
                                              child: Text(
                                                AppLocalizations.of(context, 'clear_filters'),
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed:
                                                  () => Navigator.pop(context),
                                              style: theme.primaryButtonStyle(
                                                context,
                                              ),
                                              child: Text(AppLocalizations.of(context, 'apply')),
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
                        child: Text('${AppLocalizations.of(context, 'error_prefix')}$error', style: theme.titleStyle),
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
                            Text(AppLocalizations.of(context, 'no_job_posts_found'), style: theme.titleStyle),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed:
                                  () =>
                                      Navigator.pushNamed(context, '/job-post'),
                              icon: const Icon(Icons.add),
                              label: Text(
                                AppLocalizations.of(context, 'create_job_post'),
                                style: const TextStyle(color: Colors.white),
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
                                              Row(
                                                children: [
                                                  if (job['isCompanyPost'] == true)
                                                    Padding(
                                                      padding: const EdgeInsets.only(right: 8.0),
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          AppLocalizations.of(context, 'company_post'),
                                                          style: TextStyle(
                                                            color: Theme.of(context).primaryColor,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: _getStatusColor(job['status']).withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      AppLocalizations.of(context, (job['status']?.toString().toLowerCase()) ?? 'active').toUpperCase(),
                                                      style: TextStyle(
                                                        color: _getStatusColor(job['status']),
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              // Display categories as chips
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  ...((job['categories'] as List?)
                                                          ?.map(
                                                            (category) => Chip(
                                                              label: Text(
                                                                category['name'] ?? '',
                                                              ),
                                                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                                              labelStyle: TextStyle(
                                                                color: Theme.of(context).primaryColor,
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
                                                  builder: (context) => EditJobPostScreen(job: job),
                                                ),
                                              ).then((result) {
                                                // Refresh the list if edit was successful
                                                if (result == true) {
                                                  fetchMyJobs();
                                                }
                                              });
                                            } else if (value == 'clone') {
                                              _cloneJob(job['_id']);
                                            } else if (value == 'delete') {
                                              // Show confirmation dialog
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: Text(AppLocalizations.of(context, 'delete_job_post_title')),
                                                  content: Text(AppLocalizations.of(context, 'delete_job_post_desc')),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context),
                                                      child: Text(AppLocalizations.of(context, 'cancel')),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                        _deleteJob(job['_id']);
                                                      },
                                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                                      child: Text(AppLocalizations.of(context, 'delete')),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            PopupMenuItem<String>(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.edit),
                                                  const SizedBox(width: 8),
                                                  Text(AppLocalizations.of(context, 'edit')),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem<String>(
                                              value: 'clone',
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.copy),
                                                  const SizedBox(width: 8),
                                                  Text(AppLocalizations.of(context, 'clone')),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem<String>(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.delete, color: Colors.red),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    AppLocalizations.of(context, 'delete'),
                                                    style: const TextStyle(color: Colors.red),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Full location: address → taluk → district → city → state → pincode
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            [
                                              if ((location['address'] ?? '').isNotEmpty) location['address'],
                                              if ((location['taluk'] ?? '').isNotEmpty) location['taluk'],
                                              if ((location['district'] ?? '').isNotEmpty) location['district'],
                                              if ((location['city'] ?? '').isNotEmpty) location['city'],
                                              if ((location['state'] ?? '').isNotEmpty) location['state'],
                                              if ((location['pincode'] ?? '').isNotEmpty) location['pincode'],
                                            ].join(', '),
                                            style: const TextStyle(color: Colors.grey),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    // Expiry date badge
                                    if (job['expiresAt'] != null)
                                      Builder(builder: (ctx) {
                                        final expiresAt = DateTime.tryParse(job['expiresAt']);
                                        if (expiresAt == null) return const SizedBox.shrink();
                                        final now = DateTime.now();
                                        final daysLeft = expiresAt.difference(now).inDays;
                                        final isExpired = expiresAt.isBefore(now);
                                        final isNearExpiry = !isExpired && daysLeft <= 3;
                                        final expiryColor = isExpired ? Colors.red : isNearExpiry ? Colors.orange : Colors.green;
                                        final expiryText = isExpired ? 'Expired' : 'Expires in $daysLeft day${daysLeft == 1 ? '' : 's'}';
                                        return Row(
                                          children: [
                                            Icon(Icons.timer_outlined, size: 14, color: expiryColor),
                                            const SizedBox(width: 4),
                                            Text(expiryText, style: TextStyle(fontSize: 12, color: expiryColor, fontWeight: FontWeight.w600)),
                                          ],
                                        );
                                      }),
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
