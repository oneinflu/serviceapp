import 'dart:convert';
import 'package:app/widgets/location_details_form.dart';
import 'package:drop_down_search_field/drop_down_search_field.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class JobProfileScreen extends StatefulWidget {
  const JobProfileScreen({Key? key}) : super(key: key);

  @override
  State<JobProfileScreen> createState() => _JobProfileScreenState();
}

class _JobProfileScreenState extends State<JobProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Text Controllers
  final TextEditingController _categoryController = TextEditingController();
  
  // Location Controllers
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController(text: 'INDIA');
  final TextEditingController _addressController = TextEditingController();

  List<Map<String, dynamic>> _selectedCategories = [];
  List<Map<String, dynamic>> _categories = [];
  
  bool _isLoading = false;
  bool _isFetching = true;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _fetchCategories();
    await _fetchMyProfile();
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
          _categories = data.map((cat) => {'id': cat['_id'], 'name': cat['name']}).toList();
        });
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> _fetchMyProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    
    if (token == null) {
      setState(() => _isFetching = false);
      return;
    }

    try {
      var dio = Dio();
      var response = await dio.get(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/job-profiles/my-profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['data'] != null && response.data['data']['profile'] != null) {
        final profile = response.data['data']['profile'];
        
        setState(() {
          _isActive = profile['isActive'] ?? true;
          
          if (profile['location'] != null) {
            _districtController.text = profile['location']['district'] ?? '';
            _stateController.text = profile['location']['state'] ?? '';
            _cityController.text = profile['location']['city'] ?? '';
            _pincodeController.text = profile['location']['pincode'] ?? '';
            _countryController.text = profile['location']['country'] ?? 'INDIA';
            _addressController.text = profile['location']['address'] ?? '';
          }
          
          if (profile['categories'] != null) {
            _selectedCategories = (profile['categories'] as List).map((cat) {
              if (cat is Map) {
                return {'id': cat['_id'], 'name': cat['name']};
              }
              // If it's just an ID, try to find the name from our fetched categories
              final found = _categories.firstWhere((c) => c['id'] == cat, orElse: () => {'id': cat, 'name': 'Unknown Category'});
              return found;
            }).toList();
          }
        });
      }
    } catch (e) {
      print('Error fetching profile: $e');
      // If 404, it just means profile doesn't exist yet, which is fine
    } finally {
      setState(() => _isFetching = false);
    }
  }

  void _removeCategory(Map<String, dynamic> category) {
    setState(() {
      _selectedCategories.removeWhere((cat) => cat['id'] == category['id']);
    });
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context, 'please_select_at_least_one_category'))),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context, 'please_log_in_to_update_profile'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    final Map<String, dynamic> requestData = {
      "categories": _selectedCategories.map((cat) => cat['id']).toList(),
      "location": {
        "city": _cityController.text.trim(),
        "district": _districtController.text.trim(),
        "state": _stateController.text.trim(),
        "country": _countryController.text.trim(),
        "pincode": _pincodeController.text.trim(),
      },
      "isActive": _isActive,
    };

    try {
      var dio = Dio();
      var response = await dio.post(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/job-profiles',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: jsonEncode(requestData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context, 'profile_saved_successfully'))),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context, 'failed_prefix')} ${response.statusMessage}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context, 'error_saving_profile')} $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.style;
    final int maxCategories = 5;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ThemeStyle.iconColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(AppLocalizations.of(context, 'job_seeker_profile'), style: theme.appBarTitleStyle(context)),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: theme.backgroundGradient),
        child: _isFetching 
            ? Center(child: theme.loadingIndicator(color: Theme.of(context).primaryColor))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(ThemeStyle.defaultPadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Active Status Toggle
                      theme.buildCard(
                        child: SwitchListTile(
                          title: Text(AppLocalizations.of(context, 'profile_active'), style: theme.titleStyle),
                          subtitle: Text(
                            AppLocalizations.of(context, 'allow_employers_desc'),
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                          value: _isActive,
                          onChanged: (value) => setState(() => _isActive = value),
                          activeColor: Theme.of(context).primaryColor,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // The Categories Section starts immediately after the active toggle

                      // Categories Section
                      theme.buildCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context, 'categories'), style: theme.titleStyle),
                            const SizedBox(height: 4),
                            Text(
                              '${AppLocalizations.of(context, 'select_up_to_job_categories')} $maxCategories',
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
                                        labelText: AppLocalizations.of(context, 'search_categories'),
                                        prefixIcon: Icons.search,
                                        context: context,
                                        hintText: AppLocalizations.of(context, 'type_to_search'),
                                      ),
                                    ),
                                    displayAllSuggestionWhenTap: true,
                                    isMultiSelectDropdown: false,
                                    suggestionsCallback: (pattern) {
                                      return _categories
                                          .where((cat) => cat['name'].toString().toLowerCase().contains(pattern.toLowerCase()) &&
                                                          !_selectedCategories.any((selected) => selected['id'] == cat['id']))
                                          .map((cat) => cat['name'] as String)
                                          .toList();
                                    },
                                    itemBuilder: (context, suggestion) => ListTile(title: Text(suggestion)),
                                    onSuggestionSelected: (suggestion) {
                                      final selectedCategory = _categories.firstWhere(
                                        (cat) => cat['name'] == suggestion,
                                        orElse: () => {'id': null, 'name': ''},
                                      );

                                      if (selectedCategory['id'] != null && !_selectedCategories.any((cat) => cat['id'] == selectedCategory['id'])) {
                                        if (_selectedCategories.length < maxCategories) {
                                          setState(() {
                                            _selectedCategories.add(selectedCategory);
                                            _categoryController.clear();
                                          });
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('${AppLocalizations.of(context, 'max_categories_allowed')} $maxCategories')),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: _selectedCategories.length >= maxCategories
                                      ? null
                                      : () {
                                          if (_categoryController.text.isNotEmpty) {
                                            final categoryName = _categoryController.text.trim();
                                            final selectedCategory = _categories.firstWhere(
                                              (cat) => cat['name'] == categoryName,
                                              orElse: () => {'id': null, 'name': ''},
                                            );

                                            if (selectedCategory['id'] != null && !_selectedCategories.any((cat) => cat['id'] == selectedCategory['id'])) {
                                              setState(() {
                                                _selectedCategories.add(selectedCategory);
                                                _categoryController.clear();
                                              });
                                            }
                                          }
                                        },
                                  style: theme.primaryButtonStyle(context).copyWith(
                                        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 16, horizontal: 24)),
                                      ),
                                  child: Text(AppLocalizations.of(context, 'add'), style: const TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                            if (_selectedCategories.isNotEmpty) const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedCategories.map((category) {
                                return Chip(
                                  label: Text(category['name']),
                                  deleteIcon: const Icon(Icons.close, size: 18),
                                  onDeleted: () => _removeCategory(category),
                                  backgroundColor: Colors.grey[200],
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                );
                              }).toList(),
                            ),
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
                        addressController: _addressController,
                        hideAddress: true,
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: theme.primaryButtonStyle(context),
                        child: _isLoading
                            ? theme.loadingIndicator()
                            : Text(AppLocalizations.of(context, 'save_profile'), style: theme.buttonTextStyle),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
