import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/api_client.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, this.token, this.email});

  final String? token;
  final String? email;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  late final TextEditingController _emailController;
  bool _isVerifying = false;
  bool _isResending = false;
  bool _verified = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email ?? '');
    if (widget.token != null && widget.token!.isNotEmpty) {
      _isVerifying = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _verify(widget.token!));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _verify(String token) async {
    setState(() {
      _isVerifying = true;
      _error = null;
    });
    try {
      await dio.post('/auth/verify-email', data: {'token': token});
      if (mounted) setState(() => _verified = true);
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _error = e.response?.statusCode == 409
            ? 'This verification link is invalid or has expired. Request a new one below.'
            : 'We could not verify your email. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter the email address you used to register.');
      return;
    }
    setState(() {
      _isResending = true;
      _error = null;
    });
    try {
      await dio.post('/auth/resend-verification', data: {'email': email});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('If the account is eligible, a new verification email is on its way.')),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _error = e.response == null
            ? 'Cannot reach the server. Please try again.'
            : 'Could not resend the email. Please try again shortly.');
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/images/JomIn_ExpandedLogo.png', height: 92),
                  const SizedBox(height: 28),
                  Icon(
                    _verified ? Icons.mark_email_read_outlined : Icons.mark_email_unread_outlined,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _verified ? 'Email verified' : 'Verify your email',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _verified
                        ? 'Your account is ready. Log in to continue.'
                        : 'We sent a verification link to your email. Open it on this device, or request a new link below.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (_isVerifying) ...[
                    const SizedBox(height: 24),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  if (!_verified) ...[
                    const SizedBox(height: 28),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: _isResending || _isVerifying ? null : _resend,
                      child: _isResending
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Resend verification email'),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isVerifying ? null : () => context.go('/login'),
                    child: Text(_verified ? 'Continue to login' : 'Back to login'),
                  ),
                  if (!_verified && widget.token == null)
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('I have already verified'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
