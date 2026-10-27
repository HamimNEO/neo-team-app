import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../data/certificate_store.dart';
import 'widgets/certificate_request_card.dart';

class AdminCertificatesScreen extends StatefulWidget {
  const AdminCertificatesScreen({super.key});

  @override
  State<AdminCertificatesScreen> createState() =>
      _AdminCertificatesScreenState();
}

class _AdminCertificatesScreenState extends State<AdminCertificatesScreen> {
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    CertificateStore.instance.load(force: true);
  }

  final List<String> _filters = [
    'All',
    'Pending',
    'In Preparation',
    'Delivered',
    'Rejected',
  ];

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    return Scaffold(
      backgroundColor: nec.bg,
      appBar: AppBar(
        backgroundColor: nec.surface,
        elevation: 0,
        centerTitle: true,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.back, size: 18, color: nec.brand),
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
        leadingWidth: 72,
        title: Text(
          'Certificate Requests',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: nec.textPrimary,
          ),
        ),
        actions: [
          IconButton(
              onPressed: () => CertificateStore.instance.load(force: true),
              icon: const Icon(CupertinoIcons.refresh),
              tooltip: 'Refresh certificates')
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: nec.separator.withValues(alpha: 0.3)),
        ),
      ),
      body: AnimatedBuilder(
        animation: CertificateStore.instance,
        builder: (context, _) {
          final all = CertificateStore.instance.allRequests;
          final pending = all.where((r) => r.isPending).length;
          final inPrep = all.where((r) => r.isInPreparation).length;

          final filtered = all.where((r) {
            if (_selectedFilter == 'Pending') return r.isPending;
            if (_selectedFilter == 'In Preparation') return r.isInPreparation;
            if (_selectedFilter == 'Delivered') return r.isDelivered;
            if (_selectedFilter == 'Rejected') return r.isRejected;
            return true;
          }).toList();

          return Column(
            children: [
              if (CertificateStore.instance.loading)
                const LinearProgressIndicator(),
              if (CertificateStore.instance.error != null)
                ListTile(
                    title: Text(CertificateStore.instance.error!),
                    trailing: TextButton(
                        onPressed: () =>
                            CertificateStore.instance.load(force: true),
                        child: const Text('Retry'))),
              Container(
                color: nec.surface,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      int? count;
                      if (filter == 'All') count = all.length;
                      if (filter == 'Pending') count = pending;
                      if (filter == 'In Preparation') count = inPrep;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(filter),
                              if (count != null && count > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.25)
                                        : (filter == 'Pending'
                                            ? AppColors.warning
                                                .withValues(alpha: 0.2)
                                            : nec.textTertiary
                                                .withValues(alpha: 0.15)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : (filter == 'Pending'
                                              ? AppColors.warning
                                              : nec.textSecondary),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          showCheckmark: false,
                          selected: isSelected,
                          onSelected: (_) =>
                              setState(() => _selectedFilter = filter),
                          selectedColor: nec.brand,
                          backgroundColor: nec.bg,
                          labelStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color:
                                isSelected ? Colors.white : nec.textSecondary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? nec.brand : nec.separator,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Divider(height: 1, color: nec.separator.withValues(alpha: 0.4)),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.doc_checkmark,
                                size: 48, color: nec.textTertiary),
                            const SizedBox(height: 12),
                            Text(
                              'No $_selectedFilter Certificate Requests',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: nec.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final req = filtered[index];
                          return CertificateRequestCard(
                            request: req,
                            isAdmin: true,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
