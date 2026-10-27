import 'package:file_picker/file_picker.dart';
import '../../../../core/network/api_client.dart';
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
  ApiUpload? _receipt;

  Future<void> _pickReceipt() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
          withData: true);
      if (picked == null || !mounted) return;
      final file = picked.files.single;
      if (file.bytes == null || file.size > 10 * 1024 * 1024) {
        throw const FormatException('Choose a receipt up to 10 MB.');
      }
      setState(() => _receipt = ApiUpload(
          field: 'receipt',
          bytes: file.bytes!,
          filename: file.name,
          mimeType: file.extension?.toLowerCase() == 'pdf'
              ? 'application/pdf'
              : file.extension?.toLowerCase() == 'png'
                  ? 'image/png'
                  : 'image/jpeg'));
    } catch (e) {
      if (mounted) {
        NecToast.show(context,
            message: e is FormatException
                ? e.message
                : 'Receipt could not be selected.',
            type: NecToastType.error);
      }
    }
  }

  final List<String> _paymentMethods = [
    'Bank Transfer',
    'Company Card',
    'bKash',
    'Nagad',
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
    _paidByController = TextEditingController(text: e?.paidBy ?? '');
    _notesController = TextEditingController(text: e?.notes ?? '');

    _selectedCategory = e?.category ?? ExpenseCategory.office;
    _selectedDate = e?.date ?? DateTime.now();
    _selectedPaymentMethod = {
          'bank_transfer': 'Bank Transfer',
          'company_card': 'Company Card',
          'bkash': 'bKash',
          'nagad': 'Nagad',
          'cash': 'Cash'
        }[e?.paymentMethod] ??
        e?.paymentMethod ??
        'Bank Transfer';
    if (!_paymentMethods.contains(_selectedPaymentMethod)) {
      _paymentMethods.add(_selectedPaymentMethod);
    }
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
        id: widget.expense?.id ?? '',
        title: _titleController.text.trim(),
        amount: rawAmount,
        category: _selectedCategory,
        date: _selectedDate,
        paymentMethod: _selectedPaymentMethod,
        status: _selectedStatus,
        vendor: _vendorController.text.trim(),
        paidBy: _paidByController.text.trim(),
        notes: _notesController.text.trim(),
      );

      if (isEdit) {
        await ExpenseStore.instance.updateExpense(expense, receipt: _receipt);
      } else {
        await ExpenseStore.instance.addExpense(expense, receipt: _receipt);
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

  InputDecoration _inputDec({
    required NecColors nec,
    required String hintText,
    String? prefixText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: nec.surfaceSecondary.withValues(alpha: 0.6),
      isDense: true,
      prefixText: prefixText,
      prefixIcon: prefixIcon,
      prefixStyle: TextStyle(
        color: nec.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
      hintText: hintText,
      hintStyle: TextStyle(
        color: nec.textTertiary.withValues(alpha: 0.75),
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: nec.separator.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: nec.separator.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: nec.brand, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: CupertinoColors.systemRed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isEdit = widget.expense != null;
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight * 0.88,
      child: Container(
        decoration: BoxDecoration(
          color: nec.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 10),
                decoration: BoxDecoration(
                  color: nec.separator.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9500).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.money_dollar_circle_fill,
                      color: Color(0xFFFF9500),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Edit Expense' : 'Log New Expense',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: nec.textPrimary,
                          ),
                        ),
                        Text(
                          'Company financials & expenses',
                          style:
                              TextStyle(fontSize: 11, color: nec.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: nec.surfaceSecondary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(CupertinoIcons.xmark,
                          size: 13, color: nec.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: nec.separator.withValues(alpha: 0.25)),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  14,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expense Title *',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: nec.textSecondary),
                      ),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: _titleController,
                        decoration: _inputDec(
                          nec: nec,
                          hintText: 'e.g. Internet Bill',
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Title is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Amount (BDT) *',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: nec.textSecondary),
                      ),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                        ],
                        decoration: _inputDec(
                          nec: nec,
                          prefixText: '৳ ',
                          hintText: '0.00',
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
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Category *',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: nec.textSecondary),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: nec.brand.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _selectedCategory.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: nec.brand,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: ExpenseCategory.values.map((cat) {
                          final isSel = _selectedCategory == cat;
                          return InkWell(
                            onTap: () =>
                                setState(() => _selectedCategory = cat),
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? nec.brand
                                    : nec.surfaceSecondary
                                        .withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSel
                                      ? nec.brand
                                      : nec.separator.withValues(alpha: 0.15),
                                  width: isSel ? 1.2 : 1,
                                ),
                                boxShadow: isSel
                                    ? [
                                        BoxShadow(
                                          color:
                                              nec.brand.withValues(alpha: 0.22),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    cat.icon,
                                    size: 13,
                                    color: isSel ? Colors.white : cat.color,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    cat.shortLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSel
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSel
                                          ? Colors.white
                                          : nec.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Expense Date',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: nec.textSecondary)),
                                const SizedBox(height: 5),
                                InkWell(
                                  onTap: _pickDate,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    height: 42,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 11),
                                    decoration: BoxDecoration(
                                      color: nec.surfaceSecondary
                                          .withValues(alpha: 0.6),
                                      border: Border.all(
                                          color: nec.separator
                                              .withValues(alpha: 0.2)),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(CupertinoIcons.calendar,
                                            size: 15, color: nec.brand),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: nec.textPrimary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Payment Status',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: nec.textSecondary)),
                                const SizedBox(height: 5),
                                Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: nec.surfaceSecondary
                                        .withValues(alpha: 0.6),
                                    border: Border.all(
                                        color: nec.separator
                                            .withValues(alpha: 0.2)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<ExpenseStatus>(
                                      value: _selectedStatus,
                                      isExpanded: true,
                                      icon: Icon(CupertinoIcons.chevron_down,
                                          size: 13, color: nec.textTertiary),
                                      items: ExpenseStatus.values.map((s) {
                                        return DropdownMenuItem(
                                          value: s,
                                          child: Row(
                                            children: [
                                              Container(
                                                  width: 7,
                                                  height: 7,
                                                  decoration: BoxDecoration(
                                                      color: s.color,
                                                      shape: BoxShape.circle)),
                                              const SizedBox(width: 6),
                                              Text(s.label,
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Payment Method',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: nec.textSecondary)),
                                const SizedBox(height: 5),
                                Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: nec.surfaceSecondary
                                        .withValues(alpha: 0.6),
                                    border: Border.all(
                                        color: nec.separator
                                            .withValues(alpha: 0.2)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedPaymentMethod,
                                      isExpanded: true,
                                      icon: Icon(CupertinoIcons.chevron_down,
                                          size: 13, color: nec.textTertiary),
                                      items: _paymentMethods
                                          .map((m) => DropdownMenuItem(
                                              value: m,
                                              child: Text(m,
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
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
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Vendor / Payee',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: nec.textSecondary)),
                                const SizedBox(height: 5),
                                TextFormField(
                                  controller: _vendorController,
                                  decoration: _inputDec(
                                    nec: nec,
                                    hintText: 'e.g. Star Tech',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Paid By / Account',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: nec.textSecondary),
                      ),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: _paidByController,
                        decoration: _inputDec(
                          nec: nec,
                          hintText: 'e.g. Company Account',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Receipt / Invoice',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: nec.textSecondary),
                      ),
                      const SizedBox(height: 5),
                      InkWell(
                        onTap: _saving ? null : _pickReceipt,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: nec.surfaceSecondary.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: (_receipt != null ||
                                      widget.expense?.receiptName != null)
                                  ? nec.brand.withValues(alpha: 0.5)
                                  : nec.separator.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.paperclip,
                                size: 16,
                                color: (_receipt != null ||
                                        widget.expense?.receiptName != null)
                                    ? nec.brand
                                    : nec.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _receipt?.filename ??
                                      widget.expense?.receiptName ??
                                      'Attach receipt (optional)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: (_receipt != null ||
                                            widget.expense?.receiptName != null)
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: (_receipt != null ||
                                            widget.expense?.receiptName != null)
                                        ? nec.textPrimary
                                        : nec.textTertiary,
                                  ),
                                ),
                              ),
                              if (_receipt != null)
                                GestureDetector(
                                  onTap: () => setState(() => _receipt = null),
                                  child: Icon(
                                      CupertinoIcons.clear_circled_solid,
                                      size: 15,
                                      color: nec.textTertiary),
                                )
                              else
                                Text(
                                  '10 MB max',
                                  style: TextStyle(
                                      fontSize: 11, color: nec.textTertiary),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Notes & Justification',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: nec.textSecondary),
                      ),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: _inputDec(
                          nec: nec,
                          hintText: 'Add optional notes...',
                        ),
                      ),
                      const SizedBox(height: 20),
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
