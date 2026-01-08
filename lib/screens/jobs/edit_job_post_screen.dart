import 'dart:convert';
import 'package:app/widgets/location_details_form.dart';
import 'package:drop_down_search_field/drop_down_search_field.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class EditJobPostScreen extends StatefulWidget {
  final Map<String, dynamic> job;

  const EditJobPostScreen({Key? key, required this.job}) : super(key: key);

  @override
  State<EditJobPostScreen> createState() => _EditJobPostScreenState();
}

class _EditJobPostScreenState extends State<EditJobPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  List<Map<String, dynamic>> _selectedCategories = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _filteredCategories = [];
  bool _isLoading = false;
  bool _isCompanyPost = false;
  String? _companyId;
  String _jobId = '';

  @override
  void initState() {
    super.initState();
    _jobId = widget.job['_id'];
    _isCompanyPost = widget.job['isCompanyPost'] ?? false;

    // Initialize location fields
    final location = widget.job['location'] ?? {};
    _districtController.text = location['district'] ?? '';
    _stateController.text = location['state'] ?? '';
    _cityController.text = location['city'] ?? '';
    _pincodeController.text = location['pincode'] ?? '';
    _countryController.text = location['country'] ?? '';

    // Fetch categories and other data
    _fetchCategories();
    _fetchCompanyId();
    _fetchJobDetails();
  }

  Future<void> _fetchJobDetails() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      var dio = Dio();
      var response = await dio.get(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/jobs/${_jobId}',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final jobData = response.data['data']['job'];

        // Set company post status
        setState(() {
          _isCompanyPost = jobData['isCompanyPost'] ?? false;

          // Set selected company ID if it's a company post
          if (_isCompanyPost && jobData['companyId'] != null) {
            _companyId = jobData['companyId'];
          }

          // Set selected categories
          if (jobData['categories'] != null) {
            _selectedCategories =
                (jobData['categories'] as List).map((cat) {
                  return {'id': cat['_id'], 'name': cat['name']};
                }).toList();
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching job details: $e')));
    }
  }

  Future<void> _fetchCompanyId() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = authProvider.userData;

    if (userData != null && userData['company'] != null) {
      setState(() {
        _companyId = userData['company']['_id'];
      });
    }
  }

  Future<void> _fetchCategories() async {
    try {
      var dio = Dio();
      var response = await dio.get(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/categories/type/Job',
      );

      if (response.statusCode == 200) {
        var data = response.data['data']['categories'] as List;
        setState(() {
          _categories =
              data
                  .map((cat) => {'id': cat['_id'], 'name': cat['name']})
                  .toList();
          _filteredCategories = List.from(_categories);
        });
      } else {
        print('Failed to fetch categories: ${response.statusMessage}');
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  void _removeCategory(Map<String, dynamic> category) {
    setState(() {
      _selectedCategories.removeWhere((cat) => cat['id'] == category['id']);
    });
  }

  Future<void> _updateJob() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one category')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = authProvider.userData;
    final token = authProvider.token;

    // Check if company post is selected but no company info is available
    if (_isCompanyPost) {
      final hasCompanyInfo =
          userData != null &&
          userData['company'] != null &&
          userData['company'].isNotEmpty;

      if (!hasCompanyInfo) {
        // Show dialog to add company info
        final result = await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Company Information Required'),
                content: const Text(
                  'You need to add company information before posting a company job.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Add Company Info'),
                  ),
                ],
              ),
        );

        if (result == true) {
          // Navigate to company info page
          final infoResult = await Navigator.pushNamed(
            context,
            '/company-info',
          );

          // If company info was added successfully, refresh user data and retry
          if (infoResult == true && mounted) {
            await authProvider.refreshUserData();
            _updateJob(); // Retry posting the job
          }
          return;
        } else {
          return; // User cancelled
        }
      }
    }

    // Check if company post is selected but no company ID is available
    if (_isCompanyPost && (_companyId == null || _companyId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company ID is required for company posts'),
        ),
      );
      return;
    }

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to update a Job')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Create the base request data
    final Map<String, dynamic> requestData = {
      "categoriesIds": _selectedCategories.map((cat) => cat['id']).toList(),
      "location": {
        "district": _districtController.text,
        "state": _stateController.text,
        "city": _cityController.text,
        "pincode": _pincodeController.text,
        "country": _countryController.text,
      },
      "isCompanyPost": _isCompanyPost,
    };

    // Add companyId if it's a company post
    if (_isCompanyPost && _companyId != null) {
      requestData["companyId"] = _companyId;
    }

    try {
      var dio = Dio();
      var response = await dio.put(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/jobs/${_jobId}',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job updated successfully!')),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${response.statusMessage}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.style;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ThemeStyle.iconColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Edit Job Post', style: theme.appBarTitleStyle(context)),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: theme.backgroundGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ThemeStyle.defaultPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),

                // Categories Section with Search
                theme.buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Categories', style: theme.titleStyle),
                      const SizedBox(height: 4),
                      Text(
                        'Add up to 10 categories for your job',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropDownSearchField<String>(
                              textFieldConfiguration: TextFieldConfiguration(
                                controller: _categoryController,
                                decoration: theme.searchDropdownDecoration(
                                  labelText: 'Search categories',
                                  prefixIcon: Icons.search,
                                  context: context,
                                ),
                              ),
                              suggestionsCallback: (pattern) {
                                return _filteredCategories
                                    .where(
                                      (category) => category['name']
                                          .toLowerCase()
                                          .contains(pattern.toLowerCase()),
                                    )
                                    .map((e) => e['name'] as String)
                                    .toList();
                              },
                              itemBuilder: (context, suggestion) {
                                return ListTile(title: Text(suggestion));
                              },
                              onSuggestionSelected: (suggestion) {
                                _categoryController.clear();
                                // Find the category by name
                                final selectedCategory = _categories.firstWhere(
                                  (category) => category['name'] == suggestion,
                                  orElse: () => {},
                                );

                                // Check if category already selected
                                final alreadySelected = _selectedCategories.any(
                                  (cat) => cat['id'] == selectedCategory['id'],
                                );

                                if (alreadySelected) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Category already selected',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                // Check max categories limit
                                if (_selectedCategories.length >= 10) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'You can only add up to 10 categories',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setState(() {
                                  _selectedCategories.add({
                                    'id': selectedCategory['id'],
                                    'name': selectedCategory['name'],
                                  });
                                });
                              },
                              isMultiSelectDropdown: false,
                              displayAllSuggestionWhenTap: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Selected Categories
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            _selectedCategories.map((category) {
                              return Chip(
                                label: Text(category['name']),
                                deleteIcon: const Icon(Icons.close),
                                onDeleted: () => _removeCategory(category),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Company Post Toggle
                theme.buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Post Type', style: theme.titleStyle),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Post as Company'),
                        subtitle: const Text(
                          'Enable to post this job under your company profile',
                        ),
                        value: _isCompanyPost,
                        onChanged: (value) {
                          setState(() {
                            _isCompanyPost = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Location Details
                theme.buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Location Details', style: theme.titleStyle),
                      const SizedBox(height: 16),
                      LocationDetailsForm(
                        districtController: _districtController,
                        stateController: _stateController,
                        cityController: _cityController,
                        pincodeController: _pincodeController,
                        countryController: _countryController,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _updateJob,
                  style: theme.primaryButtonStyle(context),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text('Update Job'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
