import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/demo_session.dart';
import '../../../core/theme/app_theme.dart';
import '../data/expense_store.dart';
import '../domain/models/expense.dart';
import 'widgets/add_expense_sheet.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final TextEditingController _searchController = TextEditingController();
  ExpenseCategory? _filterCategory;
  ExpenseStatus? _filterStatus;
  String _query = '';

  @override
  void initState() {
    super.initState();
    ExpenseStore.instance.initialize();
    ExpenseStore.instance.addListener(_refresh);
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ExpenseStore.instance.removeListener(_refresh);
    _searchController.dispose();
    super.dispose();
  }

  void _openAddExpense() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddExpenseSheet(),
    );
  }

  List<Expense> _filteredExpenses(List<Expense> list) {
    return list.where((e) {
      if (_filterCategory != null && e.category != _filterCategory) {
        return false;
      }
      if (_filterStatus != null && e.status != _filterStatus) return false;
      if (_query.isNotEmpty) {
        final matchTitle = e.title.toLowerCase().contains(_query);
        final matchVendor = e.vendor.toLowerCase().contains(_query);
        final matchCategory = e.category.label.toLowerCase().contains(_query);
        final matchNotes = e.notes.toLowerCase().contains(_query);
        if (!matchTitle && !matchVendor && !matchCategory && !matchNotes) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  String _formatBdt(double amount) {
    final isInt = amount % 1 == 0;
    final numStr =
        isInt ? amount.toInt().toString() : amount.toStringAsFixed(0);
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return '৳ ${numStr.replaceAllMapped(reg, (Match m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    if (!DemoSession.instance.isAdmin) {
      return Scaffold(
        backgroundColor: nec.bg,
        appBar: AppBar(
          title: const Text('Expense Management'),
          backgroundColor: nec.bg,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.lock_shield, size: 56, color: nec.brand),
                const SizedBox(height: 16),
                Text(
                  'Administrator Access Required',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: nec.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Expense management is restricted exclusively to company owners and administrators.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: nec.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final store = ExpenseStore.instance;
    final allExpenses = store.expenses;
    final filtered = _filteredExpenses(allExpenses);
    final thisMonthTotal = store.totalThisMonth;
    final paidThisMonth = store.totalPaidThisMonth;
    final pendingThisMonth = store.totalPendingThisMonth;

    return Scaffold(
      backgroundColor: nec.bg,
      appBar: AppBar(
        backgroundColor: nec.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: Icon(CupertinoIcons.back, color: nec.brand, size: 22),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expense Management',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: nec.textPrimary),
            ),
            Text(
              'Company financials & expenses',
              style: TextStyle(fontSize: 11, color: nec.textTertiary),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Add Expense',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: nec.brand.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(CupertinoIcons.add, color: nec.brand, size: 18),
            ),
            onPressed: _openAddExpense,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: nec.brand,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(CupertinoIcons.add, size: 18),
        label: const Text('Add Expense',
            style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: _openAddExpense,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      nec.surface,
                      nec.surfaceSecondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: nec.separator),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            const SizedBox(width: 8),
                            Text(
                              'This Month Spend',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: nec.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: nec.brand.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${allExpenses.length} Records',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: nec.brand,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _formatBdt(thisMonthTotal),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: nec.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Divider(height: 1, color: nec.separator),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Paid Amount',
                                style: TextStyle(
                                    fontSize: 11, color: nec.textTertiary),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF34C759),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _formatBdt(paidThisMonth),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: nec.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 26, color: nec.separator),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pending / Due',
                                style: TextStyle(
                                    fontSize: 11, color: nec.textTertiary),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF9500),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _formatBdt(pendingThisMonth),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: nec.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: nec.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: nec.separator),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.search,
                          size: 18,
                          color: nec.textTertiary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(
                              fontSize: 14,
                              color: nec.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search expenses...',
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
                        if (_query.isNotEmpty)
                          GestureDetector(
                            onTap: () => _searchController.clear(),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(
                                CupertinoIcons.clear_circled_solid,
                                size: 18,
                                color: nec.textTertiary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('All Categories'),
                          selected: _filterCategory == null,
                          showCheckmark: false,
                          onSelected: (_) =>
                              setState(() => _filterCategory = null),
                          selectedColor: nec.brand,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: _filterCategory == null
                                  ? nec.brand
                                  : nec.separator,
                            ),
                          ),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: _filterCategory == null
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: _filterCategory == null
                                ? Colors.white
                                : nec.textPrimary,
                          ),
                          backgroundColor: nec.surface,
                        ),
                        const SizedBox(width: 8),
                        ...ExpenseCategory.values.map((cat) {
                          final isSel = _filterCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              avatar: Icon(
                                cat.icon,
                                size: 14,
                                color: isSel ? Colors.white : cat.color,
                              ),
                              label: Text(cat.label),
                              selected: isSel,
                              showCheckmark: false,
                              onSelected: (_) => setState(
                                  () => _filterCategory = isSel ? null : cat),
                              selectedColor: cat.color,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSel ? cat.color : nec.separator,
                                ),
                              ),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    isSel ? FontWeight.w700 : FontWeight.w500,
                                color: isSel ? Colors.white : nec.textPrimary,
                              ),
                              backgroundColor: nec.surface,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.doc_plaintext,
                          size: 48, color: nec.textTertiary),
                      const SizedBox(height: 12),
                      Text(
                        'No expenses found',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: nec.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _query.isNotEmpty
                            ? 'No results matching "$_query"'
                            : 'Log company expenses to track finances in real-time.',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 13, color: nec.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = filtered[index];
                    return _ExpenseCard(
                      expense: item,
                      onTap: () => context.push('/expense-details/${item.id}'),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback onTap;

  const _ExpenseCard({required this.expense, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: nec.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: nec.separator),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: expense.category.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(expense.category.icon,
                      color: expense.category.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: nec.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            expense.category.label,
                            style: TextStyle(
                                fontSize: 11, color: nec.textTertiary),
                          ),
                          if (expense.vendor.isNotEmpty) ...[
                            Text(' · ',
                                style: TextStyle(color: nec.textTertiary)),
                            Flexible(
                              child: Text(
                                expense.vendor,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11, color: nec.textSecondary),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(CupertinoIcons.calendar,
                              size: 11, color: nec.textTertiary),
                          const SizedBox(width: 3),
                          Text(
                            '${expense.date.day}/${expense.date.month}/${expense.date.year}',
                            style: TextStyle(
                                fontSize: 11, color: nec.textTertiary),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: nec.surfaceSecondary,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: nec.separator),
                            ),
                            child: Text(
                              expense.paymentMethod,
                              style: TextStyle(
                                  fontSize: 10, color: nec.textTertiary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      expense.formattedAmount,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: nec.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: expense.status.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        expense.status.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: expense.status.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
