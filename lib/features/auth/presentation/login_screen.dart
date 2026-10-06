import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_button.dart';
import '../../../core/services/demo_session.dart';
import 'widgets/auth_field.dart';
import 'widgets/auth_header.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleSignIn() async {
    if (_isLoading) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await DemoSession.instance
          .signIn(_emailController.text, _passwordController.text);
      if (mounted) {
        context.go('/home');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error is FormatException
            ? error.message
            : 'Unable to sign in. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final screenHeight = MediaQuery.of(context).size.height;
    final topBannerHeight = screenHeight * 0.35;

    return Scaffold(
      backgroundColor: nec.surface,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topBannerHeight + 60,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/others/login-banner.png',
                  fit: BoxFit.cover,
                ),
                Container(
                  color: Colors.black.withValues(alpha: 0.15),
                ),
              ],
            ),
          ),
          Column(
            children: [
              SizedBox(
                height: topBannerHeight,
                width: double.infinity,
                child: const SafeArea(
                  bottom: false,
                  child: Center(
                    child: AuthHeader(),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: nec.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: nec.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sign in to your account',
                            style: TextStyle(
                              fontSize: 15,
                              color: nec.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          AuthField(
                            label: 'Work Email',
                            hintText: 'you@neonecy.com',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          AuthField(
                            label: 'Password',
                            hintText: 'Enter your password',
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: nec.textTertiary,
                              ),
                              onPressed: () {
                                setState(
                                    () => _obscurePassword = !_obscurePassword);
                              },
                            ),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: nec.brand,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFFF3B30),
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          NecButton(
                            label: 'Sign In',
                            onPressed: _handleSignIn,
                            fullWidth: true,
                            loading: _isLoading,
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: Text(
                              'Access is restricted to NEONECY employees. Contact your administrator for an account.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: nec.textTertiary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
