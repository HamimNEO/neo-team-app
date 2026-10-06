import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/operations_settings_app_bar.dart';

class IssueSettingsScreen extends StatefulWidget {
  const IssueSettingsScreen({super.key});

  @override
  State<IssueSettingsScreen> createState() => _IssueSettingsScreenState();
}

class _IssueSettingsScreenState extends State<IssueSettingsScreen> {
  bool _testingStage = true;
  bool _requireResolutionType = false;

  final Map<String, ({bool isCustom, bool enabled})> _categories = {
    'Bug': (isCustom: false, enabled: true),
    'Technical': (isCustom: false, enabled: true),
    'Customer Support': (isCustom: false, enabled: true),
    'Feature Request': (isCustom: false, enabled: true),
    'Payment': (isCustom: false, enabled: true),
    'Hotel / Client': (isCustom: false, enabled: true),
    'Mobile App': (isCustom: true, enabled: true),
    'Website': (isCustom: true, enabled: true),
    'Backend': (isCustom: true, enabled: true),
    'Other': (isCustom: false, enabled: true),
  };

  final List<String> _resolutionTypes = const [
    'Fixed',
    'Configuration Updated',
    'User Guidance',
    'Duplicate',
    'Unable to Reproduce',
  ];

  Widget _buildHeading(NecColors nec, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 0, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 0.7,
          fontWeight: FontWeight.w600,
          color: nec.textTertiary,
        ),
      ),
    );
  }

  Widget _buildBadge(NecColors nec, String text, bool isCustom) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isCustom
            ? AppColors.warning.withValues(alpha: 0.2)
            : nec.surfaceSecondary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isCustom ? AppColors.warning : nec.textTertiary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildWorkflowPill(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        name,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.error,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    final currentWorkflow = [
      'Reported',
      'Assigned',
      'In Progress',
      if (_testingStage) 'Testing',
      'Resolved',
      'Closed',
    ];

    return Scaffold(
      backgroundColor: nec.bg,
      appBar: const OperationsSettingsAppBar(title: 'Issue Settings'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
        children: [
          _buildHeading(nec, 'WORKFLOW'),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Testing Stage',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: nec.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Enable testing step before resolution',
                              style: TextStyle(
                                fontSize: 12,
                                color: nec.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CupertinoSwitch(
                        value: _testingStage,
                        activeTrackColor: AppColors.success,
                        onChanged: (val) => setState(() => _testingStage = val),
                      ),
                    ],
                  ),
                ),
                Divider(
                    height: 1,
                    thickness: 0.5,
                    color: nec.separator,
                    indent: 16),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Require Resolution Type',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: nec.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Select resolution type when closing an issue',
                              style: TextStyle(
                                fontSize: 12,
                                color: nec.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CupertinoSwitch(
                        value: _requireResolutionType,
                        activeTrackColor: AppColors.success,
                        onChanged: (val) =>
                            setState(() => _requireResolutionType = val),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENT WORKFLOW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: nec.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 8,
                    children: [
                      for (int i = 0; i < currentWorkflow.length; i++) ...[
                        _buildWorkflowPill(currentWorkflow[i]),
                        if (i < currentWorkflow.length - 1)
                          Text(
                            '›',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: nec.textTertiary,
                            ),
                          ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildHeading(nec, 'CATEGORIES'),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < _categories.entries.length; i++) ...[
                  () {
                    final entry = _categories.entries.elementAt(i);
                    final name = entry.key;
                    final isCustom = entry.value.isCustom;
                    final enabled = entry.value.enabled;
                    final isLast = i == _categories.entries.length - 1;

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: nec.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildBadge(
                                nec,
                                isCustom ? 'CUSTOM' : 'SYSTEM',
                                isCustom,
                              ),
                              const Spacer(),
                              CupertinoSwitch(
                                value: enabled,
                                activeTrackColor: AppColors.success,
                                onChanged: (val) {
                                  setState(() {
                                    _categories[name] =
                                        (isCustom: isCustom, enabled: val);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            color: nec.separator,
                            indent: 16,
                          ),
                      ],
                    );
                  }(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildHeading(nec, 'RESOLUTION TYPES'),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < _resolutionTypes.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Text(
                          _resolutionTypes[i],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: nec.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < _resolutionTypes.length - 1)
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: nec.separator,
                      indent: 16,
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
