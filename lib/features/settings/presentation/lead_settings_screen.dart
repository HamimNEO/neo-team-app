import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class LeadSettingsScreen extends StatelessWidget {
  const LeadSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

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
                  'Lead Settings',
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.brandLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: const Border(
                    left: BorderSide(
                      color: AppColors.brandLight,
                      width: 3.5,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lead Management Priority',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lead configuration directly affects sales operations. Changes apply to all new lead forms and workflows.',
                      style: TextStyle(
                        fontSize: 13,
                        color: nec.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(nec, 'LIFECYCLE'),
              Material(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    'Lead Statuses',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: nec.textPrimary,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      'Manage the status lifecycle and custom states',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: nec.textTertiary,
                      ),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '9',
                        style: TextStyle(
                          fontSize: 15,
                          color: nec.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: nec.textTertiary,
                      ),
                    ],
                  ),
                  onTap: () => context.push('/lead-statuses'),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(nec, 'CLASSIFICATION'),
              Material(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      title: Text(
                        'Lead Sources',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: nec.textPrimary,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          'Where leads come from — Facebook, Website, Referral...',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: nec.textTertiary,
                          ),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '9',
                            style: TextStyle(
                              fontSize: 15,
                              color: nec.textTertiary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            CupertinoIcons.chevron_right,
                            size: 16,
                            color: nec.textTertiary,
                          ),
                        ],
                      ),
                      onTap: () => context.push('/lead-sources'),
                    ),
                    Divider(
                      height: 1,
                      color: nec.separator.withValues(alpha: 0.2),
                      indent: 16,
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      title: Text(
                        'Business Types',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: nec.textPrimary,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          'Types of businesses for lead classification',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: nec.textTertiary,
                          ),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '7',
                            style: TextStyle(
                              fontSize: 15,
                              color: nec.textTertiary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            CupertinoIcons.chevron_right,
                            size: 16,
                            color: nec.textTertiary,
                          ),
                        ],
                      ),
                      onTap: () => context.push('/business-types'),
                    ),
                    Divider(
                      height: 1,
                      color: nec.separator.withValues(alpha: 0.2),
                      indent: 16,
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      title: Text(
                        'Lead Priorities',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: nec.textPrimary,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          'Low, Normal, High, Urgent — system defined',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: nec.textTertiary,
                          ),
                        ),
                      ),
                      trailing: Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: nec.textTertiary,
                      ),
                      onTap: () => context.push('/lead-priorities'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(nec, 'DATA'),
              Material(
                color: nec.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      title: Text(
                        'Custom Fields',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: nec.textPrimary,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          'Extend lead records with additional data fields',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: nec.textTertiary,
                          ),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '3',
                            style: TextStyle(
                              fontSize: 15,
                              color: nec.textTertiary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            CupertinoIcons.chevron_right,
                            size: 16,
                            color: nec.textTertiary,
                          ),
                        ],
                      ),
                      onTap: () => context.push('/custom-fields'),
                    ),
                    Divider(
                      height: 1,
                      color: nec.separator.withValues(alpha: 0.2),
                      indent: 16,
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      title: Text(
                        'Lost Reasons',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: nec.textPrimary,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          'Reasons for marking a lead as Lost',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: nec.textTertiary,
                          ),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '7',
                            style: TextStyle(
                              fontSize: 15,
                              color: nec.textTertiary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            CupertinoIcons.chevron_right,
                            size: 16,
                            color: nec.textTertiary,
                          ),
                        ],
                      ),
                      onTap: () => context.push('/lost-reasons'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(NecColors nec, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: nec.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
