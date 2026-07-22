import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';

const _baseUrl = 'https://servicebackendnew-e2d8v.ondigitalocean.app';

/// Design preview of the redesigned home screen, wired to the new
/// read-only /api/home/* endpoints (see servicebackend/routes/homeRoutes.js).
/// Not linked into any real flow yet — fold into home_screen.dart once approved.
class HomeScreenPreview extends StatefulWidget {
  const HomeScreenPreview({super.key});

  @override
  State<HomeScreenPreview> createState() => _HomeScreenPreviewState();
}

class _HomeScreenPreviewState extends State<HomeScreenPreview> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  bool _isLoading = true;
  List<dynamic> _suggestions = [];
  List<dynamic> _trending = [];
  List<dynamic> _professionals = [];
  List<dynamic> _recommendedJobs = [];
  List<dynamic> _recommendedServices = [];
  List<dynamic> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }

    final dio = Dio(BaseOptions(headers: {'Authorization': 'Bearer $token'}));

    final results = await Future.wait([
      _safeGet(dio, '/api/home/suggestions', 'suggestions'),
      _safeGet(dio, '/api/home/trending', 'trending'),
      _safeGet(dio, '/api/home/professionals-near-you', 'professionals'),
      _safeGet(dio, '/api/home/recommended-jobs', 'jobs'),
      _safeGet(dio, '/api/home/recommended-services', 'services'),
      _safeGet(dio, '/api/home/recent-activity', 'activity'),
    ]);

    if (!mounted) return;
    setState(() {
      _suggestions = results[0];
      _trending = results[1];
      _professionals = results[2];
      _recommendedJobs = results[3];
      _recommendedServices = results[4];
      _recentActivity = results[5];
      _isLoading = false;
    });
  }

  Future<List<dynamic>> _safeGet(Dio dio, String path, String key) async {
    try {
      final res = await dio.get('$_baseUrl$path');
      return (res.data['data'][key] as List<dynamic>?) ?? [];
    } catch (_) {
      return [];
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature — coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.style;
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData;
    final userName = userData?['name']?.toString().split(' ').first ?? 'there';

    return theme.buildPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: const AppDrawer(),
        appBar: AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: ThemeStyle.primaryColor),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Service',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
              ),
              Text(
                'infotek',
                style: TextStyle(color: ThemeStyle.primaryColor, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: ThemeStyle.primaryColor),
              onPressed: () => _comingSoon('Notifications'),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreetingAndSearch(theme, userName),
                if (!authProvider.isAuthenticated)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: theme.buildPrimaryButton(
                      text: 'Login to see suggestions, trending & more',
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                    ),
                  ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (authProvider.isAuthenticated) ...[
                  _buildAiSuggestions(theme),
                  theme.buildSectionHeader('Quick Actions'),
                  _buildQuickActions(theme),
                  theme.buildSectionHeader('Trending Near You'),
                  _buildTrending(theme),
                  theme.buildSectionHeader('Professionals Near You'),
                  _buildProfessionals(theme),
                  theme.buildSectionHeader('Recommended Jobs'),
                  _buildRecommendedList(theme, isJob: true),
                  theme.buildSectionHeader('Recommended Services'),
                  _buildRecommendedList(theme, isJob: false),
                  theme.buildSectionHeader('Recent Activity'),
                  _buildRecentActivity(theme),
                ] else ...[
                  theme.buildSectionHeader('Quick Actions'),
                  _buildQuickActions(theme),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingAndSearch(ThemeStyle theme, String userName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      decoration: BoxDecoration(
        gradient: theme.mainGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ThemeStyle.primaryColor.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_greeting, $userName 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'What do you need today?',
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 15),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search services, jobs...',
                prefixIcon: Icon(Icons.search, color: ThemeStyle.primaryColor.withOpacity(0.7)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _searchModeButton(Icons.mic_none_rounded, 'Speak', () => _comingSoon('Voice search')),
              _searchModeButton(Icons.document_scanner_outlined, 'Scan', () => _comingSoon('Scan search')),
              _searchModeButton(Icons.keyboard_alt_outlined, 'Type', () => _searchFocusNode.requestFocus()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _searchModeButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyHint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Text(text, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
    );
  }

  Widget _buildAiSuggestions(ThemeStyle theme) {
    if (_suggestions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('✨', style: TextStyle(fontSize: 16)),
              SizedBox(width: 6),
              Text('AI Suggestions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 20),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final s = _suggestions[index] as Map<String, dynamic>;
                final isJob = s['type'] == 'job';
                return ActionChip(
                  label: Text(s['label'] as String? ?? ''),
                  backgroundColor: ThemeStyle.primaryColor.withOpacity(0.08),
                  labelStyle: const TextStyle(color: ThemeStyle.primaryColor, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: ThemeStyle.primaryColor.withOpacity(0.15)),
                  ),
                  onPressed: () => Navigator.pushNamed(context, isJob ? '/job-search' : '/service-search'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeStyle theme) {
    final actions = [
      {'label': 'Service\nSearch', 'icon': Icons.search_rounded, 'route': '/service-search'},
      {'label': 'Job\nSearch', 'icon': Icons.work_outline_rounded, 'route': '/job-search'},
      {'label': 'Post\nService', 'icon': Icons.add_business_rounded, 'route': '/service-post'},
      {'label': 'Post\nJob', 'icon': Icons.post_add_rounded, 'route': '/job-post'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 2.2,
        children: actions.map((action) {
          return Container(
            decoration: theme.cardDecoration,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(ThemeStyle.cardBorderRadius),
                onTap: () => Navigator.pushNamed(context, action['route'] as String),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ThemeStyle.primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(action['icon'] as IconData, color: ThemeStyle.primaryColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          action['label'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, height: 1.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrending(ThemeStyle theme) {
    if (_trending.isEmpty) return _emptyHint('No trending categories yet in your area.');

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _trending.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final t = _trending[index] as Map<String, dynamic>;
          return ActionChip(
            avatar: const Icon(Icons.local_fire_department_rounded, size: 16, color: Colors.deepOrange),
            label: Text(t['name'] as String? ?? ''),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: ThemeStyle.cardBorder),
            ),
            onPressed: () => Navigator.pushNamed(context, '/service-search'),
          );
        },
      ),
    );
  }

  Widget _buildProfessionals(ThemeStyle theme) {
    if (_professionals.isEmpty) return _emptyHint('No service providers posted in your area yet.');

    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _professionals.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final pro = _professionals[index] as Map<String, dynamic>;
          final categories = (pro['categories'] as List<dynamic>? ?? [])
              .map((c) => (c as Map<String, dynamic>)['name'] as String? ?? '')
              .where((n) => n.isNotEmpty)
              .join(', ');
          final startingPrice = pro['startingPrice'];

          return Container(
            width: 220,
            decoration: theme.cardDecoration,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: ThemeStyle.primaryColor.withOpacity(0.1),
                      child: Icon(
                        pro['isCompanyPost'] == true ? Icons.business_rounded : Icons.person,
                        color: ThemeStyle.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (pro['providerName'] as String?)?.isNotEmpty == true
                                ? pro['providerName'] as String
                                : 'Provider',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            categories,
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        pro['locality'] as String? ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  startingPrice != null ? '₹$startingPrice onwards' : 'Contact for price',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: ThemeStyle.primaryColor),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _comingSoon('Booking'),
                    style: theme.primaryButtonStyle(context).copyWith(
                          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 10)),
                        ),
                    child: const Text('Book Now', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendedList(ThemeStyle theme, {required bool isJob}) {
    final items = isJob ? _recommendedJobs : _recommendedServices;
    if (items.isEmpty) {
      return _emptyHint(isJob ? 'No jobs posted yet.' : 'No services posted yet.');
    }

    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index] as Map<String, dynamic>;
          final categoryNames = isJob
              ? (item['categories'] as List<dynamic>? ?? [])
                  .map((c) => (c as Map<String, dynamic>)['name'] as String? ?? '')
                  .where((n) => n.isNotEmpty)
                  .join(', ')
              : (item['categoryPrices'] as List<dynamic>? ?? [])
                  .map((c) => ((c as Map<String, dynamic>)['category'] as Map<String, dynamic>?)?['name'] as String? ?? '')
                  .where((n) => n.isNotEmpty)
                  .join(', ');
          final city = (item['location'] as Map<String, dynamic>?)?['city'] as String? ?? '';
          final label = city.isNotEmpty ? '$categoryNames — $city' : categoryNames;

          return Container(
            width: 220,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: theme.cardDecoration,
            child: Row(
              children: [
                Icon(
                  isJob ? Icons.work_outline_rounded : Icons.home_repair_service_rounded,
                  color: ThemeStyle.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label.isNotEmpty ? label : (isJob ? 'Job listing' : 'Service listing'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _timeAgo(String? isoDate) {
    if (isoDate == null) return '';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildRecentActivity(ThemeStyle theme) {
    if (_recentActivity.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _emptyHint('No recent activity on your account yet.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: theme.cardDecoration,
        child: Column(
          children: List.generate(_recentActivity.length, (index) {
            final item = _recentActivity[index] as Map<String, dynamic>;
            final isJob = item['type'] == 'job_post';
            final isLast = index == _recentActivity.length - 1;
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 14,
                bottom: isLast ? 14 : 0,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        isJob ? Icons.post_add : Icons.design_services_outlined,
                        size: 18,
                        color: ThemeStyle.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isJob ? 'You posted a new job listing' : 'You posted a new service listing',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        _timeAgo(item['createdAt'] as String?),
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  if (!isLast) const Divider(height: 24, color: ThemeStyle.cardBorder),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
