import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../core/theme/app_theme.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({
    super.key,
    required this.initialCheck,
    required this.isChecking,
    required this.onRetry,
  });

  final bool initialCheck;
  final bool isChecking;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<NecColors>()!;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final animationSize = math.min(
              340.0,
              math.min(constraints.maxWidth - 48, constraints.maxHeight * .43),
            );
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(0, constraints.maxHeight - 48),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: colors.brand.withValues(alpha: .09),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'NEC TEAM',
                            style: text.labelSmall?.copyWith(
                              color: colors.brand,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: animationSize,
                          height: animationSize,
                          child: ExcludeSemantics(
                            child: Lottie.asset(
                              'assets/others/Free no internet Animation  new.json',
                              fit: BoxFit.contain,
                              animate:
                                  !MediaQuery.of(context).disableAnimations,
                              errorBuilder: (context, error, stack) => Icon(
                                Icons.wifi_off_rounded,
                                size: 110,
                                color: colors.brand,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Semantics(
                          liveRegion: true,
                          header: true,
                          child: Text(
                            initialCheck
                                ? 'Checking your connection'
                                : 'No Internet Connection',
                            textAlign: TextAlign.center,
                            style: text.headlineMedium?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          initialCheck
                              ? 'Please wait while we check internet access to NEC TEAM.'
                              : 'An internet connection is required to use NEC TEAM. Please connect to Wi-Fi or mobile data to continue.',
                          textAlign: TextAlign.center,
                          style: text.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: colors.textSecondary,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: isChecking ? null : onRetry,
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.brand,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: isChecking
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colors.textSecondary,
                                    ),
                                  )
                                : const Icon(Icons.refresh_rounded, size: 20),
                            label: Text(
                              isChecking ? 'Checking connection…' : 'Try Again',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your previous screen will return automatically when your connection is restored.',
                          textAlign: TextAlign.center,
                          style: text.labelSmall?.copyWith(
                            fontSize: 12,
                            color: colors.textTertiary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
