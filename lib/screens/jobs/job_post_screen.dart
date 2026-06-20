import 'dart:convert';
import 'package:app/widgets/location_details_form.dart';
import 'package:drop_down_search_field/drop_down_search_field.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/service_subscription_sheet.dart';
import '../../l10n/app_localizations.dart';

class JobPostScreen extends StatefulWidget {
  const JobPostScreen({Key? key}) : super(key: key);

  @override
  State<JobPostScreen> createState() => _JobPostScreenState();
}

class _JobPostScreenState extends State<JobPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _localityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  List<Map<String, dynamic>> _selectedCategories = [];
  List<Map<String, dynamic>> _categories = [];
  // Remove this line
  // List<Map<String, dynamic>> _filteredCategories = [];
  bool _isLoading = false;
  bool _isCompanyPost = false;
  String? _companyId; // This would be populated from user data or selection

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshUserData();
    _fetchCategories();
    _fetchCompanyId();
  }

  Future<void> _fetchCompanyId() async {
    // This is a placeholder - in a real app, you would fetch the company ID
    // from the user's profile or from a company selection screen
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = authProvider.userData;

    if (userData != null && userData['company'] != null) {
      setState(() {
        _companyId = userData['company']['_id'];
        if (_isCompanyPost) {
          _autofillCompanyLocation();
        }
      });
    }
  }

  void _autofillCompanyLocation() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = authProvider.userData;

    if (userData != null &&
        userData['company'] != null &&
        userData['company']['location'] != null) {
      final loc = userData['company']['location'];
      setState(() {
        _districtController.text = loc['district'] ?? '';
        _stateController.text = loc['state'] ?? '';
        _cityController.text = loc['city'] ?? '';
        _pincodeController.text = loc['pincode'] ?? '';
        _countryController.text = loc['country'] ?? 'INDIA';
        _addressController.text = loc['address'] ?? '';
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

  void _showSubscriptionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ThemeStyle.cardBorderRadius),
        ),
      ),
      builder:
          (context) => ServiceSubscriptionSheet(
            serviceType: 'Job Post',
            price: 500,
            benefits: [
              'Post unlimited jobs for 365 days',
              'Business profile customization',
              'Priority listing in search results',
              'Analytics and insights',
              'Add up to 10 categories per job',
              'Includes access to Job & Service search feature',
            ],
            isPremium: true,
          ),
    );
  }

  // In the _postJob method, modify the company post check:
  Future<void> _postJob() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context, 'select_category_hint'))),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context, 'setup_company_profile_first')),
            action: SnackBarAction(
              label: AppLocalizations.of(context, 'add'),
              onPressed: () => Navigator.pushNamed(context, '/company-info'),
            ),
          ),
        );
        return;
      }
    }

    // Check if company post is selected but no company ID is available
    if (_isCompanyPost && (_companyId == null || _companyId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context, 'company_id_required')),
        ),
      );
      return;
    }

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context, 'login_to_post'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Send the raw locality string — the backend resolves it to full location.
    final Map<String, dynamic> requestData = {
      "categoriesIds": _selectedCategories.map((cat) => cat['id']).toList(),
      "isCompanyPost": _isCompanyPost,
    };

    if (_isCompanyPost) {
      requestData["location"] = {
        "address": _addressController.text.trim(),
        "district": _districtController.text.trim(),
        "state": _stateController.text.trim(),
        "city": _cityController.text.trim(),
        "pincode": _pincodeController.text.trim(),
        "country": _countryController.text.trim(),
      };
      if (_companyId != null) {
        requestData["companyId"] = _companyId;
      }
    } else {
      requestData["locality"] = _localityController.text.trim();
    }

    try {
      var dio = Dio();
      var response = await dio.post(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/jobs',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: jsonEncode(requestData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context, 'job_posted_success'))),
        );
        _formKey.currentState?.reset();
        setState(() {
          _selectedCategories = [];
          _categoryController.clear();
          _isCompanyPost = false;
        });
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context, 'failed_prefix')}${response.statusMessage}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context, 'error_prefix')}$e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.style;
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData;

    // Set max categories to 10 (no subscription check needed as per requirements)
    final int maxCategories = 10;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ThemeStyle.iconColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(AppLocalizations.of(context, 'post_a_job'), style: theme.appBarTitleStyle(context)),
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
                      Text(AppLocalizations.of(context, 'categories_title'), style: theme.titleStyle),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context, 'categories_desc'),
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
                                  labelText: AppLocalizations.of(context, 'search_select_category'),
                                  prefixIcon: Icons.search,
                                  context: context,
                                  hintText: AppLocalizations.of(context, 'select_category'),
                                ),
                              ),
                              displayAllSuggestionWhenTap: true,
                              isMultiSelectDropdown: false,
                              suggestionsCallback: (pattern) {
                                return _categories
                                    .where(
                                      (cat) =>
                                          cat['name']
                                              .toString()
                                              .toLowerCase()
                                              .contains(
                                                pattern.toLowerCase(),
                                              ) &&
                                          !_selectedCategories.any(
                                            (selected) =>
                                                selected['id'] == cat['id'],
                                          ),
                                    )
                                    .map((cat) => cat['name'] as String)
                                    .toList();
                              },
                              itemBuilder: (context, suggestion) {
                                return ListTile(title: Text(suggestion));
                              },
                              onSuggestionSelected: (suggestion) {
                                // Find the category based on the selected name
                                final selectedCategory = _categories.firstWhere(
                                  (cat) => cat['name'] == suggestion,
                                  orElse: () => {'id': null, 'name': ''},
                                );

                                if (selectedCategory['id'] != null &&
                                    !_selectedCategories.any(
                                      (cat) =>
                                          cat['id'] == selectedCategory['id'],
                                    )) {
                                  // Check if user is within the maximum category limit
                                  if (_selectedCategories.length <
                                      maxCategories) {
                                    setState(() {
                                      _selectedCategories.add(selectedCategory);
                                      _categoryController.clear();
                                    });
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppLocalizations.of(context, 'max_categories_allowed'),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed:
                                _selectedCategories.length >= maxCategories
                                    ? null // Disable button when max categories reached
                                    : () {
                                      if (_categoryController.text.isNotEmpty) {
                                        // Find the category based on the text
                                        final categoryName =
                                            _categoryController.text.trim();
                                        final selectedCategory = _categories
                                            .firstWhere(
                                              (cat) =>
                                                  cat['name'] == categoryName,
                                              orElse:
                                                  () => {
                                                    'id': null,
                                                    'name': '',
                                                  },
                                            );

                                        if (selectedCategory['id'] != null &&
                                            !_selectedCategories.any(
                                              (cat) =>
                                                  cat['id'] ==
                                                  selectedCategory['id'],
                                            )) {
                                          setState(() {
                                            _selectedCategories.add(
                                              selectedCategory,
                                            );
                                            _categoryController.clear();
                                          });
                                        }
                                      }
                                    },
                            style: theme
                                .primaryButtonStyle(context)
                                .copyWith(
                                  padding: MaterialStateProperty.all(
                                    const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 24,
                                    ),
                                  ),
                                  minimumSize: MaterialStateProperty.all(
                                    const Size(0, 0),
                                  ),
                                ),
                            child: Text(
                              AppLocalizations.of(context, 'add'),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      if (_selectedCategories.isNotEmpty)
                        const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            _selectedCategories.map((category) {
                              return Chip(
                                label: Text(category['name']),
                                deleteIcon: const Icon(Icons.close, size: 18),
                                onDeleted: () => _removeCategory(category),
                                backgroundColor: Colors.grey[200],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              );
                            }).toList(),
                      ),
                      if (_selectedCategories.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${_selectedCategories.length}/$maxCategories ${AppLocalizations.of(context, 'categories_count')}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Company Post Toggle
                theme.buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context, 'company_post'), style: theme.titleStyle),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context, 'is_company_post'),
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: Text(AppLocalizations.of(context, 'post_as_company')),
                        value: _isCompanyPost,
                        onChanged: (value) {
                          setState(() {
                            _isCompanyPost = value;
                            if (value) {
                              _autofillCompanyLocation();
                            }
                          });
                        },
                        activeColor: Theme.of(context).primaryColor,
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_isCompanyPost)
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            final userData = authProvider.userData;
                            final hasCompany = userData != null && 
                                              userData['company'] != null && 
                                              userData['company']['_id'] != null;

                            if (hasCompany) {
                              return Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.business,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${AppLocalizations.of(context, 'posting_as')} ${userData!['company']['name']}',
                                        style: const TextStyle(color: Colors.green),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              return Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context, 'setup_company_profile_first'),
                                        style: const TextStyle(color: Colors.orange),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/company-info');
                                      },
                                      child: Text(AppLocalizations.of(context, 'add_company')),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Location Section
                if (!_isCompanyPost) ...[
                  LocationDetailsForm(
                    localityController: _localityController,
                    districtController: _districtController,
                    stateController: _stateController,
                    cityController: _cityController,
                    pincodeController: _pincodeController,
                    countryController: _countryController,
                    addressController: _addressController,
                  ),
                ] else ...[
                  theme.buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(AppLocalizations.of(context, 'location_company'), style: theme.titleStyle),
                            const Icon(Icons.check_circle, color: Colors.green),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_cityController.text}, ${_stateController.text}\n${_addressController.text}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _postJob,
                  style: theme.primaryButtonStyle(context),
                  child:
                      _isLoading
                          ? theme.loadingIndicator()
                          : Text(AppLocalizations.of(context, 'post_job_button'), style: theme.buttonTextStyle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
