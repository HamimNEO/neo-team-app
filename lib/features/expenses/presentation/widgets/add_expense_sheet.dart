import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_button.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../data/expense_store.dart';
import '../../domain/models/expense.dart';

class AddExpenseSheet extends StatefulWidget {
  final Expense? expense;

  const AddExpenseSheet({super.key, this.expense});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _vendorController;
  late final TextEditingController _paidByController;
  late final TextEditingController _notesController;

  late ExpenseCategory _selectedCategory;
  late DateTime _selectedDate;
  late String _selectedPaymentMethod;
  late ExpenseStatus _selectedStatus;
  bool _saving = false;

  final List<String> _paymentMethods = [
    'Bank Transfer',
    'Company Card',
    'bKash / Nagad',
    'Cash',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _titleController = TextEditingController(text: e?.title ?? '');
    _amountController = TextEditingController(
      text: e != null
          ? (e.amount % 1 == 0
              ? e.amount.toInt().toString()
              : e.amount.toStringAsFixed(2))
          : '',
    );
    _vendorController = TextEditingController(text: e?.vendor ?? '');
    _paidByController =
        TextEditingController(text: e?.paidBy ?? 'Company Account');
    _notesController = TextEditingController(text: e?.notes ?? '');

    _selectedCategory = e?.category ?? ExpenseCategory.office;
    _selectedDate = e?.date ?? DateTime.now();
    _selectedPaymentMethod = e?.paymentMethod ?? 'Bank Transfer';
    _selectedStatus = e?.status ?? ExpenseStatus.paid;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _vendorController.dispose();
    _paidByController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final rawAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (rawAmount <= 0) {
      NecToast.show(context,
          message: 'Please enter a valid amount.', type: NecToastType.error);
      return;
    }

    setState(() => _saving = true);

    try {
      final isEdit = widget.expense != null;
      final expense = Expense(
        id: widget.expense?.id ??
            'exp_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        amount: rawAmount,
        category: _selectedCategory,
        date: _selectedDate,
        paymentMethod: _selectedPaymentMethod,
        status: _selectedStatus,
        vendor: _vendorController.text.trim(),
        paidBy: _paidByController.text.trim().isNotEmpty
            ? _paidByController.text.trim()
            : 'Company Account',
        notes: _notesController.text.trim(),
      );

      if (isEdit) {
        await ExpenseStore.instance.updateExpense(expense);
      } else {
        await ExpenseStore.instance.addExpense(expense);
      }

      if (mounted) {
        NecToast.show(
          context,
          message: isEdit
              ? 'Expense updated successfully'
              : 'Expense recorded successfully',
          type: NecToastType.success,
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        NecToast.show(context,
            message: 'Failed to save expense: $e', type: NecToastType.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isEdit = widget.expense != null;
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight * 0.8,
      child: Container(
        decoration: BoxDecoration(
          color: nec.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 10),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: nec.separator,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9500)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              CupertinoIcons.money_dollar_circle_fill,
                              color: Color(0xFFFF9500),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isEdit ? 'Edit Expense' : 'Log New Expense',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: nec.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(CupertinoIcons.xmark_circle_fill,
                            size: 22, color: nec.textTertiary),
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Divider(height: 1, color: nec.separator),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expense Title *',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: nec.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Office Internet Bill or Client Lunch',
                          hintStyle:
                              TextStyle(color: nec.textTertiary, fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: nec.separator)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: nec.separator)),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Title is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Amount (BDT) *',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: nec.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                        ],
                        decoration: InputDecoration(
                          prefixText: '৳ ',
                          prefixStyle: TextStyle(
                              color: nec.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16),
                          hintText: '0.00',
                          hintStyle:
                              TextStyle(color: nec.textTertiary, fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: nec.separator)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: nec.separator)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Amount is required';
                          }
                          final num = double.tryParse(val.trim());
                          if (num == null || num <= 0) {
                            return 'Enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Category *',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: nec.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ExpenseCategory.values.map((cat) {
                          final isSel = _selectedCategory == cat;
                          return ChoiceChip(
                            avatar: Icon(cat.icon,
                                size: 14,
                                color: isSel ? Colors.white : cat.color),
                            label: Text(cat.label),
                            selected: isSel,
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isSel ? FontWeight.w600 : FontWeight.w500,
                              color: isSel ? Colors.white : nec.textPrimary,
                            ),
                            selectedColor: cat.color,
                            backgroundColor: nec.surfaceSecondary,
                            side: BorderSide(
                                color: isSel ? cat.color : nec.separator),
                            onSelected: (_) =>
                                setState(() => _selectedCategory = cat),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Expense Date',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: nec.textSecondary)),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: _pickDate,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: nec.separator),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(CupertinoIcons.calendar,
                                            size: 16, color: nec.brand),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: nec.textPrimary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Payment Status',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: nec.textSecondary)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: nec.separator),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<ExpenseStatus>(
                                      value: _selectedStatus,
                                      isExpanded: true,
                                      icon: Icon(CupertinoIcons.chevron_down,
                                          size: 14, color: nec.textTertiary),
                                      items: ExpenseStatus.values.map((s) {
                                        return DropdownMenuItem(
                                          value: s,
                                          child: Row(
                                            children: [
                                              Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                      color: s.color,
                                                      shape: BoxShape.circle)),
                                              const SizedBox(width: 6),
                                              Text(s.label,
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color: nec.textPrimary)),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _selectedStatus = val);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Payment Method',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: nec.textSecondary)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: nec.separator),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedPaymentMethod,
                                      isExpanded: true,
                                      icon: Icon(CupertinoIcons.chevron_down,
                                          size: 14, color: nec.textTertiary),
                                      items: _paymentMethods
                                          .map((m) => DropdownMenuItem(
                                              value: m,
                                              child: Text(m,
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color: nec.textPrimary))))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() =>
                                              _selectedPaymentMethod = val);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Vendor / Payee',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: nec.textSecondary)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _vendorController,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Star Tech',
                                    hintStyle: TextStyle(
                                        color: nec.textTertiary, fontSize: 13),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide:
                                            BorderSide(color: nec.separator)),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide:
                                            BorderSide(color: nec.separator)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Paid By / Account',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: nec.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _paidByController,
                        decoration: InputDecoration(
                          hintText:
                              'e.g. Company Account, Mahmud Hasan, Petty Cash',
                          hintStyle:
                              TextStyle(color: nec.textTertiary, fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: nec.separator)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: nec.separator)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Notes & Justification',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: nec.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText:
                              'Add invoice details, purpose, or remarks...',
                          hintStyle:
                              TextStyle(color: nec.textTertiary, fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: nec.separator)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: nec.separator)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      NecButton(
                        label: _saving
                            ? 'Saving...'
                            : (isEdit ? 'Update Expense' : 'Record Expense'),
                        fullWidth: true,
                        onPressed: _saving ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
