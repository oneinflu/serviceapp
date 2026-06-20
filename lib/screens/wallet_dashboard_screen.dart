import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'payout_details_screen.dart';

class WalletDashboardScreen extends StatefulWidget {
  const WalletDashboardScreen({super.key});

  @override
  State<WalletDashboardScreen> createState() => _WalletDashboardScreenState();
}

class _WalletDashboardScreenState extends State<WalletDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  bool isLoadingSummary = true;
  String? errorSummary;
  Map<String, dynamic>? summaryData;

  bool isLoadingTree = true;
  String? errorTree;
  List<dynamic> treeData = [];

  bool isLoadingCommissions = true;
  String? errorCommissions;
  List<dynamic> commissionsData = [];

  bool isLoadingTransactions = true;
  String? errorTransactions;
  List<dynamic> transactionsData = [];

  bool isWithdrawing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _loadTabData(_tabController.index);
      }
    });
    _loadTabData(0);
  }

  void _loadTabData(int index) {
    if (index == 0 && summaryData == null) fetchSummary();
    if (index == 1 && treeData.isEmpty) fetchTree();
    if (index == 2 && commissionsData.isEmpty) fetchCommissions();
    if (index == 3 && transactionsData.isEmpty) fetchTransactions();
  }

  Future<void> fetchSummary() async {
    try {
      setState(() { isLoadingSummary = true; errorSummary = null; });
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final response = await Dio().get(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/referrals/my-summary',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        setState(() {
          summaryData = response.data['data'];
          isLoadingSummary = false;
        });
      }
    } catch (e) {
      setState(() { errorSummary = e.toString(); isLoadingSummary = false; });
    }
  }

  Future<void> fetchTree() async {
    try {
      setState(() { isLoadingTree = true; errorTree = null; });
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final response = await Dio().get(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/referrals/my-tree?page=1&limit=50',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        setState(() {
          treeData = response.data['data']['tree'] ?? [];
          isLoadingTree = false;
        });
      }
    } catch (e) {
      setState(() { errorTree = e.toString(); isLoadingTree = false; });
    }
  }

  Future<void> fetchCommissions() async {
    try {
      setState(() { isLoadingCommissions = true; errorCommissions = null; });
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final response = await Dio().get(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/referrals/my-commissions?page=1&limit=50',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        setState(() {
          commissionsData = response.data['data']['commissions'] ?? [];
          isLoadingCommissions = false;
        });
      }
    } catch (e) {
      setState(() { errorCommissions = e.toString(); isLoadingCommissions = false; });
    }
  }

  Future<void> fetchTransactions() async {
    try {
      setState(() { isLoadingTransactions = true; errorTransactions = null; });
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final response = await Dio().get(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/wallet/my-transactions',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        setState(() {
          transactionsData = response.data['data']['transactions'] ?? [];
          isLoadingTransactions = false;
        });
      }
    } catch (e) {
      setState(() { errorTransactions = e.toString(); isLoadingTransactions = false; });
    }
  }

  Future<void> requestWithdrawal() async {
    try {
      setState(() => isWithdrawing = true);
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      await Dio().post(
        'https://servicebackendnew-e2d8v.ondigitalocean.app/api/wallet/withdrawals/request',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context, 'withdrawal_requested')), backgroundColor: Colors.green));
      fetchSummary();
      fetchTransactions();
    } on DioException catch (e) {
      String msg = AppLocalizations.of(context, 'failed_to_request_withdrawal');
      if (e.response?.data != null && e.response?.data['message'] != null) {
        msg = e.response?.data['message'];
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    } finally {
      setState(() => isWithdrawing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.style;

    return theme.buildPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context, 'wallet_referrals'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Theme.of(context).primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.account_balance_outlined, color: Colors.white),
              tooltip: 'Payout Details',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PayoutDetailsScreen()),
                ).then((value) {
                  if (value == true) {
                    fetchSummary();
                  }
                });
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14.0),
            tabs: [
              Tab(text: AppLocalizations.of(context, 'overview')),
              Tab(text: AppLocalizations.of(context, 'network')),
              Tab(text: AppLocalizations.of(context, 'commissions')),
              Tab(text: AppLocalizations.of(context, 'transactions')),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(theme),
            _buildNetworkTab(theme),
            _buildCommissionsTab(theme),
            _buildTransactionsTab(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(dynamic theme) {
    if (isLoadingSummary) return Center(child: theme.loadingIndicator(color: Theme.of(context).primaryColor));
    if (errorSummary != null) return Center(child: Text('Error: $errorSummary'));
    
    return RefreshIndicator(
      onRefresh: fetchSummary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWalletCard(theme),
            const SizedBox(height: 24),
            _buildReferralStatsCard(theme),
            const SizedBox(height: 24),
            _buildLevelsCard(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCard(dynamic theme) {
    final balance = (summaryData?['walletBalance'] ?? 0).toDouble();
    final totalEarned = (summaryData?['totalEarned'] ?? 0).toDouble();
    final pending = (summaryData?['pendingWithdrawalAmount'] ?? 0).toDouble();
    final minWithdrawal = (summaryData?['minWithdrawal'] ?? 200).toDouble();
    final hasPending = summaryData?['hasPendingWithdrawal'] == true;
    
    final canWithdraw = balance >= minWithdrawal && !hasPending;

    return theme.buildCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(AppLocalizations.of(context, 'wallet_balance'), style: theme.subtitleStyle),
          const SizedBox(height: 8),
          Text(
            '₹$balance',
            style: TextStyle(
              fontSize: 32.0,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(theme, AppLocalizations.of(context, 'total_earned'), '₹$totalEarned', Icons.account_balance_wallet),
              _buildStatItem(theme, AppLocalizations.of(context, 'pending'), '₹$pending', Icons.hourglass_empty),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isWithdrawing || !canWithdraw ? null : requestWithdrawal,
              style: ElevatedButton.styleFrom(
                backgroundColor: canWithdraw ? Theme.of(context).primaryColor : Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isWithdrawing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      hasPending ? AppLocalizations.of(context, 'withdrawal_pending') : AppLocalizations.of(context, 'withdraw_balance'),
                      style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          if (balance < minWithdrawal && !hasPending)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '${AppLocalizations.of(context, 'min_withdrawal_is')}$minWithdrawal',
                style: const TextStyle(color: Colors.red, fontSize: 12.0),
              ),
            ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PayoutDetailsScreen()),
              ).then((value) {
                if (value == true) {
                  fetchSummary();
                }
              });
            },
            icon: Icon(Icons.edit_note, color: Theme.of(context).primaryColor),
            label: Text(
              'Manage Payout Details',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 14.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralStatsCard(dynamic theme) {
    final count = summaryData?['referralCount'] ?? 0;
    final refId = summaryData?['referralId'] ?? 'N/A';
    
    return theme.buildCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: Theme.of(context).primaryColor, size: 20.0),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context, 'referral_overview'), style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context, 'total_referrals'), style: theme.subtitleStyle),
              Text('$count', style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context, 'your_code'), style: theme.subtitleStyle),
              Text(
                refId,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelsCard(dynamic theme) {
    final levels = summaryData?['byLevel'] as List? ?? [];
    
    return theme.buildCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree, color: Theme.of(context).primaryColor, size: 20.0),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context, 'earnings_by_level'), style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          const Divider(height: 24),
          if (levels.isEmpty)
            Text(AppLocalizations.of(context, 'no_level_earnings_yet'), style: theme.subtitleStyle)
          else
            ...levels.map((level) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${AppLocalizations.of(context, 'level')} ${level['level']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
                        Text('${level['count']} ${AppLocalizations.of(context, 'referrals')}', style: theme.subtitleStyle),
                      ],
                    ),
                    Text(
                      '₹${level['total']}',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildNetworkTab(dynamic theme) {
    if (isLoadingTree) return Center(child: theme.loadingIndicator(color: Theme.of(context).primaryColor));
    if (errorTree != null) return Center(child: Text('Error: $errorTree'));
    
    if (treeData.isEmpty) {
      final referralCode = summaryData?['referralId'] ?? 
                           Provider.of<AuthProvider>(context, listen: false).userData?['referralId'] ?? 
                           'N/A';

      return RefreshIndicator(
        onRefresh: () async {
          await fetchSummary();
          await fetchTree();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.group_add_outlined,
                    size: 64,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Start Building Your Network!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Share your referral code with friends and colleagues to earn commissions when they join the platform!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (referralCode != 'N/A') ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'YOUR REFERRAL CODE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            referralCode,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: referralCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context, 'copied_to_clipboard')),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: Icon(Icons.copy, color: Theme.of(context).primaryColor),
                        tooltip: AppLocalizations.of(context, 'tap_to_copy'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    final message = 'Check out this amazing app! Download now and get exclusive benefits. Use my referral code: $referralCode';
                    Share.share(message);
                  },
                  icon: const Icon(Icons.share, size: 18, color: Colors.white),
                  label: const Text(
                    'Share Code',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchTree,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: treeData.length,
        itemBuilder: (context, index) {
          return _buildTreeNode(treeData[index], theme);
        },
      ),
    );
  }

  Widget _buildTreeNode(Map<String, dynamic> node, dynamic theme) {
    final children = node['children'] as List? ?? [];
    final name = node['name'] ?? 'Unknown';
    final level = node['level'] ?? 1;

    if (children.isEmpty) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1), child: Text('L$level', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold))),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(node['email'] ?? ''),
          trailing: Text(node['referralId'] ?? '', style: const TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1), child: Text('L$level', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold))),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(node['email'] ?? ''),
        children: children.map((child) => Padding(
          padding: const EdgeInsets.only(left: 32.0),
          child: _buildTreeNode(child as Map<String, dynamic>, theme),
        )).toList(),
      ),
    );
  }

  Widget _buildCommissionsTab(dynamic theme) {
    if (isLoadingCommissions) return Center(child: theme.loadingIndicator(color: Theme.of(context).primaryColor));
    if (errorCommissions != null) return Center(child: Text('Error: $errorCommissions'));
    
    if (commissionsData.isEmpty) {
      final referralCode = summaryData?['referralId'] ?? 
                           Provider.of<AuthProvider>(context, listen: false).userData?['referralId'] ?? 
                           'N/A';

      return RefreshIndicator(
        onRefresh: () async {
          await fetchSummary();
          await fetchCommissions();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.monetization_on_outlined,
                    size: 64,
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Commission Earnings Yet!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Once your network referrals purchase subscriptions or publish premium postings, your commissions will be calculated and paid out instantly here!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (referralCode != 'N/A') ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SHARE YOUR CODE TO START EARNING',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            referralCode,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: referralCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context, 'copied_to_clipboard')),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: Icon(Icons.copy, color: Theme.of(context).primaryColor),
                        tooltip: AppLocalizations.of(context, 'tap_to_copy'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    final message = 'Check out this amazing app! Download now and get exclusive benefits. Use my referral code: $referralCode';
                    Share.share(message);
                  },
                  icon: const Icon(Icons.share, size: 18, color: Colors.white),
                  label: const Text(
                    'Share Code & Invite',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchCommissions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: commissionsData.length,
        itemBuilder: (context, index) {
          final comm = commissionsData[index];
          final sourceUser = comm['sourceUser'] ?? {};
          final name = sourceUser['name'] ?? AppLocalizations.of(context, 'unknown_user');
          final amount = comm['amount'] ?? 0;
          final level = comm['level'] ?? 1;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.attach_money, color: Colors.white)),
              title: Text('${AppLocalizations.of(context, 'commission_from')} $name', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${AppLocalizations.of(context, 'level')} $level ${AppLocalizations.of(context, 'referral')}'),
              trailing: Text('+₹$amount', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16.0)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionsTab(dynamic theme) {
    if (isLoadingTransactions) return Center(child: theme.loadingIndicator(color: Theme.of(context).primaryColor));
    if (errorTransactions != null) return Center(child: Text('Error: $errorTransactions'));
    
    if (transactionsData.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await fetchSummary();
          await fetchTransactions();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Center(
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'No Transaction History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'You haven\'t made any withdrawal requests or payout transactions yet. When you request a withdrawal, your complete history will appear right here!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchTransactions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: transactionsData.length,
        itemBuilder: (context, index) {
          final tx = transactionsData[index];
          final amount = tx['amount'] ?? 0;
          final status = tx['status'] ?? 'unknown';
          
          Color statusColor = Colors.grey;
          IconData icon = Icons.help_outline;
          
          if (status == 'requested' || status == 'pending') {
            statusColor = Colors.orange;
            icon = Icons.pending_actions;
          } else if (status == 'paid' || status == 'completed') {
            statusColor = Colors.green;
            icon = Icons.check_circle;
          } else if (status == 'failed' || status == 'rejected') {
            statusColor = Colors.red;
            icon = Icons.cancel;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: statusColor.withOpacity(0.1), child: Icon(icon, color: statusColor)),
              title: Text(AppLocalizations.of(context, 'withdraw_balance'), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Status: ${status.toUpperCase()}', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
              trailing: Text('-₹$amount', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16.0)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(dynamic theme, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20.0),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: theme.subtitleStyle.copyWith(fontSize: 12.0)),
      ],
    );
  }
}
