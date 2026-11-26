import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api_client.dart';
import '../../../../core/token_storage.dart';

class OnboardingInterestsScreen extends StatefulWidget {
  const OnboardingInterestsScreen({super.key});

  @override
  State<OnboardingInterestsScreen> createState() =>
      _OnboardingInterestsScreenState();
}

class _OnboardingInterestsScreenState extends State<OnboardingInterestsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  List<Map<String, String>> _interests = [];
  List<String> _roles = [];

  final Set<String> _selectedInterestIds = {};
  final Set<String> _selectedRoles = {};

  static const Map<String, String> _roleDescriptions = {
    'Activity': 'Games, flow & stage programs',
    'Multimedia': 'Posters, photography & video',
    'Food': 'Refreshments & catering',
    'Technical': 'AV, lighting & web/app tools',
    'Protocol': 'VIPs, emcee & ushering',
    'Sponsorship': 'External sponsors & funding',
  };

  @override
  void initState() {
    super.initState();
    _fetchOptions();
  }

  Future<Options> _authOptions() async {
    final token = await TokenStorage.read();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<void> _fetchOptions() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final res = await dio.get('/interests', options: await _authOptions());
      final data = Map<String, dynamic>.from(res.data as Map);

      final rawInterests = (data['interests'] as List<dynamic>? ?? []);
      final rawRoles = (data['roles'] as List<dynamic>? ?? []);

      if (!mounted) return;
      setState(() {
        _interests = rawInterests
            .map((e) => {
                  'id': e['id'].toString(),
                  'name': e['name'].toString(),
                })
            .toList();
        _roles = rawRoles.map((e) => e.toString()).toList();
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.response == null
            ? 'Cannot reach the server. Check your connection.'
            : 'Failed to load preferences. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitPreferences() async {
    if (_selectedInterestIds.isEmpty || _selectedRoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pick at least 1 interest and 1 role.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await dio.post(
        '/interests/me',
        data: {
          'interestIds': _selectedInterestIds.toList(),
          'roles': _selectedRoles.toList(),
        },
        options: await _authOptions(),
      );

      if (!mounted) return;
      context.go('/home');
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response == null
          ? 'Cannot reach the server.'
          : 'Could not save preferences. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canSubmit =
        _selectedInterestIds.isNotEmpty && _selectedRoles.isNotEmpty && !_isSaving;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalize JomIn'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => context.go('/home'),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_loadError!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _fetchOptions,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'What events excite you?',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Pick at least one category so we can tailor your For You feed.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: _interests.map((interest) {
                                  final id = interest['id']!;
                                  final name = interest['name']!;
                                  final selected =
                                      _selectedInterestIds.contains(id);
                                  return FilterChip(
                                    label: Text(name),
                                    selected: selected,
                                    onSelected: (val) {
                                      setState(() {
                                        if (val) {
                                          _selectedInterestIds.add(id);
                                        } else {
                                          _selectedInterestIds.remove(id);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                'Which committee roles interest you?',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Select the units you would like to explore or join.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: _roles.map((role) {
                                  final selected = _selectedRoles.contains(role);
                                  final desc = _roleDescriptions[role];
                                  return FilterChip(
                                    label: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          role,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (desc != null)
                                          Text(
                                            desc,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                      ],
                                    ),
                                    selected: selected,
                                    onSelected: (val) {
                                      setState(() {
                                        if (val) {
                                          _selectedRoles.add(role);
                                        } else {
                                          _selectedRoles.remove(role);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: canSubmit ? _submitPreferences : null,
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Save & Continue',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
