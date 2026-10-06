import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_button.dart';
import '../../../core/widgets/nec_toast.dart';
import '../data/mock_system_roles.dart';
import '../domain/models/system_role.dart';

class NewRoleScreen extends StatefulWidget {
  const NewRoleScreen({super.key});

  @override
  State<NewRoleScreen> createState() => _NewRoleScreenState();
}

class _NewRoleScreenState extends State<NewRoleScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submitRole() {
    if (_nameController.text.trim().isEmpty) {
      NecToast.show(
        context,
        message: 'Please enter a role name',
        type: NecToastType.error,
      );
      return;
    }

    final newRole = SystemRoleItem(
      id: 'role_${DateTime.now().millisecondsSinceEpoch % 1000}',
      name: _nameController.text.trim(),
      badge: 'CUSTOM',
      description: _descController.text.trim().isEmpty
          ? 'Custom operational role'
          : _descController.text.trim(),
      memberCount: 0,
      iconColor: const Color(0xFF30B0C7),
      scope: 'Custom scope',
      lastUpdated: 'Today',
      memberNames: const [],
      modulePermissions: defaultModulePermissions,
    );

    if (Navigator.canPop(context)) {
      Navigator.pop(context, newRole);
    } else {
      context.pop(newRole);
    }

    NecToast.show(
      context,
      message: 'New role created successfully',
      type: NecToastType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  'New Role',
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ROLE NAME',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: nec.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? nec.surface
                      : nec.separator.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: nec.separator.withValues(alpha: 0.2),
                  ),
                ),
                child: TextField(
                  controller: _nameController,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: nec.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Senior Sales',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: nec.textTertiary,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'DESCRIPTION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: nec.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? nec.surface
                      : nec.separator.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: nec.separator.withValues(alpha: 0.2),
                  ),
                ),
                child: TextField(
                  controller: _descController,
                  maxLines: 4,
                  style: TextStyle(
                    fontSize: 14,
                    color: nec.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Brief description of this role\'s scope',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: nec.textTertiary,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              NecButton(
                label: 'Continue',
                onPressed: _submitRole,
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
