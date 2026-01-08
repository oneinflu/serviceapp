import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:drop_down_search_field/drop_down_search_field.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/location_details_form.dart';
import '../../widgets/service_subscription_sheet.dart';

class EditServicePostScreen extends StatefulWidget {
  final Map<String, dynamic> service;

  const EditServicePostScreen({Key? key, required this.service})
    : super(key: key);

  @override
  State<EditServicePostScreen> createState() => _EditServicePostScreenState();
}

class _EditServicePostScreenState extends State<EditServicePostScreen> {
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
  String? _selectedCompanyId;
  List<Map<String, dynamic>> _userCompanies = [];
  bool _isLoadingCompanies = false;
  bool _isPaidSubscription = false;
  String _serviceId = '';

  @override
  void initState() {
    super.initState();
    _serviceId = widget.service['_id'];
    _isCompanyPost = widget.service['isCompanyPost'] ?? false;

    // Initialize location fields
    final location = widget.service['location'] ?? {};
    _districtController.text = location['district'] ?? '';
    _stateController.text = location['state'] ?? '';
    _cityController.text = location['city'] ?? '';
    _pincodeController.text = location['pincode'] ?? '';
    _countryController.text = location['country'] ?? '';

    // Fetch categories and other data
    _fetchCategories();
    _fetchCompanyId();
    _fetchSubscriptionData();
    _fetchServiceDetails();
  }

  Future<void> _fetchServiceDetails() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      var dio = Dio();
      var response = await dio.get(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/services/${_serviceId}',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final serviceData = response.data['data']['service'];

        // Set company post status
        setState(() {
          _isCompanyPost = serviceData['isCompanyPost'] ?? false;

          // Set selected company ID if it's a company post
          if (_isCompanyPost && serviceData['company'] != null) {
            _selectedCompanyId = serviceData['company']['_id'];
          }

          // Set selected categories with prices
          if (serviceData['categoryPrices'] != null) {
            _selectedCategories =
                (serviceData['categoryPrices'] as List).map((catPrice) {
                  return {
                    'id': catPrice['category']['_id'],
                    'name': catPrice['category']['name'],
                    'price': catPrice['price'],
                  };
                }).toList();
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching service details: $e')),
      );
    }
  }

  Future<void> _fetchCompanyId() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = authProvider.userData;

    if (userData != null && userData['company'] != null) {
      setState(() {
        _selectedCompanyId = userData['company']['_id'];
      });
    }

    _fetchUserCompanies();
  }

  Future<void> _fetchUserCompanies() async {
    setState(() => _isLoadingCompanies = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      var dio = Dio();
      var response = await dio.get(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/companies/user',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        var data = response.data['data']['companies'] as List;
        setState(() {
          _userCompanies =
              data
                  .map(
                    (company) => {
                      'id': company['_id'],
                      'name': company['name'],
                    },
                  )
                  .toList();
          _isLoadingCompanies = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingCompanies = false);
      print('Error fetching user companies: $e');
    }
  }

  Future<void> _fetchCategories() async {
    try {
      var dio = Dio();
      var response = await dio.get(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/categories/type/Service',
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

  Future<void> _fetchSubscriptionData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = authProvider.userData;

    setState(() {
      _isPaidSubscription =
          userData != null &&
          userData['subscription'] != null &&
          userData['subscription']['status'] == 'active' &&
          userData['subscription']['type'] == 'SERVICE_POST';
    });
  }

  void _removeCategory(Map<String, dynamic> category) {
    setState(() {
      _selectedCategories.removeWhere((cat) => cat['id'] == category['id']);
    });
  }

  void _updateCategoryPrice(String categoryId, double price) {
    setState(() {
      final index = _selectedCategories.indexWhere(
        (cat) => cat['id'] == categoryId,
      );
      if (index != -1) {
        _selectedCategories[index]['price'] = price;
      }
    });
  }

  void _showCompanyInfoDialog() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Company Information Required'),
            content: const Text(
              'You need to add company information before posting a company service.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.pushNamed(context, '/company-info').then((_) {
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

  Future<void> _updateService() async {
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
      if (_userCompanies.isEmpty) {
        _showCompanyInfoDialog();
        return;
      }

      if (_selectedCompanyId == null || _selectedCompanyId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a company')),
        );
        return;
      }
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to update a service.')),
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
      var response = await dio.put(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/services/${_serviceId}',
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
          const SnackBar(content: Text('Service updated successfully!')),
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
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData;

    // Set max categories based on subscription (1 for free, 10 for SERVICE_POST)
    final int maxCategories = _isPaidSubscription ? 10 : 1;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ThemeStyle.iconColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edit Service Post',
          style: theme.appBarTitleStyle(context),
        ),
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
                        'Add up to ${maxCategories} categories for your service',
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
                                if (_selectedCategories.length >=
                                    maxCategories) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'You can only add up to $maxCategories categories',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setState(() {
                                  _selectedCategories.add({
                                    'id': selectedCategory['id'],
                                    'name': selectedCategory['name'],
                                    'price': 0.0, // Default price
                                  });
                                });
                              },
                              displayAllSuggestionWhenTap: true,
                              isMultiSelectDropdown: false,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Selected Categories with Price Input
                      ..._selectedCategories.map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Chip(
                                  label: Text(category['name']),
                                  deleteIcon: const Icon(Icons.close),
                                  onDeleted: () => _removeCategory(category),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 100,
                                child: TextFormField(
                                  initialValue:
                                      category['price']?.toString() ?? '',
                                  decoration: const InputDecoration(
                                    labelText: 'Price',
                                    prefixText: '₹',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    final price = double.tryParse(value);
                                    if (price == null || price <= 0) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    final price = double.tryParse(value) ?? 0;
                                    _updateCategoryPrice(category['id'], price);
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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
                          'Enable to post this service under your company profile',
                        ),
                        value: _isCompanyPost,
                        onChanged: (value) {
                          setState(() {
                            _isCompanyPost = value;
                          });
                        },
                      ),
                      if (_isCompanyPost) ...[
                        const SizedBox(height: 16),
                        if (_isLoadingCompanies)
                          const Center(child: CircularProgressIndicator())
                        else if (_userCompanies.isEmpty)
                          ElevatedButton.icon(
                            onPressed: _showCompanyInfoDialog,
                            icon: const Icon(Icons.add_business),
                            label: const Text('Add Company Information'),
                            style: theme.primaryButtonStyle(context),
                          )
                        else
                          DropdownButtonFormField<String>(
                            // This expects String values
                            value: _selectedCompanyId,
                            decoration: theme.dropdownDecoration(
                              labelText: 'Select Company',
                              prefixIcon: Icons.business,
                              context: context,
                            ),
                            items:
                                _userCompanies
                                    .map(
                                      (company) => DropdownMenuItem<String>(
                                        value:
                                            company['id']
                                                as String, // Explicitly cast to String
                                        child: Text(company['name']),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCompanyId = value;
                              });
                            },
                            validator: (value) {
                              if (_isCompanyPost && value == null) {
                                return 'Please select a company';
                              }
                              return null;
                            },
                          ),
                      ],
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
                  onPressed: _isLoading ? null : _updateService,
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
                          : const Text('Update Service'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
