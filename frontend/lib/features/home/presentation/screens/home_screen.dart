import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/core/token_storage.dart';

import '../../../events/presentation/screens/pick_media_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _hasToken = false;
  bool _isLoadingAccount = true;
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    final token = await TokenStorage.read();
    if (!mounted) return;
    if (token == null) {
      setState(() {
        _hasToken = false;
        _isLoadingAccount = false;
      });
      return;
    }

    setState(() => _hasToken = true);
    try {
      final response = await dio.get('/auth/me');
      if (!mounted) return;
      setState(() {
        _role = response.data['role'] as String?;
        _isLoadingAccount = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingAccount = false;
        // Keep the signed-in banner while offline; never grant organizer UI
        // until the backend has confirmed the user's role.
        if (error.response?.statusCode == 401) _hasToken = false;
      });
    }
  }

  List<_HomeTab> get _tabs {
    final tabs = <_HomeTab>[
      const _HomeTab(label: 'Home', icon: Icons.home_outlined, selectedIcon: Icons.home,
          page: _EventFeed()),
      const _HomeTab(label: 'Explore', icon: Icons.explore_outlined, selectedIcon: Icons.explore,
          page: Center(child: Text('Explore events'))),
    ];

    if (_role == 'organizer') {
      tabs.add(const _HomeTab(label: 'Create', icon: Icons.add_box_outlined,
          selectedIcon: Icons.add_box, page: PickMediaScreen()));
    }

    if (_hasToken) {
      tabs.addAll(const [
        _HomeTab(label: 'Saved', icon: Icons.bookmark_border,
            selectedIcon: Icons.bookmark, page: Center(child: Text('Saved events'))),
        _HomeTab(label: 'Profile', icon: Icons.person_outline,
            selectedIcon: Icons.person, page: Center(child: Text('Your profile'))),
      ]);
    }
    return tabs;
  }

  String get _accountLabel {
    if (_isLoadingAccount) return 'Checking your account…';
    if (!_hasToken) return 'You are browsing as a guest.';
    switch (_role) {
      case 'student':
        return 'Signed in as a student.';
      case 'organizer':
        return 'Signed in as an organizer.';
      default:
        return 'You are signed in.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    final selectedIndex = _selectedIndex.clamp(0, tabs.length - 1).toInt();

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/JomIn_ExpandedLogo.png', height: 32),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                Icon(_hasToken ? Icons.account_circle_outlined : Icons.visibility_outlined,
                    size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_accountLabel)),
                if (!_hasToken && !_isLoadingAccount)
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Sign in'),
                  ),
              ],
            ),
          ),
          Expanded(child: tabs[selectedIndex].page),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: [
          for (final tab in tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}

class _EventFeed extends StatefulWidget {
  const _EventFeed();

  @override
  State<_EventFeed> createState() => _EventFeedState();
}

class _EventFeedState extends State<_EventFeed> {
  late Future<List<dynamic>> _posts;

  @override
  void initState() {
    super.initState();
    _posts = _loadPosts();
  }

  Future<List<dynamic>> _loadPosts() async {
    final response = await dio.get('/events');
    return response.data as List<dynamic>;
  }

  Future<void> _openRegistration(String? rawUrl) async {
    final uri = Uri.tryParse(rawUrl ?? '');
    if (uri == null || !{'http', 'https'}.contains(uri.scheme)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration link is not available yet.')),
      );
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the registration form.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _posts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not load event posts.'),
                TextButton(
                  onPressed: () => setState(() => _posts = _loadPosts()),
                  child: const Text('Try again'),
                ),
              ],
            ),
          );
        }
        final posts = snapshot.data ?? const [];
        if (posts.isEmpty) {
          return const Center(child: Text('No event posts yet. Check back soon.'));
        }
        return RefreshIndicator(
          onRefresh: () async => setState(() => _posts = _loadPosts()),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index] as Map<String, dynamic>;
              final registration = post['registration'] as Map<String, dynamic>?;
              final start = DateTime.tryParse(post['startTime'] as String? ?? '');
              return Card(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if ((post['mediaUrl'] as String? ?? '').isNotEmpty)
                      Image.network(
                        post['mediaUrl'] as String,
                        height: 190,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post['title'] as String? ?? 'Event',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 6),
                          Text('By ${post['organizerName'] ?? 'JomIn organizer'}'),
                          if (start != null) ...[
                            const SizedBox(height: 6),
                            Text(start.toLocal().toString().substring(0, 16)),
                          ],
                          if ((post['location'] as String? ?? '').isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(post['location'] as String),
                          ],
                          const SizedBox(height: 10),
                          Text(post['description'] as String? ?? ''),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.favorite_border, size: 18),
                              const SizedBox(width: 4),
                              Text('${post['likeCount'] ?? 0}'),
                              const SizedBox(width: 16),
                              const Icon(Icons.chat_bubble_outline, size: 18),
                              const SizedBox(width: 4),
                              Text('${post['commentCount'] ?? 0}'),
                              const Spacer(),
                              FilledButton(
                                onPressed: () => _openRegistration(
                                  registration?['targetUrl'] as String?,
                                ),
                                child: const Text('Register'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _HomeTab {
  const _HomeTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.page,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
}
