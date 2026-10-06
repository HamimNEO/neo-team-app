import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/operations_settings_app_bar.dart';

class TaskSettingsScreen extends StatefulWidget {
  const TaskSettingsScreen({super.key});

  @override
  State<TaskSettingsScreen> createState() => _TaskSettingsScreenState();
}

class _TaskSettingsScreenState extends State<TaskSettingsScreen> {
  bool _taskReviewStage = true;

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

  Widget _buildPriorityRow(
    NecColors nec, {
    required String name,
    required Color color,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: nec.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'System',
                style: TextStyle(
                  fontSize: 13,
                  color: nec.textTertiary,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 0.5, color: nec.separator, indent: 16),
      ],
    );
  }

  Widget _buildTaskTypeRow(
    NecColors nec, {
    required String name,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              const Spacer(),
              Text(
                'System',
                style: TextStyle(
                  fontSize: 13,
                  color: nec.textTertiary,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 0.5, color: nec.separator, indent: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Scaffold(
      backgroundColor: nec.bg,
      appBar: const OperationsSettingsAppBar(title: 'Task Settings'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
        children: [
          _buildHeading(nec, 'WORKFLOW'),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Task Review Stage',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: nec.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Require review before task completion',
                          style: TextStyle(
                            fontSize: 12,
                            color: nec.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoSwitch(
                    value: _taskReviewStage,
                    activeTrackColor: AppColors.success,
                    onChanged: (val) => setState(() => _taskReviewStage = val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildHeading(nec, 'PRIORITIES'),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildPriorityRow(
                  nec,
                  name: 'Low',
                  color: nec.textTertiary,
                  showDivider: true,
                ),
                _buildPriorityRow(
                  nec,
                  name: 'Normal',
                  color: AppColors.brandLight,
                  showDivider: true,
                ),
                _buildPriorityRow(
                  nec,
                  name: 'High',
                  color: AppColors.warning,
                  showDivider: true,
                ),
                _buildPriorityRow(
                  nec,
                  name: 'Urgent',
                  color: AppColors.error,
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Task priorities are system-defined to maintain consistency.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: nec.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildHeading(nec, 'TASK TYPES'),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildTaskTypeRow(nec, name: 'Lead', showDivider: true),
                _buildTaskTypeRow(nec, name: 'Issue', showDivider: true),
                _buildTaskTypeRow(nec, name: 'Internal', showDivider: true),
                _buildTaskTypeRow(nec, name: 'Client', showDivider: false),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
