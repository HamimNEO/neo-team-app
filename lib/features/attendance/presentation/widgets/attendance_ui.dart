import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../domain/models/attendance_models.dart';

Color attendanceColor(AttendanceStatus status) => switch (status) {
      AttendanceStatus.present => const Color(0xFF30A46C),
      AttendanceStatus.working => AppColors.brandLight,
      AttendanceStatus.onBreak => AppColors.warning,
      AttendanceStatus.late ||
      AttendanceStatus.halfDay ||
      AttendanceStatus.shortDay =>
        AppColors.warning,
      AttendanceStatus.absent => AppColors.error,
      AttendanceStatus.leave => const Color(0xFF5856D6),
      AttendanceStatus.swappedOff => const Color(0xFF30B0C7),
      _ => AppColors.neutral,
    };

Color requestColor(AttendanceRequestStatus status) => switch (status) {
      AttendanceRequestStatus.pending => AppColors.warning,
      AttendanceRequestStatus.approved => AppColors.success,
      AttendanceRequestStatus.rejected => AppColors.error,
      AttendanceRequestStatus.cancelled => AppColors.neutral,
    };

class AttendanceBadge extends StatelessWidget {
  final String text;
  final Color color;

  const AttendanceBadge(this.text, this.color, {super.key});

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .13),
          borderRadius: BorderRadius.circular(8)),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)));
}

class AttendanceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const AttendanceCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) => SizedBox(
      width: double.infinity,
      child: Material(
          color: Theme.of(context).extension<NecColors>()!.surface,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: Padding(padding: padding, child: child)));
}

class AttendanceHeading extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const AttendanceHeading(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Row(children: [
        Expanded(
            child: Text(title.toUpperCase(),
                style: TextStyle(
                    color:
                        Theme.of(context).extension<NecColors>()!.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .7))),
        if (trailing != null) trailing!
      ]));
}

class AttendanceEmpty extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const AttendanceEmpty(
      {super.key,
      required this.title,
      required this.message,
      this.icon = CupertinoIcons.calendar});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return AttendanceCard(
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(children: [
              Icon(icon, color: nec.textTertiary, size: 38),
              const SizedBox(height: 12),
              Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: nec.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: nec.textSecondary, fontSize: 13, height: 1.5))
            ])));
  }
}

class AttendanceMetrics extends StatelessWidget {
  final List<(String, String, Color)> items;

  const AttendanceMetrics({super.key, required this.items});

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final nec = Theme.of(context).extension<NecColors>()!;
        final columns = constraints.maxWidth >= 650 ? 4 : 2;
        return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items
                .map((item) => SizedBox(
                    width:
                        (constraints.maxWidth - (columns - 1) * 10) / columns,
                    child: AttendanceCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.$2,
                                  style: TextStyle(
                                      color: item.$3,
                                      fontSize: 23,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 5),
                              Text(item.$1,
                                  style: TextStyle(
                                      color: nec.textSecondary, fontSize: 12)),
                            ]))))
                .toList());
      });
}

class AttendanceValues extends StatelessWidget {
  final List<(String, String)> rows;

  const AttendanceValues({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return AttendanceCard(
        child: Column(children: [
      for (var index = 0; index < rows.length; index++) ...[
        if (index > 0) Divider(height: 24, color: nec.separator),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              flex: 2,
              child: Text(rows[index].$1,
                  style: TextStyle(color: nec.textSecondary, fontSize: 13))),
          const SizedBox(width: 12),
          Expanded(
              flex: 3,
              child: Text(rows[index].$2,
                  textAlign: TextAlign.end,
                  style: TextStyle(color: nec.textPrimary, fontSize: 14))),
        ]),
      ],
    ]));
  }
}

PreferredSizeWidget attendanceAppBar(BuildContext context, String title,
    {List<Widget>? actions}) {
  final nec = Theme.of(context).extension<NecColors>()!;
  return AppBar(
      backgroundColor: nec.bg,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leadingWidth: 86,
      leading: CupertinoButton(
          padding: const EdgeInsets.only(left: 12),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/more');
            }
          },
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(CupertinoIcons.back, color: nec.brand, size: 17),
            Text(' Back', style: TextStyle(color: nec.brand, fontSize: 16)),
          ])),
      title: Text(title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: nec.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600)),
      actions: actions,
      bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: nec.separator)));
}

class AttendanceField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int maxLines;

  const AttendanceField(
      {super.key,
      required this.label,
      required this.controller,
      this.hint,
      this.validator,
      this.keyboardType = TextInputType.text,
      this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  color: nec.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 7),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            maxLines: maxLines,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: TextStyle(color: nec.textPrimary, fontSize: 15),
            decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: nec.bg,
                hintStyle: TextStyle(color: nec.textTertiary),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: nec.separator)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: nec.brand))),
          ),
        ]));
  }
}

class AttendancePickerRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final IconData icon;

  const AttendancePickerRow(
      {super.key,
      required this.label,
      required this.value,
      required this.onTap,
      this.icon = CupertinoIcons.chevron_down});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  color: nec.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 7),
          Material(
              color: nec.bg,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onTap,
                  child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          border: Border.all(color: nec.separator),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Expanded(
                            child: Text(value,
                                style: TextStyle(
                                    color: nec.textPrimary, fontSize: 15))),
                        const SizedBox(width: 8),
                        Icon(icon, color: nec.brand, size: 17)
                      ])))),
        ]));
  }
}

Future<T?> showAttendanceSheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Theme.of(context).extension<NecColors>()!.surface,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        clipBehavior: Clip.antiAlias,
        builder: (_) => SizedBox(
            height: MediaQuery.sizeOf(context).height * .9, child: child));

class AttendanceSheetBody extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const AttendanceSheetBody(
      {super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return SafeArea(
        child: Column(children: [
      const SizedBox(height: 10),
      Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
              color: nec.separator, borderRadius: BorderRadius.circular(4))),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            const SizedBox(width: 44),
            Expanded(
                child: Text(title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: nec.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600))),
            IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.pop(context),
                icon: Icon(CupertinoIcons.xmark_circle_fill,
                    color: nec.textTertiary, size: 23))
          ])),
      Divider(height: 1, color: nec.separator),
      Expanded(
          child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children))),
    ]));
  }
}

void attendanceError(BuildContext context, Object error) =>
    NecToast.show(context,
        message: error is FormatException
            ? error.message
            : 'This change could not be saved. Please try again.',
        type: NecToastType.error);
