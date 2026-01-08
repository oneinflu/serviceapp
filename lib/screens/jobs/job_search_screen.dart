import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart'; // Add this import

class JobSearchScreen extends StatefulWidget {
  const JobSearchScreen({super.key});

  @override
  State<JobSearchScreen> createState() => _JobSearchScreenState();
}

class _JobSearchScreenState extends State<JobSearchScreen> {
  List<dynamic> jobs = [];
  List<dynamic> filteredJobs = [];
  bool isLoading = true;
  String? error;
  final TextEditingController _searchController =
      TextEditingController(); // Add search controller

  // Filter state
  String? selectedDistrict;
  String? selectedState;
  String? selectedCity;
  String? selectedPincode;
  String? selectedCountry;
  String sortOption = 'none';

  // Unique location values
  Set<String> districts = {};
  Set<String> states = {};
  Set<String> cities = {};
  Set<String> pincodes = {};
  Set<String> countries = {};

  @override
  void initState() {
    super.initState();
    fetchJobs();
  }

  void extractUniqueLocations() {
    for (var job in jobs) {
      var location = job['location'] ?? {};
      if (location['district'] != null) districts.add(location['district']);
      if (location['state'] != null) states.add(location['state']);
      if (location['city'] != null) cities.add(location['city']);
      if (location['pincode'] != null) pincodes.add(location['pincode']);
      if (location['country'] != null) countries.add(location['country']);
    }
  }

  Future<void> fetchJobs() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      var response = await Dio().get(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/jobs',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        setState(() {
          jobs = response.data['data']['jobs'];
          filteredJobs = jobs;
          isLoading = false;
          extractUniqueLocations(); // Extract location data after fetching
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void applyFiltersAndSort() {
    filteredJobs = List.from(jobs);

    // Apply search filter if text is entered
    if (_searchController.text.isNotEmpty) {
      final searchQuery = _searchController.text.toLowerCase();
      filteredJobs =
          filteredJobs.where((job) {
            final categoryName =
                job['category']?['name']?.toString().toLowerCase() ?? '';
            final tags = job['tags'] as List? ?? [];
            final tagsMatch = tags.any(
              (tag) => tag.toString().toLowerCase().contains(searchQuery),
            );
            return categoryName.contains(searchQuery) || tagsMatch;
          }).toList();
    }

    // Apply location filters
    filteredJobs =
        filteredJobs.where((job) {
          var location = job['location'] ?? {};
          return (selectedDistrict == null ||
                  location['district'] == selectedDistrict) &&
              (selectedState == null || location['state'] == selectedState) &&
              (selectedCity == null || location['city'] == selectedCity) &&
              (selectedPincode == null ||
                  location['pincode'] == selectedPincode) &&
              (selectedCountry == null ||
                  location['country'] == selectedCountry);
        }).toList();

    // Apply sorting if implemented in the future
    if (sortOption != 'none') {
      // Add sorting logic here if needed
    }

    setState(() {});
  }

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }

    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch phone call to $phoneNumber')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.style; // Get the theme

