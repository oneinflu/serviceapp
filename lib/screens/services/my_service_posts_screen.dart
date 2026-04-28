import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_drawer.dart';
import 'package:app/screens/services/edit_service_post_screen.dart';
import '../../l10n/app_localizations.dart';

class MyServicePostsScreen extends StatefulWidget {
  const MyServicePostsScreen({super.key});

  @override
  State<MyServicePostsScreen> createState() => _MyServicePostsScreenState();
}

class _MyServicePostsScreenState extends State<MyServicePostsScreen> {
  List<dynamic> services = [];
  List<dynamic> filteredServices = [];
  bool isLoading = true;
  String? error;
  final TextEditingController _searchController = TextEditingController();

  String? selectedCategory;
  String? selectedState;
  String? selectedCity;
  String? selectedCompanyFilter;

  @override
  void initState() {
    super.initState();
    fetchMyServices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchMyServices() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      var response = await Dio().get(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/services/my-services',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        setState(() {
          services = response.data['data']['services'] ?? [];
          filteredServices = services;
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

  void applyFilters() {
    setState(() {
      filteredServices =
          services.where((service) {
            final location = service['location'] ?? {};
            final category = service['category'] ?? {};
            final searchQuery = _searchController.text.toLowerCase();
            final isCompanyPost = service['isCompanyPost'] ?? false;

            // Add company post filter
            bool matchesCompanyFilter = true;
            if (selectedCompanyFilter != null) {
              if (selectedCompanyFilter == 'company' && !isCompanyPost) {
                matchesCompanyFilter = false;
              } else if (selectedCompanyFilter == 'personal' && isCompanyPost) {
                matchesCompanyFilter = false;
              }
            }

            return (searchQuery.isEmpty ||
                    category['name'].toLowerCase().contains(searchQuery)) &&
                (selectedCategory == null ||
                    category['name'] == selectedCategory) &&
                (selectedState == null || location['state'] == selectedState) &&
                (selectedCity == null || location['city'] == selectedCity) &&
                matchesCompanyFilter;
          }).toList();
    });
  }

  void _deleteService(String serviceId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await Dio().delete(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/services/$serviceId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context, 'service_deleted_success'))),
        );
        fetchMyServices(); // Refresh the list
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context, 'error_deleting_service')}: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.style;

    return theme.buildPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: theme.buildAppBar(context, AppLocalizations.of(context, 'my_service_posts')),
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
                        labelText: AppLocalizations.of(context, 'search_services'),
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
                                          AppLocalizations.of(context, 'filter_services'),
                                          style: theme.headingStyle(context),
                                        ),
                                        const SizedBox(height: 16),
                                        // Add company filter dropdown
                                        DropdownButtonFormField<String>(
                                          value: selectedCompanyFilter,
                                          decoration: theme.dropdownDecoration(
                                            labelText: AppLocalizations.of(context, 'post_type'),
                                            prefixIcon: Icons.business,
                                            context: context,
                                          ),
                                          items: [
                                            DropdownMenuItem(
                                              value: null,
                                              child: Text(AppLocalizations.of(context, 'all_posts')),
                                            ),
                                            DropdownMenuItem(
                                              value: 'personal',
                                              child: Text(AppLocalizations.of(context, 'personal_posts')),
                                            ),
                                            DropdownMenuItem(
                                              value: 'company',
                                              child: Text(AppLocalizations.of(context, 'company_posts')),
                                            ),
                                          ],
                                          onChanged: (value) {
                                            setModalState(
                                              () =>
                                                  selectedCompanyFilter = value,
                                            );
                                            applyFilters();
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                        DropdownButtonFormField<String>(
                                          value: selectedCategory,
                                          decoration: theme.dropdownDecoration(
                                            labelText: AppLocalizations.of(context, 'category'),
                                            prefixIcon: Icons.category,
                                            context: context,
                                          ),
                                          items:
                                              services
                                                  .map(
                                                    (service) =>
                                                        service['category']?['name'],
                                                  )
                                                  .whereType<String>()
                                                  .toSet()
                                                  .map(
                                                    (category) =>
                                                        DropdownMenuItem<
                                                          String
                                                        >(
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
                                              services
                                                  .map(
                                                    (service) =>
                                                        service['location']?['state'],
                                                  )
                                                  .whereType<String>()
                                                  .toSet()
                                                  .map(
                                                    (state) => DropdownMenuItem<
                                                      String
                                                    >(
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
                                              services
                                                  .map(
                                                    (service) =>
                                                        service['location']?['city'],
                                                  )
                                                  .whereType<String>()
                                                  .toSet()
                                                  .map(
                                                    (city) => DropdownMenuItem<
                                                      String
                                                    >(
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
                                                  selectedCompanyFilter = null;
                                                  filteredServices = services;
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
                        child: Text('${AppLocalizations.of(context, 'error_prefix')} $error', style: theme.titleStyle),
                      )
                      : filteredServices.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.handyman_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context, 'no_service_posts_found'),
                              style: theme.titleStyle,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed:
                                  () => Navigator.pushNamed(
                                    context,
                                    '/service-post',
                                  ),
                              icon: const Icon(Icons.add),
                              label: Text(AppLocalizations.of(context, 'create_service_post')),
                              style: theme.primaryButtonStyle(context),
                            ),
                          ],
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: fetchMyServices,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredServices.length,
                          itemBuilder: (context, index) {
                            final service = filteredServices[index];
                            final location = service['location'] ?? {};
                            final isCompanyPost = service['isCompanyPost'] ?? false;
                            final companyId = service['companyId'];

                            String categoryName = '';
                            if (service['categoryPrices'] != null && (service['categoryPrices'] as List).isNotEmpty) {
                              categoryName = service['categoryPrices'][0]['category']?['name'] ?? '';
                            }
                            if (categoryName.isEmpty) {
                              categoryName = service['category']?['name'] ?? '';
                            }

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
                                              Text(
                                                categoryName.isNotEmpty
                                                    ? categoryName
                                                    : AppLocalizations.of(context, 'untitled_service'),
                                                style: theme
                                                    .headingStyle(context)
                                                    .copyWith(fontSize: 18),
                                              ),
                                              // Display company badge if it's a company post
                                              if (isCompanyPost)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                    top: 4,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.business,
                                                        size: 14,
                                                        color: Colors.blue,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        AppLocalizations.of(context, 'company_post'),
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors
                                                                  .blue
                                                                  .shade700,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
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
                                                          EditServicePostScreen(
                                                            service: service,
                                                          ),
                                                ),
                                              ).then((result) {
                                                // Refresh the list if edit was successful
                                                if (result == true) {
                                                  fetchMyServices();
                                                }
                                              });
                                            } else if (value == 'delete') {
                                              // Show confirmation dialog
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (context) => AlertDialog(
                                                      title: Text(
                                                        AppLocalizations.of(context, 'delete_service_post'),
                                                      ),
                                                      content: Text(
                                                        AppLocalizations.of(context, 'delete_service_post_desc'),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed:
                                                              () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                  ),
                                                          child: Text(
                                                            AppLocalizations.of(context, 'cancel'),
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                              context,
                                                            );
                                                            _deleteService(
                                                              service['_id'],
                                                            );
                                                          },
                                                          style:
                                                              TextButton.styleFrom(
                                                                foregroundColor:
                                                                    Colors.red,
                                                              ),
                                                          child: Text(
                                                            AppLocalizations.of(context, 'delete'),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                              );
                                            }
                                          },
                                          itemBuilder:
                                              (context) => [
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
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        AppLocalizations.of(context, 'delete'),
                                                        style: const TextStyle(
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
                                        for (var tag in service['tags'] ?? [])
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
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          // Share service post
                                        },
                                        icon: const Icon(
                                          Icons.share,
                                          color: Colors.white,
                                        ),
                                        label: Text(
                                          AppLocalizations.of(context, 'share'),
                                          style: const TextStyle(
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
                              ),
                            );
                          },
                        ),
                      ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/service-post'),
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
