import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';  // Add this import
import 'wallet_dashboard_screen.dart';
import '../l10n/app_localizations.dart';

class ReferEarnScreen extends StatelessWidget {
  const ReferEarnScreen({super.key});

  void _shareApp(String referralCode) {
    final message =
        'Check out this amazing app! Download now and get exclusive benefits. Use my referral code: $referralCode';
    Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData;
    final referralCode =
        userData?['referralId'] ?? 'FRIEND2024'; // Get referralId from userData
    final theme = AppTheme.style;

    return theme.buildPageBackground(
      child: Scaffold(
        appBar: theme.buildAppBar(context, AppLocalizations.of(context, 'refer_earn')),
        drawer: const AppDrawer(),  // Add this line
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(ThemeStyle.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                theme.buildCard(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: theme.iconBoxDecoration(context),
                        child: const Icon(
                          Icons.card_giftcard,
                          size: ThemeStyle.iconSize * 1.5,
                          color: ThemeStyle.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context, 'refer_friends_earn'),
                        style: theme.headingStyle(context),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context, 'share_code_get_rewarded'),
                        style: theme.subtitleStyle,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                theme.buildCard(
                  child: Column(
                    children: [
                      Text(
                        AppLocalizations.of(context, 'your_referral_code'),
                        style: theme.titleStyle,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: ThemeStyle.dividerColor),
                          borderRadius: BorderRadius.circular(ThemeStyle.cardBorderRadius / 2),
                          color: Colors.grey[50],
                        ),
                        child: Text(
                          referralCode,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _shareApp(referralCode),
                  icon: const Icon(Icons.share),
                  label: Text(AppLocalizations.of(context, 'share_with_friends'), style: theme.buttonTextStyle),
                  style: theme.primaryButtonStyle(context),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WalletDashboardScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.account_balance_wallet),
                  label: Text(
                    AppLocalizations.of(context, 'go_to_wallet_dashboard'), 
                    style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                theme.buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context, 'how_it_works'),
                        style: theme.headingStyle(context).copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Text('1', style: TextStyle(color: Theme.of(context).primaryColor)),
                        ),
                        title: Text(AppLocalizations.of(context, 'share_code'), style: theme.titleStyle),
                        subtitle: Text(AppLocalizations.of(context, 'share_code_desc'), style: theme.subtitleStyle),
                      ),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Text('2', style: TextStyle(color: Theme.of(context).primaryColor)),
                        ),
                        title: Text(AppLocalizations.of(context, 'friends_join'), style: theme.titleStyle),
                        subtitle: Text(
                          AppLocalizations.of(context, 'friends_join_desc'),
                          style: theme.subtitleStyle,
                        ),
                      ),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Text('3', style: TextStyle(color: Theme.of(context).primaryColor)),
                        ),
                        title: Text(AppLocalizations.of(context, 'earn_rewards'), style: theme.titleStyle),
                        subtitle: Text(
                          AppLocalizations.of(context, 'earn_rewards_desc'),
                          style: theme.subtitleStyle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
