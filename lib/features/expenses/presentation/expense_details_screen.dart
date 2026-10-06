import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nec_toast.dart';
import '../data/expense_store.dart';
import 'widgets/add_expense_sheet.dart';

class ExpenseDetailsScreen extends StatefulWidget {
  final String expenseId;

  const ExpenseDetailsScreen({super.key, required this.expenseId});

  @override
  State<ExpenseDetailsScreen> createState() => _ExpenseDetailsScreenState();
}

class _ExpenseDetailsScreenState extends State<ExpenseDetailsScreen> {
  @override
  void initState() {
    super.initState();
    ExpenseStore.instance.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ExpenseStore.instance.removeListener(_refresh);
    super.dispose();
  }

  void _editExpense() {
    final expense = ExpenseStore.instance.byId(widget.expenseId);
    if (expense == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddExpenseSheet(expense: expense),
    );
  }

  Future<void> _deleteExpense() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text('This expense record will be permanently deleted.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => ctx.pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => ctx.pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ExpenseStore.instance.deleteExpense(widget.expenseId);
      if (mounted) {
        NecToast.show(context,
            message: 'Expense deleted', type: NecToastType.info);
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final expense = ExpenseStore.instance.byId(widget.expenseId);

    if (expense == null) {
      return Scaffold(
        backgroundColor: nec.bg,
        appBar: AppBar(title: const Text('Expense Details')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.doc_text_search,
                  size: 48, color: nec.textTertiary),
              const SizedBox(height: 12),
              Text('Expense not found',
                  style: TextStyle(color: nec.textSecondary)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: nec.bg,
      appBar: AppBar(
        backgroundColor: nec.bg,
        title: Text(
          'Expense Details',
          style: TextStyle(
              color: nec.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.pencil, color: nec.brand, size: 20),
            onPressed: _editExpense,
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.trash,
                color: Colors.redAccent, size: 20),
            onPressed: _deleteExpense,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: nec.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: nec.separator),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: expense.category.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(expense.category.icon,
                        color: expense.category.color, size: 28),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    expense.formattedAmount,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: nec.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    expense.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: nec.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: expense.category.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          expense.category.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: expense.category.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: expense.status.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: expense.status.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              expense.status.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: expense.status.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: nec.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: nec.separator),
              ),
              child: Column(
                children: [
                  _infoRow(
                    nec,
                    icon: CupertinoIcons.calendar,
                    label: 'Date',
                    value:
                        '${expense.date.day} ${_monthName(expense.date.month)} ${expense.date.year}',
                  ),
                  _divider(nec),
                  _infoRow(
                    nec,
                    icon: CupertinoIcons.creditcard,
                    label: 'Payment Method',
                    value: expense.paymentMethod,
                  ),
                  _divider(nec),
                  _infoRow(
                    nec,
                    icon: CupertinoIcons.building_2_fill,
                    label: 'Vendor / Payee',
                    value: expense.vendor.isNotEmpty
                        ? expense.vendor
                        : 'Not specified',
                  ),
                  _divider(nec),
                  _infoRow(
                    nec,
                    icon: CupertinoIcons.person_circle,
                    label: 'Paid By',
                    value: expense.paidBy,
                  ),
                  if (expense.notes.isNotEmpty) ...[
                    _divider(nec),
                    _infoRow(
                      nec,
                      icon: CupertinoIcons.text_quote,
                      label: 'Notes',
                      value: expense.notes,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    NecColors nec, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: nec.textTertiary),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, color: nec.textSecondary)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: nec.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(NecColors nec) =>
      Divider(height: 1, indent: 46, color: nec.separator);

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return (month >= 1 && month <= 12) ? months[month - 1] : '';
  }
}
