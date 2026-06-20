import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/service_subscription_sheet.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _localityController = TextEditingController();
  bool isSearching = false; // true when showing backend search results

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

  // Seeker state
  List<dynamic> seekers = [];
  bool isLoadingSeekers = false;
  String? errorSeekers;
  final TextEditingController _seekerSearchController = TextEditingController();
  final TextEditingController _seekerCityController = TextEditingController();

  static const String _pendingKeywordKey = 'pending_job_search_keyword';
  static const String _pendingLocalityKey = 'pending_job_search_locality';

  @override
  void initState() {
    super.initState();
    fetchJobs();
    fetchSeekers();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPendingSearch());
  }

  Future<void> _loadPendingSearch() async {
    final prefs = await SharedPreferences.getInstance();
    final keyword = prefs.getString(_pendingKeywordKey);
    final locality = prefs.getString(_pendingLocalityKey);
    if (keyword != null || locality != null) {
      if (keyword != null) _searchController.text = keyword;
      if (locality != null) _localityController.text = locality;
      await prefs.remove(_pendingKeywordKey);
      await prefs.remove(_pendingLocalityKey);
      searchJobs();
    }
  }

  Future<void> _checkSubscriptionThenSearch() async {
    final keyword = _searchController.text.trim();
    final locality = _localityController.text.trim();

    if (keyword.isEmpty && locality.isEmpty) {
      fetchJobs();
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      await Navigator.pushNamed(context, '/login');
      return;
    }

    final token = authProvider.token;

    // Persist search inputs so they survive the subscription flow
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingKeywordKey, keyword);
    await prefs.setString(_pendingLocalityKey, locality);

    try {
      final response = await Dio().get(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/subscriptions/my-subscriptions',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      bool isSubscribed = false;
      if (response.statusCode == 200) {
        final subscriptions = response.data['data']['subscriptions'] as List;
        isSubscribed = subscriptions.any(
          (sub) =>
              (sub['type'] == 'JOB_SEARCH' || sub['type'] == 'SERVICE_POST') &&
              DateTime.parse(sub['endDate']).isAfter(DateTime.now()),
        );
      }

      if (isSubscribed) {
        await prefs.remove(_pendingKeywordKey);
        await prefs.remove(_pendingLocalityKey);
        searchJobs();
      } else {
        if (!context.mounted) return;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          builder: (context) => ServiceSubscriptionSheet(
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
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context, 'error_prefix')}$e')),
      );
    }
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
        isSearching = false;
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
          extractUniqueLocations();
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  /// Calls GET /api/jobs/search?keyword=...&locality=... for server-side search.
  /// Falls back to fetchJobs() when both fields are empty.
  Future<void> searchJobs() async {
    final keyword = _searchController.text.trim();
    final locality = _localityController.text.trim();

    if (keyword.isEmpty && locality.isEmpty) {
      fetchJobs();
      return;
    }

    try {
      setState(() {
        isLoading = true;
        error = null;
        isSearching = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final Map<String, String> queryParams = {};
      if (keyword.isNotEmpty) queryParams['keyword'] = keyword;
      if (locality.isNotEmpty) queryParams['locality'] = locality;

      final response = await Dio().get(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/jobs/search',
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final results = List<dynamic>.from(response.data['data']['jobs'] ?? []);
        setState(() {
          filteredJobs = results;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> fetchSeekers() async {
    try {
      setState(() {
        isLoadingSeekers = true;
        errorSeekers = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      String query = _seekerSearchController.text.trim();
      String city = _seekerCityController.text.trim();
      
      String url = 'https://servicebackendnew-e2d8v.ondigitalocean.app/api/job-profiles/search?';
      if (query.isNotEmpty) url += 'keyword=${Uri.encodeComponent(query)}&';
      if (city.isNotEmpty) url += 'city=${Uri.encodeComponent(city)}&';

      var response = await Dio().get(
        url,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        setState(() {
          seekers = response.data['data']['profiles'] ?? [];
          isLoadingSeekers = false;
        });
      }
    } catch (e) {
      setState(() {
        errorSeekers = e.toString();
        isLoadingSeekers = false;
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
            String categoryName = '';
            if (job['categories'] != null && (job['categories'] as List).isNotEmpty) {
              categoryName = (job['categories'][0]['name'] ?? '').toString().toLowerCase();
            }
            final tags = job['tags'] as List? ?? [];
            final tagsMatch = tags.any(
              (tag) => tag.toString().toLowerCase().contains(searchQuery),
            );
            return categoryName.contains(searchQuery) || tagsMatch;
          }).toList();
    }

    // Apply location filters
    bool hasLocationFilter = selectedDistrict != null || 
                             selectedState != null || 
                             selectedCity != null || 
                             selectedPincode != null || 
                             selectedCountry != null;

    if (hasLocationFilter) {
      filteredJobs =
          filteredJobs.where((job) {
            var location = job['location'];
            if (location == null) return false;
            return (selectedDistrict == null ||
                    location['district'] == selectedDistrict) &&
                (selectedState == null || location['state'] == selectedState) &&
                (selectedCity == null || location['city'] == selectedCity) &&
                (selectedPincode == null ||
                    location['pincode'] == selectedPincode) &&
                (selectedCountry == null ||
                    location['country'] == selectedCountry);
          }).toList();
    }

    // Apply sorting if implemented in the future
    if (sortOption != 'none') {
      // Add sorting logic here if needed
    }

    setState(() {});
  }

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context, 'phone_number_not_available'))),
      );
      return;
    }

    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context, 'could_not_launch_phone_call')}$phoneNumber')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.style; // Get the theme

    return theme.buildPageBackground(
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: theme.buildAppBar(context, AppLocalizations.of(context, 'job_search')),
          body: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[600],
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.work_outline, size: 18),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              AppLocalizations.of(context, 'find_jobs'),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person_search_outlined, size: 18),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              AppLocalizations.of(context, 'find_seekers'),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildFindJobsTab(theme),
                    _buildFindJobSeekersTab(theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFindJobSeekersTab(dynamic theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: theme.buildCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _seekerSearchController,
                  decoration: theme.inputDecoration(
                    labelText: AppLocalizations.of(context, 'search_skills_hint'),
                    prefixIcon: Icons.search,
                    context: context,
                  ),
                  onSubmitted: (_) => fetchSeekers(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _seekerCityController,
                  decoration: theme.inputDecoration(
                    labelText: AppLocalizations.of(context, 'city_hint'),
                    prefixIcon: Icons.location_city,
                    context: context,
                  ),
                  onSubmitted: (_) => fetchSeekers(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: fetchSeekers,
                    style: theme.primaryButtonStyle(context),
                    child: Text(AppLocalizations.of(context, 'search_seekers')),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: isLoadingSeekers
              ? Center(child: theme.loadingIndicator(color: Theme.of(context).primaryColor))
              : errorSeekers != null
                  ? Center(child: Text('${AppLocalizations.of(context, 'error_prefix')}$errorSeekers'))
                  : seekers.isEmpty
                      ? Center(child: Text(AppLocalizations.of(context, 'no_seekers_found')))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: seekers.length,
                          itemBuilder: (context, index) {
                            var profile = seekers[index];
                            var user = profile['user'] ?? {};
                            var name = user['name'] ?? AppLocalizations.of(context, 'unknown');
                            var phone = user['phone'] ?? 'N/A';
                            
                            var categories = profile['categories'] as List? ?? [];
                            String categoryStr = categories.map((c) => c['name']).join(', ');
                            
                            var loc = profile['location'] ?? {};
                            String locStr = '${loc['city'] ?? ''}, ${loc['state'] ?? ''}'.trim();
                            if (locStr.startsWith(',')) locStr = locStr.substring(1).trim();

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: theme.buildCard(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                          child: Text(
                                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                                            style: TextStyle(
                                              color: Theme.of(context).primaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(name, style: theme.titleStyle),
                                              const SizedBox(height: 4),
                                              Text(
                                                categoryStr.isNotEmpty ? categoryStr : AppLocalizations.of(context, 'no_skills_listed'),
                                                style: TextStyle(
                                                  color: Theme.of(context).primaryColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            locStr.isNotEmpty ? locStr : AppLocalizations.of(context, 'location_not_available'), 
                                            style: theme.subtitleStyle,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _makePhoneCall(phone),
                                        icon: const Icon(Icons.phone),
                                        label: Text(AppLocalizations.of(context, 'contact_seeker')),
                                        style: theme.primaryButtonStyle(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        ),
        ),
      ],
    );
  }

  Widget _buildFindJobsTab(dynamic theme) {
    return Column(
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
                        labelText: AppLocalizations.of(context, 'search_jobs_hint'),
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
                                                    AppLocalizations.of(context, 'filter_jobs'),
                                                    style: theme.headingStyle(
                                                      context,
                                                    ),
                                                  ),
                                                  theme.buildDivider(),
                                                  Text(
                                                    AppLocalizations.of(context, 'location'),
                                                    style: theme.titleStyle,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  DropdownButtonFormField<
                                                    String
                                                  >(
                                                    value: selectedState,
                                                    decoration: theme
                                                        .dropdownDecoration(
                                                          labelText: AppLocalizations.of(context, 'state'),
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
                                                          labelText: AppLocalizations.of(context, 'city'),
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
                                                          labelText: AppLocalizations.of(context, 'district'),
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
                                                            AppLocalizations.of(context, 'clear_filters'),
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
                                                          child: Text(
                                                            AppLocalizations.of(context, 'apply'),
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
                      onChanged: (_) {
                        if (!isSearching) applyFiltersAndSort();
                      },
                      onSubmitted: (_) => _checkSubscriptionThenSearch(),
                    ),
                    const SizedBox(height: 12),
                    // Locality field
                    TextField(
                      controller: _localityController,
                      decoration: theme.inputDecoration(
                        labelText: AppLocalizations.of(context, 'locality'),
                        prefixIcon: Icons.location_on_outlined,
                        context: context,
                        hintText: 'e.g. Kankanadi',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _localityController.clear();
                            if (_searchController.text.isEmpty) fetchJobs();
                          },
                        ),
                      ),
                      onSubmitted: (_) => _checkSubscriptionThenSearch(),
                    ),
                    const SizedBox(height: 12),
                    // Search button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _checkSubscriptionThenSearch,
                        icon: const Icon(Icons.search, color: Colors.white),
                        label: Text(
                          AppLocalizations.of(context, 'search'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        style: theme.primaryButtonStyle(context),
                      ),
                    ),
                    if (isSearching)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Showing results from server search',
                                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                _localityController.clear();
                                fetchJobs();
                              },
                              child: const Text('Clear', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    // Active filters display
                    if (!isSearching && (selectedState != null ||
                        selectedCity != null ||
                        selectedDistrict != null))
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (selectedState != null)
                              Chip(
                                label: Text('${AppLocalizations.of(context, 'state')}: $selectedState'),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () {
                                  setState(() => selectedState = null);
                                  applyFiltersAndSort();
                                },
                              ),
                            if (selectedCity != null)
                              Chip(
                                label: Text('${AppLocalizations.of(context, 'city')}: $selectedCity'),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () {
                                  setState(() => selectedCity = null);
                                  applyFiltersAndSort();
                                },
                              ),
                            if (selectedDistrict != null)
                              Chip(
                                label: Text('${AppLocalizations.of(context, 'district')}: $selectedDistrict'),
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
                              Text('${AppLocalizations.of(context, 'error_prefix')}$error', style: theme.titleStyle),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: fetchJobs,
                                style: theme.primaryButtonStyle(context),
                                child: Text(AppLocalizations.of(context, 'retry')),
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
                              Text(AppLocalizations.of(context, 'no_jobs_found'), style: theme.titleStyle),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(context, 'adjust_filters_hint'),
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
                          final userObj = job['user'];
                          final isCompanyPost = job['isCompanyPost'] == true;
                          final companyObj = job['companyId'];
                          // Show company name for company posts, user name otherwise
                          final displayName = isCompanyPost && companyObj is Map && (companyObj['name'] ?? '').isNotEmpty
                              ? companyObj['name'] as String
                              : (userObj is Map) ? (userObj['name'] ?? 'Unknown User') : 'Unknown User';
                          String categoryName = '';
                          if (job['categories'] != null && (job['categories'] as List).isNotEmpty) {
                            categoryName = job['categories'][0]['name'] ?? '';
                          }
                          final location = job['location'] ?? {};
                          final userPhone = (userObj is Map) ? userObj['phone'] : null;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    categoryName,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                if (isCompanyPost)
                                                  Padding(
                                                    padding: const EdgeInsets.only(right: 4),
                                                    child: Icon(Icons.business, size: 14, color: Colors.grey[600]),
                                                  ),
                                                Expanded(
                                                  child: Text(
                                                    displayName,
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      color: Colors.grey[700],
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on,
                                                  size: 14,
                                                  color: Colors.grey[500],
                                                ),
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
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[500],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                if (job['tags'] != null && (job['tags'] as List).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        for (var tag in job['tags'])
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey[300]!),
                                            ),
                                            child: Text(
                                              tag.toString(),
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  
                                // Call Button area
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: Colors.grey.withOpacity(0.1)),
                                    ),
                                  ),
                                  child: TextButton.icon(
                                    onPressed: () => _makePhoneCall(userPhone),
                                    icon: Icon(Icons.call, color: Theme.of(context).primaryColor),
                                    label: Text(
                                      AppLocalizations.of(context, 'call_now'),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(20),
                                          bottomRight: Radius.circular(20),
                                        ),
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
        );
  }
}
