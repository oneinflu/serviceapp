import 'dart:convert';

import 'package:app/providers/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../screens/subscription/congratulations_screen.dart';
import 'dart:io' show Platform;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class ServiceSubscriptionSheet extends StatefulWidget {
  final String serviceType;
  final int price;
  final List<String> benefits;
  final bool isPremium;

  const ServiceSubscriptionSheet({
    super.key,
    required this.serviceType,
    required this.price,
    required this.benefits,
    this.isPremium = false,
  });

  @override
  State<ServiceSubscriptionSheet> createState() =>
      _ServiceSubscriptionSheetState();
}

class _ServiceSubscriptionSheetState extends State<ServiceSubscriptionSheet> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    try {
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

      // Initialize WebView
      late final PlatformWebViewControllerCreationParams params;
      if (WebViewPlatform.instance is WebKitWebViewPlatform) {
        params = WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        );
      } else {
        params = const PlatformWebViewControllerCreationParams();
      }

      final WebViewController controller =
          WebViewController.fromPlatformCreationParams(params);

      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (NavigationRequest request) {
              // Check if the URL contains payment success parameters
              if (request.url.contains('razorpay_payment_id')) {
                final uri = Uri.parse(request.url);
                final paymentId = uri.queryParameters['razorpay_payment_id'];
                final orderId = uri.queryParameters['razorpay_order_id'];
                final signature = uri.queryParameters['razorpay_signature'];

                // Handle payment success
                _handlePaymentSuccess(
                  PaymentSuccessResponse(
                    paymentId ?? '',
                    orderId ?? '',
                    signature ?? '',
                    'success' as Map?, // Add the required fourth parameter
                  ),
                );

                // Close the dialog
                Navigator.of(context).pop();
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        );

      _webViewController = controller;
    } catch (e) {
      print('Initialization error: $e');
    }
  }

  // Add this variable to your class
  late final WebViewController _webViewController;

  @override
  void dispose() {
    try {
      _razorpay.clear(); // Removes all listeners
    } catch (e) {
      print('Error disposing Razorpay: $e');
    }
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      var data = json.encode({
        "razorpay_payment_id": response.paymentId,
        "razorpay_order_id": response.orderId,
        "razorpay_signature": response.signature,
        "subscriptionType": widget.serviceType.toUpperCase().replaceAll(
          ' ',
          '_',
        ),
      });

      var dio = Dio();
      var verifyResponse = await dio.request(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/payments/verify-payment',
        options: Options(method: 'POST', headers: headers),
        data: data,
      );

      if (verifyResponse.statusCode == 200) {
        print('Payment Verification Response:');
        print(json.encode(verifyResponse.data));

        // Close bottom sheet
        Navigator.pop(context);

        // Navigate to congratulations screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => CongratulationsScreen(
                  serviceType: widget.serviceType,
                  nextRoute:
                      widget.isPremium
                          ? '/service-post'
                          : '/${widget.serviceType.toLowerCase().replaceAll(' ', '-')}',
                ),
          ),
        );
      } else {
        throw Exception('Payment verification failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error verifying payment: $e')));
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External wallet selected: ${response.walletName}'),
      ),
    );
  }

  Future<void> _handleSubscription() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to subscribe')),
        );
        return;
      }

      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      var data = json.encode({
        "subscriptionType": widget.serviceType.toUpperCase().replaceAll(
          ' ',
          '_',
        ),
      });

      var dio = Dio();
      var response = await dio.request(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/payments/create-order',
        options: Options(method: 'POST', headers: headers),
        data: data,
      );

      if (response.statusCode == 200) {
        final orderData = response.data['data'];

        var options = {
          'key': orderData['key'],
          'amount': orderData['amount'],
          'currency': orderData['currency'],
          'name': orderData['name'],
          'description': orderData['description'],
          'order_id': orderData['order']['id'],
          'prefill': orderData['prefill'],
          'theme': {'color': '#2196F3'},
          'retry': {'enabled': true, 'max_count': 3},
          'send_sms_hash': true,
          'remember_customer': true,
          'timeout': 300, // 5 minutes
        };

        if (!kIsWeb) {
          _razorpay.open(options);
        } else {
          // For web platform, use Razorpay's standard checkout URL
          final baseUrl = 'https://checkout.razorpay.com/v1/checkout.js';
          final checkoutUrl =
              Uri.parse(baseUrl)
                  .replace(
                    queryParameters: {
                      'key': orderData['key'],
                      'amount': orderData['amount'].toString(),
                      'currency': orderData['currency'],
                      'name': orderData['name'],
                      'description': orderData['description'],
                      'order_id': orderData['order']['id'],
                      'callback_url':
                          'https://servicebackendnew-e2d8v.ondigitalocean.app/api/payments/verify-payment',
                      'prefill': json.encode(orderData['prefill']),
                    },
                  )
                  .toString();

          // Load the URL before showing the dialog
          await _webViewController.loadRequest(Uri.parse(checkoutUrl));

          // Show WebView in a dialog
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Dialog(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.8,
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      Expanded(
                        child: WebViewWidget(controller: _webViewController),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      }
    } catch (e) {
      print('Error in _handleSubscription: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating order: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Remove this line as it's causing the error
    // WebViewWidget(controller: _webViewController);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Service Type with Premium Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.serviceType,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              if (widget.isPremium)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'PREMIUM',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // First Post Free Badge
          if (widget.isPremium)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.green, size: 18),
                  SizedBox(width: 4),
                  Text(
                    'First Post FREE',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Price Display
          Container(
            margin: const EdgeInsets.symmetric(vertical: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Text(
                  '${widget.price}',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    height: 1,
                  ),
                ),
                Text(
                  '/year',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Benefits List
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                ...widget.benefits.map((benefit) => _buildBenefitItem(benefit)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Subscribe Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleSubscription,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                widget.isPremium ? 'Get Premium Access' : 'Subscribe Now',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.check,
              color: Theme.of(context).primaryColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// In your build method, update the WebView widget
