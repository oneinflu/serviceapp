import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class ServiceSearchScreen extends StatefulWidget {
  const ServiceSearchScreen({super.key});

  @override
  State<ServiceSearchScreen> createState() => _ServiceSearchScreenState();
}

class _ServiceSearchScreenState extends State<ServiceSearchScreen> {
  List<dynamic> services = [];
  List<dynamic> filteredServices = [];
  bool isLoading = true;
  String? error;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _localityController = TextEditingController();
  bool isSearching = false; // true when showing backend search results

  // Filter and sort state
  String? selectedDistrict;
  String? selectedState;
  String? selectedCity;
  String? selectedPincode;
  String? selectedCountry;

  // Unique location values
  Set<String> districts = {};
  Set<String> states = {};
  Set<String> cities = {};
  Set<String> pincodes = {};
  Set<String> countries = {};

  @override
  void initState() {
    super.initState();
    fetchServices();
  }

  void extractUniqueLocations() {
    for (var service in services) {
      var location = service['location'];
      if (location == null) continue;
      if (location['district'] != null) districts.add(location['district']);
      if (location['state'] != null) states.add(location['state']);
      if (location['city'] != null) cities.add(location['city']);
      if (location['pincode'] != null) pincodes.add(location['pincode']);
      if (location['country'] != null) countries.add(location['country']);
    }
  }

  void applyFiltersAndSort() {
    filteredServices = List.from(services);

    // Apply search filter if text is entered
    if (_searchController.text.isNotEmpty) {
      final searchQuery = _searchController.text.toLowerCase();
      filteredServices =
          filteredServices.where((service) {
            String categoryName = '';
            if (service['categoryPrices'] != null && (service['categoryPrices'] as List).isNotEmpty) {
              categoryName = (service['categoryPrices'][0]['category']?['name'] ?? '').toString().toLowerCase();
            }
            final tags = service['tags'] as List? ?? [];
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
      filteredServices =
          filteredServices.where((service) {
            var location = service['location'];
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

    setState(() {});
  }

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
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

  Future<void> fetchServices() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
        isSearching = false;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        setState(() {
          error = AppLocalizations.of(context, 'please_login_search_services');
          isLoading = false;
        });
        return;
      }

      var response = await Dio().get(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/services',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        setState(() {
          services = response.data['data']['services'] ?? [];
          filteredServices = services;
          isLoading = false;
          extractUniqueLocations();
        });
      } else {
        setState(() {
          error = response.statusMessage ?? AppLocalizations.of(context, 'failed_to_fetch_services');
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

  /// Calls GET /api/services/search?keyword=...&locality=... for server-side search.
  /// Falls back to fetchServices() when both fields are empty.
  Future<void> searchServices() async {
    final keyword = _searchController.text.trim();
    final locality = _localityController.text.trim();

    if (keyword.isEmpty && locality.isEmpty) {
      fetchServices();
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
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/services/search',
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final results = List<dynamic>.from(response.data['data']['services'] ?? []);
        setState(() {
          filteredServices = results;
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

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.style; // Get the theme

    return theme.buildPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: theme.buildAppBar(context, AppLocalizations.of(context, 'service_search')),
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
                        labelText: AppLocalizations.of(context, 'search_for_services'),
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
                                                    AppLocalizations.of(context, 'filter_services'),
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
                      onSubmitted: (_) => searchServices(),
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
                            if (_searchController.text.isEmpty) fetchServices();
                          },
                        ),
                      ),
                      onSubmitted: (_) => searchServices(),
                    ),
                    const SizedBox(height: 12),
                    // Search button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: searchServices,
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
                                fetchServices();
                              },
                              child: const Text('Clear', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    // Active filters display (only shown when not in server-search mode)
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
                              Text('${AppLocalizations.of(context, 'error_prefix')} $error', style: theme.titleStyle),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: fetchServices,
                                style: theme.primaryButtonStyle(context),
                                child: Text(AppLocalizations.of(context, 'retry')),
                              ),
                            ],
                          ),
                        ),
                      )
                      : filteredServices.isEmpty
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
                              Text(
                                AppLocalizations.of(context, 'no_services_found'),
                                style: theme.titleStyle,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(context, 'try_adjusting_filters_search_terms'),
                                style: theme.subtitleStyle,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredServices.length,
                        itemBuilder: (context, index) {
                          final service = filteredServices[index];
                          final userObj = service['user'];
                          final isCompanyPost = service['isCompanyPost'] == true;
                          final companyObj = service['companyId'];
                          // Show company name for company posts, user name otherwise
                          final displayName = isCompanyPost && companyObj is Map && (companyObj['name'] ?? '').isNotEmpty
                              ? companyObj['name'] as String
                              : (userObj is Map) ? (userObj['name'] ?? AppLocalizations.of(context, 'unknown_user')) : AppLocalizations.of(context, 'unknown_user');
                          String categoryName = '';
                          if (service['categoryPrices'] != null && (service['categoryPrices'] as List).isNotEmpty) {
                            categoryName = service['categoryPrices'][0]['category']?['name'] ?? '';
                          }
                          final location = service['location'] ?? {};
                          final userPhone = service['user']?['phone'];

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
                                
                                if (service['tags'] != null && (service['tags'] as List).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        for (var tag in service['tags'])
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
        ),
      ),
    );
  }
}
