import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';

class LocationDetailsForm extends StatefulWidget {
  final TextEditingController districtController;
  final TextEditingController stateController;
  final TextEditingController cityController;
  final TextEditingController pincodeController;
  final TextEditingController countryController;
  final TextEditingController addressController;
  final bool showTitle;
  final bool isDesktop;
  final bool hideAddress;
  /// Optional external controller for the locality input field.
  /// If provided, the parent can read the raw locality text the user typed.
  final TextEditingController? localityController;

  const LocationDetailsForm({
    super.key,
    required this.districtController,
    required this.stateController,
    required this.cityController,
    required this.pincodeController,
    required this.countryController,
    required this.addressController,
    this.showTitle = true,
    this.isDesktop = false,
    this.hideAddress = false,
    this.localityController,
  });

  @override
  State<LocationDetailsForm> createState() => _LocationDetailsFormState();
}

class _LocationDetailsFormState extends State<LocationDetailsForm> {
  late final TextEditingController _localityController;
  bool _ownLocalityController = false;
  bool _isResolving = false;
  String? _errorMessage;
  Map<String, dynamic>? _resolvedLocation;

  @override
  void initState() {
    super.initState();
    // Use the parent-provided controller if available, otherwise create our own.
    if (widget.localityController != null) {
      _localityController = widget.localityController!;
      _ownLocalityController = false;
    } else {
      _localityController = TextEditingController();
      _ownLocalityController = true;
    }

    // Pre-populate if we are editing an existing item that already has resolved location data
    if (widget.cityController.text.isNotEmpty || widget.stateController.text.isNotEmpty) {
      _resolvedLocation = {
        'locality': widget.districtController.text,
        'city': widget.cityController.text,
        'district': widget.districtController.text,
        'state': widget.stateController.text,
        'country': widget.countryController.text,
        'pincode': widget.pincodeController.text,
      };
      _localityController.text = widget.districtController.text;
    }
  }

  @override
  void didUpdateWidget(covariant LocationDetailsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.cityController.text.isNotEmpty && widget.cityController.text != oldWidget.cityController.text) ||
        (widget.stateController.text.isNotEmpty && widget.stateController.text != oldWidget.stateController.text)) {
      setState(() {
        _resolvedLocation = {
          'locality': widget.districtController.text,
          'city': widget.cityController.text,
          'district': widget.districtController.text,
          'state': widget.stateController.text,
          'country': widget.countryController.text,
          'pincode': widget.pincodeController.text,
        };
        _localityController.text = widget.districtController.text;
      });
    }
  }

  @override
  void dispose() {
    // Only dispose if we created the controller ourselves.
    if (_ownLocalityController) {
      _localityController.dispose();
    }
    super.dispose();
  }

  Future<void> _resolveLocality() async {
    final locality = _localityController.text.trim();
    if (locality.isEmpty) return;

    setState(() {
      _isResolving = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final dio = Dio();
      final response = await dio.get(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/location/resolve',
        queryParameters: {'locality': locality},
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final locData = response.data['data']['location'];
        setState(() {
          _resolvedLocation = Map<String, dynamic>.from(locData);
          
          // Populate the controllers with the resolved values
          widget.stateController.text = _resolvedLocation?['state'] ?? '';
          widget.cityController.text = _resolvedLocation?['city'] ?? '';
          widget.districtController.text = _resolvedLocation?['district'] ?? _resolvedLocation?['locality'] ?? '';
          widget.pincodeController.text = _resolvedLocation?['pincode'] ?? '';
          widget.countryController.text = _resolvedLocation?['country'] ?? 'INDIA';
          
          _isResolving = false;
        });
      } else {
        setState(() {
          _resolvedLocation = null;
          _errorMessage = response.data['message'] ?? 'Failed to resolve locality';
          _isResolving = false;
        });
        
        // Clear parent controllers on failure to avoid stale data submission
        widget.stateController.clear();
        widget.cityController.clear();
        widget.districtController.clear();
        widget.pincodeController.clear();
      }
    } catch (e) {
      setState(() {
        _resolvedLocation = null;
        _errorMessage = 'Error resolving location. Please check your internet connection.';
        _isResolving = false;
      });
      
      // Clear parent controllers on failure
      widget.stateController.clear();
      widget.cityController.clear();
      widget.districtController.clear();
      widget.pincodeController.clear();
    }
  }

  Widget _buildLocationDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ThemeStyle.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: ThemeStyle.primaryColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ThemeStyle.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: ThemeStyle.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.style;

    return theme.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showTitle) ...[
            Text(AppLocalizations.of(context, 'location_details'), style: theme.titleStyle),
            const SizedBox(height: 4),
            Text(
              'Enter your locality to automatically resolve full address details.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
          ],
          
          // Locality Input Field
          TextFormField(
            controller: _localityController,
            decoration: theme.inputDecoration(
              labelText: 'Locality',
              prefixIcon: Icons.location_on,
              suffixIcon: _isResolving
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(ThemeStyle.primaryColor),
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.search, color: ThemeStyle.primaryColor),
                      onPressed: _resolveLocality,
                    ),
              context: context,
              hintText: 'e.g. Kankanadi',
            ),
            onFieldSubmitted: (_) => _resolveLocality(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a locality';
              }
              if (_resolvedLocation == null && !_isResolving) {
                return 'Please search and verify your locality';
              }
              return null;
            },
          ),
          
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          if (_resolvedLocation != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ThemeStyle.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.green, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Location Verified',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20, thickness: 1),
                  _buildLocationDetailRow(
                    'Locality',
                    _resolvedLocation!['locality'] ?? '',
                    Icons.my_location,
                  ),
                  if (_resolvedLocation!['city'] != null && _resolvedLocation!['city'].toString().isNotEmpty)
                    _buildLocationDetailRow(
                      'City',
                      _resolvedLocation!['city'] ?? '',
                      Icons.location_city,
                    ),
                  if (_resolvedLocation!['taluk'] != null && _resolvedLocation!['taluk'].toString().isNotEmpty)
                    _buildLocationDetailRow(
                      'Taluk',
                      _resolvedLocation!['taluk'] ?? '',
                      Icons.explore,
                    ),
                  if (_resolvedLocation!['district'] != null && _resolvedLocation!['district'].toString().isNotEmpty)
                    _buildLocationDetailRow(
                      'District',
                      _resolvedLocation!['district'] ?? '',
                      Icons.map,
                    ),
                  if (_resolvedLocation!['state'] != null && _resolvedLocation!['state'].toString().isNotEmpty)
                    _buildLocationDetailRow(
                      'State',
                      _resolvedLocation!['state'] ?? '',
                      Icons.landscape,
                    ),
                  if (_resolvedLocation!['country'] != null && _resolvedLocation!['country'].toString().isNotEmpty)
                    _buildLocationDetailRow(
                      'Country',
                      _resolvedLocation!['country'] ?? '',
                      Icons.public,
                    ),
                  if (_resolvedLocation!['pincode'] != null && _resolvedLocation!['pincode'].toString().isNotEmpty)
                    _buildLocationDetailRow(
                      'Pincode',
                      _resolvedLocation!['pincode'] ?? '',
                      Icons.pin_drop,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