    return theme.buildPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: theme.buildAppBar(context, 'Job Search'),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: theme.buildCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      controller: _searchController,
                      decoration: theme.inputDecoration(
                        labelText: 'Search for jobs...',
                        prefixIcon: Icons.search,
                        context: context,
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                applyFiltersAndSort();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.filter_list),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder:
                                      (context) => StatefulBuilder(
                                        builder:
                                            (
                                              context,
                                              setModalState,
                                            ) => Container(
                                              padding: const EdgeInsets.all(24),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Filter Jobs',
                                                    style: theme.headingStyle(
                                                      context,
                                                    ),
                                                  ),
                                                  theme.buildDivider(),
                                                  Text(
                                                    'Location',
                                                    style: theme.titleStyle,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  DropdownButtonFormField<
                                                    String
                                                  >(
                                                    value: selectedState,
                                                    decoration: theme
                                                        .dropdownDecoration(
                                                          labelText: 'State',
                                                          prefixIcon:
                                                              Icons.location_on,
                                                          context: context,
                                                        ),
                                                    items:
                                                        states
                                                            .map(
                                                              (state) =>
                                                                  DropdownMenuItem(
                                                                    value:
                                                                        state,
                                                                    child: Text(
                                                                      state,
                                                                    ),
                                                                  ),
                                                            )
                                                            .toList(),
                                                    onChanged: (value) {
                                                      setModalState(
                                                        () =>
                                                            selectedState =
                                                                value,
                                                      );
                                                      applyFiltersAndSort();
                                                    },
                                                  ),
                                                  const SizedBox(height: 16),
                                                  DropdownButtonFormField<
                                                    String
                                                  >(
                                                    value: selectedCity,
                                                    decoration: theme
                                                        .dropdownDecoration(
                                                          labelText: 'City',
                                                          prefixIcon:
                                                              Icons
                                                                  .location_city,
                                                          context: context,
                                                        ),
                                                    items:
                                                        cities
                                                            .map(
                                                              (city) =>
                                                                  DropdownMenuItem(
                                                                    value: city,
                                                                    child: Text(
                                                                      city,
                                                                    ),
                                                                  ),
                                                            )
                                                            .toList(),
                                                    onChanged: (value) {
                                                      setModalState(
                                                        () =>
                                                            selectedCity =
                                                                value,
                                                      );
                                                      applyFiltersAndSort();
                                                    },
                                                  ),
                                                  const SizedBox(height: 16),
                                                  DropdownButtonFormField<
                                                    String
                                                  >(
                                                    value: selectedDistrict,
                                                    decoration: theme
                                                        .dropdownDecoration(
                                                          labelText: 'District',
                                                          prefixIcon: Icons.map,
                                                          context: context,
                                                        ),
                                                    items:
                                                        districts
                                                            .map(
                                                              (district) =>
                                                                  DropdownMenuItem(
                                                                    value:
                                                                        district,
                                                                    child: Text(
                                                                      district,
                                                                    ),
                                                                  ),
                                                            )
                                                            .toList(),
                                                    onChanged: (value) {
                                                      setModalState(
                                                        () =>
                                                            selectedDistrict =
                                                                value,
                                                      );
                                                      applyFiltersAndSort();
                                                    },
                                                  ),
                                                  const SizedBox(height: 24),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: ElevatedButton(
                                                          onPressed: () {
                                                            setState(() {
                                                              selectedState =
                                                                  null;
                                                              selectedCity =
                                                                  null;
                                                              selectedDistrict =
                                                                  null;
                                                              selectedPincode =
                                                                  null;
                                                              selectedCountry =
                                                                  null;
                                                            });
                                                            applyFiltersAndSort();
                                                            Navigator.pop(
                                                              context,
                                                            );
                                                          },
                                                          style: theme
                                                              .secondaryButtonStyle(
                                                                context,
                                                              ),
                                                          child: Text(
                                                            'Clear Filters',
                                                            style: TextStyle(
                                                              color:
                                                                  Theme.of(
                                                                    context,
                                                                  ).primaryColor,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Expanded(
                                                        child: ElevatedButton(
                                                          onPressed: () {
                                                            applyFiltersAndSort();
                                                            Navigator.pop(
                                                              context,
                                                            );
                                                          },
                                                          style: theme
                                                              .primaryButtonStyle(
                                                                context,
                                                              ),
                                                          child: const Text(
                                                            'Apply',
                                                          ),
                                                        ),
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
                      onChanged: (_) => applyFiltersAndSort(),
                    ),
                    // Active filters display
                    if (selectedState != null ||
                        selectedCity != null ||
                        selectedDistrict != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (selectedState != null)
                              Chip(
                                label: Text('State: $selectedState'),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () {
                                  setState(() => selectedState = null);
                                  applyFiltersAndSort();
                                },
                              ),
                            if (selectedCity != null)
                              Chip(
                                label: Text('City: $selectedCity'),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () {
                                  setState(() => selectedCity = null);
                                  applyFiltersAndSort();
                                },
                              ),
                            if (selectedDistrict != null)
                              Chip(
                                label: Text('District: $selectedDistrict'),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () {
                                  setState(() => selectedDistrict = null);
                                  applyFiltersAndSort();
                                },
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
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
                        child: theme.buildCard(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text('Error: $error', style: theme.titleStyle),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: fetchJobs,
                                style: theme.primaryButtonStyle(context),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                      : filteredJobs.isEmpty
                      ? Center(
                        child: theme.buildCard(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.search_off,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text('No jobs found', style: theme.titleStyle),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your filters or search terms',
                                style: theme.subtitleStyle,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredJobs.length,
                        itemBuilder: (context, index) {
                          final job = filteredJobs[index];
                          final user = job['user'] ?? {};
                          final location = job['location'] ?? {};
                          return theme.buildCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      decoration: theme.iconBoxDecoration(
                                        context,
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      child: Text(
                                        user['name']
                                                ?.substring(0, 1)
                                                .toUpperCase() ??
                                            '?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).primaryColor,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user['name'] ?? 'Unknown',
                                            style: theme.titleStyle,
                                          ),
                                          Text(
                                            job['category']?['name'] ??
                                                'No category',
                                            style: theme.subtitleStyle,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                theme.buildDivider(verticalPadding: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${location['city'] ?? ''}, ${location['state'] ?? ''}',
                                        style: theme.subtitleStyle,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (var tag in job['tags'] ?? [])
                                      Chip(
                                        label: Text(tag),
                                        backgroundColor: Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.1),
                                        labelStyle: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontSize: 12,
                                        ),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        () => _makePhoneCall(user['phone']),
                                    icon: const Icon(Icons.call),
                                    label: const Text('Call Now'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
