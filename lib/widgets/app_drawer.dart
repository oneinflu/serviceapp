import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';
import '../screens/wallet_dashboard_screen.dart';
import '../l10n/app_localizations.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.style;
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isAuthenticated;
    final userData = authProvider.userData;

    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return Drawer(
          backgroundColor: Colors.white,
          child: Column(
            children: [
              if (isLoggedIn)
                Container(
                  padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
                  decoration: BoxDecoration(
                    gradient: theme.mainGradient,
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white,
                          backgroundImage: (userData?['profilePicUrl'] as String?)?.isNotEmpty == true
                              ? NetworkImage(userData!['profilePicUrl'] as String)
                              : null,
                          child: (userData?['profilePicUrl'] as String?)?.isNotEmpty != true
                              ? Text(
                                  (userData?['name'] as String?)?.isNotEmpty == true
                                      ? userData!['name'][0].toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: ThemeStyle.primaryColor,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userData?['name'] ?? 'User Name',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              userData?['email'] ?? 'email@example.com',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: theme.mainGradient,
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Serviceinfotek',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _buildListTile(
                      context: context,
                      icon: Icons.home_rounded,
                      title: AppLocalizations.of(context, 'home'),
                      onTap: () => Navigator.pushReplacementNamed(context, '/home'),
                    ),
                    _buildListTile(
                      context: context,
                      icon: Icons.person_rounded,
                      title: 'Edit Profile',
                      enabled: isLoggedIn,
                      onTap: isLoggedIn ? () => Navigator.pushNamed(context, '/edit-profile') : null,
                    ),
                    _buildListTile(
                      context: context,
                      icon: Icons.language_rounded,
                      title: AppLocalizations.of(context, 'change_language'),
                      onTap: () => Navigator.pushNamed(context, '/language'),
                    ),
                    _buildListTile(
                      context: context,
                      icon: Icons.stars_rounded,
                      title: AppLocalizations.of(context, 'refer_earn'),
                      enabled: isLoggedIn,
                      onTap: isLoggedIn ? () => Navigator.pushNamed(context, '/refer') : null,
                    ),
                    _buildListTile(
                      context: context,
                      icon: Icons.account_balance_wallet_rounded,
                      title: AppLocalizations.of(context, 'wallet_dashboard'),
                      enabled: isLoggedIn,
                      onTap: isLoggedIn ? () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const WalletDashboardScreen()),
                        );
                      } : null,
                    ),
                    _buildListTile(
                      context: context,
                      icon: Icons.business_center_rounded,
                      title: AppLocalizations.of(context, 'company_info'),
                      enabled: isLoggedIn,
                      onTap: isLoggedIn ? () => Navigator.pushNamed(context, '/company-list') : null,
                    ),
                    _buildListTile(
                      context: context,
                      icon: Icons.loyalty_rounded,
                      title: AppLocalizations.of(context, 'my_subscriptions'),
                      enabled: isLoggedIn,
                      onTap: isLoggedIn ? () => Navigator.pushNamed(context, '/my-subscriptions') : null,
                    ),
                    _buildListTile(
                      context: context,
                      icon: Icons.receipt_long_rounded,
                      title: AppLocalizations.of(context, 'payment_history'),
                      enabled: isLoggedIn,
                      onTap: isLoggedIn ? () => Navigator.pushNamed(context, '/payment-history') : null,
                    ),
                    _buildListTile(
                      context: context,
                      icon: Icons.work_rounded,
                      title: AppLocalizations.of(context, 'my_job_posts'),
                      enabled: isLoggedIn,
                      onTap: isLoggedIn ? () => Navigator.pushNamed(context, '/my-job-posts') : null,
                    ),
                    _buildListTile(
                      context: context,
                      icon: Icons.design_services_rounded,
                      title: AppLocalizations.of(context, 'my_service_posts'),
                      enabled: isLoggedIn,
                      onTap: isLoggedIn ? () => Navigator.pushNamed(context, '/my-service-posts') : null,
                    ),
                    _buildListTile(
                      context: context,
                      icon: Icons.delete_forever_rounded,
                      title: AppLocalizations.of(context, 'delete_account'),
                      enabled: isLoggedIn,
                      onTap: isLoggedIn
                          ? () async {
                            final url = Uri.parse('https://serviceinfotek.com/delete-account.html');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          }
                          : null,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
                      child: Divider(color: Color(0xFFF1F5F9)),
                    ),
                    _buildListTile(
                      context: context,
                      icon: Icons.description_rounded,
                      title: AppLocalizations.of(context, 'terms_conditions'),
                      onTap: () => Navigator.pushNamed(context, '/terms'),
                    ),
                    _buildListTile(
                      context: context,
                      icon: Icons.info_rounded,
                      title: AppLocalizations.of(context, 'about_app'),
                      onTap: () => Navigator.pushNamed(context, '/about'),
                    ),
                    const SizedBox(height: 10),
                    if (isLoggedIn)
                      _buildListTile(
                        context: context,
                        icon: Icons.logout_rounded,
                        title: AppLocalizations.of(context, 'logout'),
                        onTap: () async {
                          await authProvider.logout();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(context, '/login');
                          }
                        },
                      )
                    else ...[
                      _buildListTile(
                        context: context,
                        icon: Icons.login_rounded,
                        title: AppLocalizations.of(context, 'login'),
                        onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                      ),
                      _buildListTile(
                        context: context,
                        icon: Icons.person_add_rounded,
                        title: AppLocalizations.of(context, 'register'),
                        onTap: () => Navigator.pushReplacementNamed(context, '/register'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    final theme = AppTheme.style;
    final Color itemColor = enabled ? ThemeStyle.textPrimary : Colors.grey.shade400;
    final Color iconColor = enabled ? ThemeStyle.primaryColor : Colors.grey.shade400;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 24),
        title: Text(
          title,
          style: TextStyle(
            color: itemColor,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        enabled: enabled,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        visualDensity: const VisualDensity(vertical: -1),
      ),
    );
  }

  // Add this after "My Service Posts" and before "Terms & Conditions"
}
