import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:drop_down_search_field/drop_down_search_field.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/location_details_form.dart';
import '../../widgets/service_subscription_sheet.dart';

class ServicePostScreen extends StatefulWidget {
  const ServicePostScreen({Key? key}) : super(key: key);

  @override
  State<ServicePostScreen> createState() => _ServicePostScreenState();
}

class _ServicePostScreenState extends State<ServicePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

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

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchCompanyId();
    _fetchSubscriptionData();
  }

  // Replace the existing _fetchCompanyId method with this one
  Future<void> _fetchCompanyId() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = authProvider.userData;
  
    if (userData != null && userData['company'] != null) {
      setState(() {
        _companyId = userData['company']['_id'];
        _selectedCompanyId = userData['company']['_id'];  // Add this line
      });
    }
  }

  // Add this new method to fetch user's companies
  Future<void> _fetchUserCompanies() async {
    if (!_isCompanyPost) return;

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

  // Implement _removeCategory method
  void _removeCategory(Map<String, dynamic> category) {
    setState(() {
      _selectedCategories.removeWhere((cat) => cat['id'] == category['id']);
    });
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
            title: const Text('Company Profile Required'),
            content: const Text(
              'You need to set up your company profile before posting a service as a company.\n\nWould you like to add your company information now?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
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
                child: const Text('Add Company Info'),
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
        const SnackBar(content: Text('Please select at least one category.')),
      );
      return;
    }

    // Check if all categories have prices
    bool allCategoriesHavePrices = _selectedCategories.every(
      (cat) =>
          cat.containsKey('price') && cat['price'] != null && cat['price'] > 0,
    );

    if (!allCategoriesHavePrices) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a price for each category.'),
        ),
      );
      return;
    }

    // Check if company post but no company info
    if (_isCompanyPost) {
      if (_selectedCompanyId == null || _selectedCompanyId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please set up your company profile first')),
        );
        return;
      }
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to post a service.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Updated request format with categoryPrices and company info
    final Map<String, dynamic> requestData = {
      "categoryPrices":
          _selectedCategories
              .map((cat) => {"category": cat['id'], "price": cat['price']})
              .toList(),
      "location": {
        "district": _districtController.text,
        "state": _stateController.text,
        "city": _cityController.text,
        "pincode": _pincodeController.text,
        "country": _countryController.text,
      },
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
          const SnackBar(content: Text('Service posted successfully!')),
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
        title: Text('Post a Service', style: theme.appBarTitleStyle(context)),
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
                      Text('Company Post', style: theme.titleStyle),
                      const SizedBox(height: 8),
                      Text(
                        'Is this a company service posting?',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Post as Company'),
                        value: _isCompanyPost,
                        onChanged: (value) {
                          setState(() {
                            _isCompanyPost = value;
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
                                        'Posting as ${userData!['company']['name']}',
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
                                        'You need to set up your company profile first',
                                        style: const TextStyle(color: Colors.orange),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/company-info');
                                      },
                                      child: const Text('Add Company'),
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
                      Text('Categories', style: theme.titleStyle),
                      const SizedBox(height: 4),
                      Text(
                        isPaidSubscription
                            ? 'Add up to 10 categories for your service'
                            : 'Add up to 1 category for your service (upgrade for more)',
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
                                  labelText: 'Search and Select Category',
                                  prefixIcon: Icons.search,
                                  context: context,
                                  hintText: 'Select Category',
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
                                          'Maximum $maxCategories categories allowed',
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
                                // Find the category based on the text
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
                                          'Maximum $maxCategories categories allowed',
                                        ),
                                      ),
                                    );
                                  }
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
                                  ? 'Upgrade'
                                  : 'Add',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      if (_selectedCategories.isNotEmpty)
                        const SizedBox(height: 16),
                      // Display selected categories with price inputs
                      ..._selectedCategories.map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Chip(
                                  label: Text(category['name']),
                                  deleteIcon: const Icon(Icons.close, size: 18),
                                  onDeleted: () => _removeCategory(category),
                                  backgroundColor: Colors.grey[200],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  initialValue:
                                      category['price'] > 0
                                          ? category['price'].toString()
                                          : '',
                                  keyboardType: TextInputType.number,
                                  decoration: theme.inputDecoration(
                                    labelText: 'Price',
                                    prefixIcon: Icons.currency_rupee,
                                    context: context,
                                  ),
                                  validator:
                                      (value) =>
                                          value == null || value.isEmpty
                                              ? 'Required'
                                              : null,
                                  onChanged:
                                      (value) => _updateCategoryPrice(
                                        category['id'],
                                        value,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      if (_selectedCategories.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${_selectedCategories.length}/$maxCategories categories',
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
                LocationDetailsForm(
                  districtController: _districtController,
                  stateController: _stateController,
                  cityController: _cityController,
                  pincodeController: _pincodeController,
                  countryController: _countryController,
                ),

                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _postService,
                  style: theme.primaryButtonStyle(context),
                  child:
                      _isLoading
                          ? theme.loadingIndicator()
                          : Text('Post Service', style: theme.buttonTextStyle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
