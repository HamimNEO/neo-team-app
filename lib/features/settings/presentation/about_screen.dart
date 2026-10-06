import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final platform = Theme.of(context).platform == TargetPlatform.iOS
        ? 'iOS'
        : Theme.of(context).platform == TargetPlatform.android
            ? 'Android'
            : 'Cross-platform';

    return Scaffold(
      backgroundColor: nec.bg,
      appBar: AppBar(
        backgroundColor: nec.bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    context.pop();
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios,
                      size: 16,
                      color: nec.brand,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Back',
                      style: TextStyle(
                        color: nec.brand,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  'About NEC TEAM',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: nec.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 68),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: nec.separator.withValues(alpha: 0.3),
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              const AppLogo(size: 72),
              const SizedBox(height: 16),
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: nec.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppConstants.appSubtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: nec.textTertiary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Version ${AppConstants.appVersion} (Build ${AppConstants.appBuildNumber})',
                style: TextStyle(
                  fontSize: 12,
                  color: nec.textTertiary,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: nec.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'NEC TEAM is the internal operational platform for NEONECY — designed to help field teams manage leads, follow-ups, visits, tasks, and issues efficiently from any location.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: nec.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Material(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _buildInfoRow(nec, 'Version', AppConstants.appVersion),
                    Divider(
                      height: 1,
                      color: nec.separator.withValues(alpha: 0.2),
                      indent: 16,
                    ),
                    _buildInfoRow(nec, 'Build', AppConstants.appBuildNumber),
                    Divider(
                      height: 1,
                      color: nec.separator.withValues(alpha: 0.2),
                      indent: 16,
                    ),
                    _buildInfoRow(nec, 'Platform', platform),
                    Divider(
                      height: 1,
                      color: nec.separator.withValues(alpha: 0.2),
                      indent: 16,
                    ),
                    _buildInfoRow(nec, 'Organization', 'NEONECY'),
                    Divider(
                      height: 1,
                      color: nec.separator.withValues(alpha: 0.2),
                      indent: 16,
                    ),
                    _buildInfoRow(nec, 'Planned by', AppConstants.plannedBy),
                    Divider(
                      height: 1,
                      color: nec.separator.withValues(alpha: 0.2),
                      indent: 16,
                    ),
                    _buildInfoRow(
                        nec, 'App Developer', AppConstants.mobileDeveloper),
                    Divider(
                      height: 1,
                      color: nec.separator.withValues(alpha: 0.2),
                      indent: 16,
                    ),
                    _buildInfoRow(nec, 'Backend Developer',
                        AppConstants.backendDeveloper),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                '© 2026 NEONECY. All rights reserved. NEC TEAM is an internal product. Unauthorized distribution is prohibited.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: nec.textTertiary,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(NecColors nec, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: nec.textPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: nec.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
