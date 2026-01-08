import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/location_details_form.dart';

class CompanyInfoScreen extends StatefulWidget {
  const CompanyInfoScreen({Key? key}) : super(key: key);

  @override
  State<CompanyInfoScreen> createState() => _CompanyInfoScreenState();
}

class _CompanyInfoScreenState extends State<CompanyInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _websiteController = TextEditingController();
  final _aboutController = TextEditingController();
  final _logoController = TextEditingController();

  // Location controllers
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _countryController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingCompanyData = true;
  String? _companyId;
  bool _hasCompany = false;

  // In the initState method, add this:
  @override
  void initState() {
    super.initState();
    // Check if we received a company object for editing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final company = ModalRoute.of(context)?.settings.arguments;
      if (company != null) {
        // If we have a company object, prefill the form
        _prefillCompanyData(company);
      } else {
        // Otherwise fetch from API
        _fetchCompanyData();
      }
    });
  }

  // Add this method to prefill the form with company data
  void _prefillCompanyData(dynamic company) {
    setState(() {
      _isLoadingCompanyData = false;
      _companyId = company['_id'];
      _hasCompany = true;

      _nameController.text = company['name'] ?? '';
      _websiteController.text = company['website'] ?? '';
      _aboutController.text = company['about'] ?? '';
      _logoController.text = company['logo'] ?? '';

      // Prefill location data
      if (company['location'] != null) {
        _countryController.text = company['location']['country'] ?? '';
        _stateController.text = company['location']['state'] ?? '';
        _cityController.text = company['location']['city'] ?? '';
        _districtController.text = company['location']['district'] ?? '';
        _pincodeController.text = company['location']['pincode'] ?? '';
      }
    });
  }

  Future<void> _fetchCompanyData() async {
    setState(() {
      _isLoadingCompanyData = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        setState(() {
          _isLoadingCompanyData = false;
        });
        return;
      }

      var dio = Dio();
      final response = await dio.get(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/companies/my-companies',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'success' && data['results'] > 0) {
          final companies = data['data']['companies'] as List;
          if (companies.isNotEmpty) {
            final company = companies[0];
            _companyId = company['_id'];
            _hasCompany = true;

            // Prefill the form with company data
            setState(() {
              _nameController.text = company['name'] ?? '';
              _websiteController.text = company['website'] ?? '';
              _aboutController.text = company['about'] ?? '';
              _logoController.text = company['logo'] ?? '';

              // Prefill location data
              if (company['location'] != null) {
                _countryController.text = company['location']['country'] ?? '';
                _stateController.text = company['location']['state'] ?? '';
                _cityController.text = company['location']['city'] ?? '';
                _districtController.text =
                    company['location']['district'] ?? '';
                _pincodeController.text = company['location']['pincode'] ?? '';
              }
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching company data: $e');
    } finally {
      setState(() {
        _isLoadingCompanyData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.style;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isDesktop = MediaQuery.of(context).size.width > 768;
    final formWidth = isDesktop ? 800.0 : double.infinity;
    final horizontalPadding =
        isDesktop
            ? (MediaQuery.of(context).size.width - formWidth) / 2
            : ThemeStyle.defaultPadding;

    return WillPopScope(
      onWillPop: () async => false,
      child: theme.buildPageBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: ThemeStyle.iconColor,
                size: isDesktop ? 28 : 24,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              _hasCompany ? 'Edit Company Information' : 'Company Information',
              style: theme
                  .appBarTitleStyle(context)
                  .copyWith(fontSize: isDesktop ? 24 : 20),
            ),
            centerTitle: true,
            actions: [
              if (!_hasCompany &&
                  (authProvider.userData == null ||
                      authProvider.userData!['skippedCompanyInfo'] != true))
                TextButton(
                  onPressed: () async {
                    final userData = authProvider.userData;

                    if (userData != null) {
                      final updatedUserData = Map<String, dynamic>.from(
                        userData,
                      );
                      updatedUserData['skippedCompanyInfo'] = true;
                      await authProvider.setUserData(updatedUserData);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString(
                        'user_data',
                        jsonEncode(updatedUserData),
                      );
                      await authProvider.refreshUserData();
                    }

                    if (mounted) {
                      Navigator.pushReplacementNamed(context, '/home');
                    }
                  },
                  child: Text(
                    'Skip',
                    style: theme
                        .linkStyle(context)
                        .copyWith(fontSize: isDesktop ? 18 : 16),
                  ),
                ),
            ],
          ),
          body:
              _isLoadingCompanyData
                  ? Center(
                    child: CircularProgressIndicator(
                      strokeWidth: isDesktop ? 4 : 3,
                    ),
                  )
                  : SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: ThemeStyle.defaultPadding,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _hasCompany
                                ? 'Edit your company information'
                                : 'Please provide your company information',
                            style: theme.titleStyle.copyWith(
                              fontSize: isDesktop ? 28 : 20,
                            ),
                          ),
                          SizedBox(height: isDesktop ? 30 : 20),
                          theme.buildCard(
                            child: Container(
                              width: formWidth,
                              padding: EdgeInsets.all(isDesktop ? 40 : 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: theme
                                        .inputDecoration(
                                          labelText: 'Company Name',
                                          prefixIcon: Icons.business,
                                          context: context,
                                        )
                                        .copyWith(
                                          contentPadding: EdgeInsets.all(
                                            isDesktop ? 20 : 12,
                                          ),
                                        ),
                                    style: TextStyle(
                                      fontSize: isDesktop ? 16 : 14,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter company name';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: isDesktop ? 24 : 16),
                                  TextFormField(
                                    controller: _websiteController,
                                    decoration: theme
                                        .inputDecoration(
                                          labelText: 'Website (Optional)',
                                          prefixIcon: Icons.language,
                                          context: context,
                                        )
                                        .copyWith(
                                          contentPadding: EdgeInsets.all(
                                            isDesktop ? 20 : 12,
                                          ),
                                        ),
                                    style: TextStyle(
                                      fontSize: isDesktop ? 16 : 14,
                                    ),
                                    keyboardType: TextInputType.url,
                                  ),
                                  SizedBox(height: isDesktop ? 24 : 16),
                                  TextFormField(
                                    controller: _aboutController,
                                    decoration: theme
                                        .inputDecoration(
                                          labelText: 'About Company (Optional)',
                                          prefixIcon: Icons.description,
                                          context: context,
                                        )
                                        .copyWith(
                                          contentPadding: EdgeInsets.all(
                                            isDesktop ? 20 : 12,
                                          ),
                                        ),
                                    style: TextStyle(
                                      fontSize: isDesktop ? 16 : 14,
                                    ),
                                    maxLines: 3,
                                  ),
                                  SizedBox(height: isDesktop ? 24 : 16),
                                  LocationDetailsForm(
                                    districtController: _districtController,
                                    stateController: _stateController,
                                    cityController: _cityController,
                                    pincodeController: _pincodeController,
                                    countryController: _countryController,
                                    isDesktop: isDesktop,
                                  ),
                                  SizedBox(height: isDesktop ? 40 : 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: isDesktop ? 56 : 48,
                                    child: ElevatedButton(
                                      onPressed:
                                          _isLoading ? null : _submitForm,
                                      child:
                                          _isLoading
                                              ? CircularProgressIndicator(
                                                strokeWidth: isDesktop ? 3 : 2,
                                              )
                                              : Text(
                                                _hasCompany
                                                    ? 'Update'
                                                    : 'Submit',
                                                style: TextStyle(
                                                  fontSize: isDesktop ? 18 : 16,
                                                ),
                                              ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final dio = Dio();
      final data = {
        'name': _nameController.text,
        'website': _websiteController.text,
        'about': _aboutController.text,
        'logo': _logoController.text,
        'location': {
          'country': _countryController.text,
          'state': _stateController.text,
          'city': _cityController.text,
          'district': _districtController.text,
          'pincode': _pincodeController.text,
        },
      };

      final response = await dio.post(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/companies',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 201 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company information saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to save company information';

        if (e is DioException && e.response != null) {
          final responseData = e.response?.data;
          if (responseData != null && responseData['message'] != null) {
            errorMessage = responseData['message'];
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
