import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../theme/version_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Create scale animation for the logo
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    // Initialize version check and animation flow
    _initApp();
  }

  Future<void> _initApp() async {
    // Start animation
    _controller.forward();

    final startTime = DateTime.now();
    VersionCheckResult? result;

    try {
      result = await VersionConfig.checkAppVersion();
    } catch (e) {
      print('Splash version check error: $e');
    }

    // Ensure splash screen displays for at least 2.5 seconds
    final elapsed = DateTime.now().difference(startTime);
    final remainingDelay = const Duration(milliseconds: 2500) - elapsed;
    if (remainingDelay.inMilliseconds > 0) {
      await Future.delayed(remainingDelay);
    }

    if (!mounted) return;

    if (result != null && result.hasUpdate) {
      _showUpdateDialog(result);
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _showUpdateDialog(VersionCheckResult result) {
    showDialog(
      context: context,
      barrierDismissible: !result.forceUpdate,
      builder: (BuildContext context) {
        final theme = AppTheme.style;

        final dialogContent = Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ThemeStyle.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  size: 48,
                  color: ThemeStyle.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                result.forceUpdate ? 'Update Required' : 'Update Available',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: ThemeStyle.textPrimary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                result.forceUpdate
                    ? 'A new version of jirehservice is required to continue. Please update to version ${result.latestVersion} to proceed.'
                    : 'A new version of jirehservice (${result.latestVersion}) is available. Update now to experience new features and improvements.',
                style: const TextStyle(
                  fontSize: 14,
                  color: ThemeStyle.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              theme.buildPrimaryButton(
                text: 'Update Now',
                onPressed: () async {
                  final url = Uri.parse(result.updateUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              if (!result.forceUpdate) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                  child: Text(
                    'Later',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );

        if (result.forceUpdate) {
          return PopScope(
            canPop: false,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: dialogContent,
            ),
          );
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: dialogContent,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.style;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, ThemeStyle.backgroundColor],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: ThemeStyle.primaryColor.withOpacity(0.15),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ThemeStyle.primaryColor.withOpacity(0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/logo.jpeg',
                      width: 180,
                      height: 223,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(ThemeStyle.primaryColor),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
