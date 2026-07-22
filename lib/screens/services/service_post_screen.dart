import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:drop_down_search_field/drop_down_search_field.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/location_details_form.dart';
import '../../widgets/service_subscription_sheet.dart';
import '../../l10n/app_localizations.dart';

class ServicePostScreen extends StatefulWidget {
  const ServicePostScreen({Key? key}) : super(key: key);

  @override
  State<ServicePostScreen> createState() => _ServicePostScreenState();
}

class _ServicePostScreenState extends State<ServicePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _localityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Changed to store category with price
  List<Map<String, dynamic>> _selectedCategories = [];
  List<Map<String, dynamic>> _categories = [];
  // Remove this line
  // List<Map<String, dynamic>> _filteredCategories = [];
  bool _isLoading = false;

  // Company post variables
  bool _isCompanyPost = false;
  String? _companyId;

  // Add these variables for company selection
  List<dynamic> _userCompanies = [];
  bool _isLoadingCompanies = false;
  String? _selectedCompanyId;

  // Subscription data
  bool _isPaidSubscription = false;

  // Existing service state
  bool _isExistingService = false;
  String? _existingServiceId;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshUserData(); // Refresh first
    _fetchCategories();
    _fetchCompanyId();
    _fetchSubscriptionData();
    // Proactively fetch user companies even if not selected yet
    _fetchUserCompanies(force: true);
    // Check for existing service
    _fetchExistingService();
  }

  Future<void> _fetchExistingService() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) return;

      var response = await Dio().get(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/services/my-services',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> services = response.data['data']['services'] ?? [];
        if (services.isNotEmpty) {
          final service = services[0]; // Take the only one
          setState(() {
            _isExistingService = true;
            _existingServiceId = service['_id'];

            // Populate fields
            _isCompanyPost = service['isCompanyPost'] ?? false;
            // Handle both object and ID formats
            final dynamic companyData = service['company'];
            if (companyData != null) {
              if (companyData is Map) {
                _selectedCompanyId = companyData['_id'];
              } else {
                _selectedCompanyId = companyData;
              }
            } else {
              _selectedCompanyId = service['companyId'];
            }
            _companyId = _selectedCompanyId;

            final loc = service['location'] ?? {};
            _districtController.text = loc['district'] ?? '';
            _stateController.text = loc['state'] ?? '';
            _cityController.text = loc['city'] ?? '';
            _pincodeController.text = loc['pincode'] ?? '';
            _countryController.text = loc['country'] ?? 'INDIA';
            _addressController.text = loc['address'] ?? '';

            if (service['categoryPrices'] != null) {
              _selectedCategories =
                  (service['categoryPrices'] as List).map((cp) {
                    return {
                      'id': cp['category']['_id'],
                      'name': cp['category']['name'],
                      'price': double.tryParse(cp['price']?.toString() ?? '0') ?? 0,
                    };
                  }).toList();
            }
          });
        }
      }
    } catch (e) {
      print('Error fetching existing service: $e');
    }
  }

  // Replace the existing _fetchCompanyId method with this one
  Future<void> _fetchCompanyId() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = authProvider.userData;
  
    if (userData != null && userData['company'] != null) {
      setState(() {
        _companyId = userData['company']['_id'];
        _selectedCompanyId = userData['company']['_id'];
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

  // Add this new method to fetch user's companies
  Future<void> _fetchUserCompanies({bool force = false}) async {
    if (!_isCompanyPost && !force) return;

    try {
      setState(() {
        _isLoadingCompanies = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        setState(() {
          _isLoadingCompanies = false;
        });
        return;
      }

      var response = await Dio().get(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/companies/my-companies',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _userCompanies = response.data['data']['companies'] ?? [];
          _isLoadingCompanies = false;

          // If we have companies and none selected yet, select the first one
          if (_userCompanies.isNotEmpty && _selectedCompanyId == null) {
            _selectedCompanyId = _userCompanies[0]['_id'];
            _companyId = _selectedCompanyId;
          }
        });
      }
    } catch (e) {
      print('Error fetching companies: $e');
      setState(() {
        _isLoadingCompanies = false;
      });
    }
  }

  // Implement _fetchCategories method
  Future<void> _fetchCategories() async {
    try {
      setState(() {
        _isLoading = true;
      });

      var dio = Dio();
      var response = await dio.get(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/categories/type/Service',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          _categories = List<Map<String, dynamic>>.from(
            data['data']['categories'].map(
              (category) => {'id': category['_id'], 'name': category['name']},
            ),
          );
          // Remove this line
          // _filteredCategories = List.from(_categories);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching categories: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Implement _fetchSubscriptionData method
  Future<void> _fetchSubscriptionData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userData = authProvider.userData;

      if (userData != null) {
        setState(() {
          _isPaidSubscription =
              userData['subscription'] != null &&
              userData['subscription']['status'] == 'active' &&
              userData['subscription']['type'] == 'SERVICE_POST';
        });
      }
    } catch (e) {
      print('Error fetching subscription data: $e');
    }
  }

  void _removeCategory(Map<String, dynamic> category) {
    setState(() {
      _selectedCategories.removeWhere((cat) => cat['id'] == category['id']);
    });
  }

  Future<void> _createAndAddCategory(String name) async {
    final int maxCategories = _isPaidSubscription ? 10 : 1;

    if (!_isPaidSubscription && _selectedCategories.isNotEmpty) {
      _showSubscriptionSheet(context);
      return;
    }
    if (_selectedCategories.length >= maxCategories) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context, 'max_categories_allowed')}$maxCategories',
          ),
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    try {
      final response = await Dio().post(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/categories/request',
        data: {'name': name.trim(), 'type': 'Service'},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 201) {
        final newCategory = Map<String, dynamic>.from(
          response.data['data']['category'],
        );
        newCategory['id'] = newCategory['_id'];
        newCategory['price'] = 0;
        setState(() {
          _categories.add(newCategory);
          _selectedCategories.add(newCategory);
          _categoryController.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add category: $e')),
      );
    }
  }

  // Implement _updateCategoryPrice method
  void _updateCategoryPrice(String categoryId, String value) {
    setState(() {
      final index = _selectedCategories.indexWhere(
        (cat) => cat['id'] == categoryId,
      );
      if (index != -1) {
        _selectedCategories[index]['price'] = double.tryParse(value) ?? 0;
      }
    });
  }

  // Implement _showCompanyInfoDialog method
  void _showCompanyInfoDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context, 'company_profile_required')),
            content: Text(
              AppLocalizations.of(context, 'company_profile_required_desc'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context, 'cancel')),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/company-info').then((_) {
                    // Refresh user data after adding company info
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    authProvider.refreshUserData().then((_) {
                      // Fetch companies again
                      _fetchUserCompanies();
                    });
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                ),
                child: Text(AppLocalizations.of(context, 'add_company_info')),
              ),
            ],
          ),
    );
  }

  // Modify the existing _postService method to use _selectedCompanyId
  Future<void> _postService() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context, 'please_select_at_least_one_category'))),
      );
      return;
    }



    // Check if company post but no company info
    if (_isCompanyPost) {
      if (_selectedCompanyId == null || _selectedCompanyId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context, 'please_set_up_company_profile'))),
        );
        return;
      }
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context, 'please_log_in_post_service'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Send the raw locality string — the backend resolves it to full location.
    final Map<String, dynamic> requestData = {
      "categoryPrices":
          _selectedCategories
              .map((cat) => {"category": cat['id'], "price": cat['price']})
              .toList(),
      "locality": _localityController.text.trim(),
      "isCompanyPost": _isCompanyPost,
    };

    // Add company ID if it's a company post
    if (_isCompanyPost &&
        _selectedCompanyId != null &&
        _selectedCompanyId!.isNotEmpty) {
      requestData["company"] = _selectedCompanyId;
    }

    try {
      var dio = Dio();
      var response = await dio.post(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/services',
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
          SnackBar(content: Text(AppLocalizations.of(context, 'service_posted_successfully'))),
        );
        // Clear form fields
        _formKey.currentState?.reset();
        setState(() {
          _selectedCategories = [];
          _categoryController.clear();
        });
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context, 'failed_prefix')} ${response.statusMessage}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context, 'error_prefix')} $e')));
    } finally {
      setState(() => _isLoading = false);
    }
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
            serviceType: 'Service Post',
            price: 500,
            benefits: [
              'Post unlimited services for 365 days',
              'Business profile customization',
              'Priority listing in search results',
              'Analytics and insights',
              'Add up to 10 categories per service',
              'Includes access to Job & Service search feature',
            ],
            isPremium: true,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.style;
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData;

    // Check subscription status to determine max categories
    final bool isPaidSubscription =
        userData != null &&
        userData['subscription'] != null &&
        userData['subscription']['status'] == 'active' &&
        userData['subscription']['type'] == 'SERVICE_POST';

    // Add this debug code to check subscription data
    print('User Data: $userData');
    print('User Data Keys: ${userData?.keys.toList()}');

    if (userData != null) {
      print('Has subscription key: ${userData.containsKey("subscription")}');
      if (userData['subscription'] != null) {
        print('Subscription Data: ${userData["subscription"]}');
        print('Subscription Status: ${userData["subscription"]["status"]}');
        print('Subscription Type: ${userData["subscription"]["type"]}');
      } else {
        print('Subscription data is null');
      }
    } else {
      print('User data is null');
    }

    print('Is Paid Subscription: $isPaidSubscription');

    // Set max categories based on subscription (1 for free, 10 for SERVICE_POST)
    final int maxCategories = isPaidSubscription ? 10 : 1;
    print('Max Categories: $maxCategories');

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ThemeStyle.iconColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(AppLocalizations.of(context, 'post_a_service'), style: theme.appBarTitleStyle(context)),
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

                // Company Post Toggle Section
                theme.buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context, 'company_post'), style: theme.titleStyle),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context, 'is_this_company_service'),
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
                                        '${AppLocalizations.of(context, 'posting_as')}${userData!['company']['name']}',
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
                                          AppLocalizations.of(context, 'please_set_up_company_profile'),
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

                // Categories Section with Search
                theme.buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context, 'categories'), style: theme.titleStyle),
                      const SizedBox(height: 4),
                      Text(
                        isPaidSubscription
                            ? AppLocalizations.of(context, 'add_up_to_10_categories')
                            : AppLocalizations.of(context, 'add_up_to_1_category'),
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
                                  // Check if free user is trying to add more than one category
                                  if (!isPaidSubscription &&
                                      _selectedCategories.length >= 1) {
                                    _showSubscriptionSheet(context);
                                    return;
                                  }

                                  // Check if user is within the maximum category limit
                                  if (_selectedCategories.length <
                                      maxCategories) {
                                    setState(() {
                                      // Initialize with empty price
                                      selectedCategory['price'] = 0;
                                      _selectedCategories.add(selectedCategory);
                                      _categoryController.clear();
                                    });
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${AppLocalizations.of(context, 'max_categories_allowed')}$maxCategories',
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
                            onPressed: () {
                              // For free users who already have one category, show upgrade button
                              if (!isPaidSubscription &&
                                  _selectedCategories.length >= 1) {
                                _showSubscriptionSheet(context);
                                return;
                              }

                              // Normal add functionality for users within their limits
                              if (_categoryController.text.isNotEmpty) {
                                final categoryName =
                                    _categoryController.text.trim();
                                final selectedCategory = _categories.firstWhere(
                                  (cat) => cat['name'] == categoryName,
                                  orElse: () => {'id': null, 'name': ''},
                                );

                                if (selectedCategory['id'] != null &&
                                    !_selectedCategories.any(
                                      (cat) =>
                                          cat['id'] == selectedCategory['id'],
                                    )) {
                                  if (_selectedCategories.length < maxCategories) {
                                    setState(() {
                                      selectedCategory['price'] = 0;
                                      _selectedCategories.add(selectedCategory);
                                      _categoryController.clear();
                                    });
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${AppLocalizations.of(context, 'max_categories_allowed')}$maxCategories',
                                        ),
                                      ),
                                    );
                                  }
                                } else if (selectedCategory['id'] == null) {
                                  _createAndAddCategory(categoryName);
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
                              // Change button text based on user status and selection
                              (!isPaidSubscription &&
                                      _selectedCategories.length >= 1)
                                  ? AppLocalizations.of(context, 'upgrade')
                                  : AppLocalizations.of(context, 'add'),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      if (_selectedCategories.isNotEmpty)
                        const SizedBox(height: 16),
                      // Display selected categories
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _selectedCategories.map((category) {
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
                          '${_selectedCategories.length}/$maxCategories ${AppLocalizations.of(context, 'categories').toLowerCase()}',
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
                  onPressed: _isLoading ? null : _postService,
                  style: theme.primaryButtonStyle(context),
                  child:
                      _isLoading
                          ? theme.loadingIndicator()
                          : Text(AppLocalizations.of(context, 'post_service'), style: theme.buttonTextStyle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
