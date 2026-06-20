import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class PayoutDetailsScreen extends StatefulWidget {
  const PayoutDetailsScreen({super.key});

  @override
  State<PayoutDetailsScreen> createState() => _PayoutDetailsScreenState();
}

class _PayoutDetailsScreenState extends State<PayoutDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  final _upiController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNoController = TextEditingController();
  final _ifscController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPayoutDetails();
  }

  @override
  void dispose() {
    _upiController.dispose();
    _holderNameController.dispose();
    _bankNameController.dispose();
    _accountNoController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _loadPayoutDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final response = await Dio().get(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/wallet/payout-details',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        final data = response.data['data'];
        final upi = data['upiId'] ?? '';
        final bankDetails = data['bankDetails'] ?? {};
        
        setState(() {
          _upiController.text = upi;
          _holderNameController.text = bankDetails['accountHolderName'] ?? '';
          _bankNameController.text = bankDetails['bankName'] ?? '';
          _accountNoController.text = bankDetails['accountNumber'] ?? '';
          _ifscController.text = bankDetails['ifscCode'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _savePayoutDetails() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isSaving = true);
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      
      final payload = {
        'upiId': _upiController.text.trim(),
        'bankDetails': {
          'bankName': _bankNameController.text.trim(),
          'accountNumber': _accountNoController.text.trim(),
          'ifscCode': _ifscController.text.trim(),
          'accountHolderName': _holderNameController.text.trim(),
        }
      };

      final response = await Dio().put(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/wallet/payout-details',
        data: payload,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payout details updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      String msg = 'Failed to update payout details';
      if (e.response?.data != null && e.response?.data['message'] != null) {
        msg = e.response?.data['message'];
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.style;

    return theme.buildPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Payout Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Theme.of(context).primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: _isLoading
            ? Center(child: theme.loadingIndicator(color: Theme.of(context).primaryColor))
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error loading details: $_errorMessage', style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadPayoutDetails,
                            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Configure Payout Accounts',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Provide either your UPI ID or Bank account details where you want to receive withdrawal payouts.',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.45),
                          ),
                          const SizedBox(height: 24),
                          
                          // UPI ID Card
                          _buildSectionCard(
                            theme: theme,
                            title: 'UPI Transfer Option',
                            icon: Icons.flash_on,
                            iconColor: Colors.blue,
                            children: [
                              TextFormField(
                                controller: _upiController,
                                decoration: InputDecoration(
                                  labelText: 'UPI ID (Virtual Payment Address)',
                                  hintText: 'e.g. john@ybl',
                                  prefixIcon: const Icon(Icons.payment),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (value) {
                                  if (value != null && value.isNotEmpty && !value.contains('@')) {
                                    return 'Please enter a valid UPI ID (must contain @)';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),

                          // Bank Details Card
                          _buildSectionCard(
                            theme: theme,
                            title: 'Bank Transfer Option',
                            icon: Icons.account_balance,
                            iconColor: Colors.green,
                            children: [
                              TextFormField(
                                controller: _holderNameController,
                                decoration: InputDecoration(
                                  labelText: 'Account Holder Name',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _bankNameController,
                                decoration: InputDecoration(
                                  labelText: 'Bank Name',
                                  prefixIcon: const Icon(Icons.business),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _accountNoController,
                                decoration: InputDecoration(
                                  labelText: 'Account Number',
                                  prefixIcon: const Icon(Icons.numbers),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _ifscController,
                                decoration: InputDecoration(
                                  labelText: 'IFSC Code',
                                  prefixIcon: const Icon(Icons.code),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                textCapitalization: TextCapitalization.characters,
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          ElevatedButton(
                            onPressed: _isSaving ? null : _savePayoutDetails,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isSaving
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : const Text(
                                    'Save Payout Details',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildSectionCard({
    required dynamic theme,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return theme.buildCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }
}
