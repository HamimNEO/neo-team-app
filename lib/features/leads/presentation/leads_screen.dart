import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/lead_card_item.dart';
import 'widgets/lead_filter_sort_sheet.dart';
import 'widgets/lead_metric_summary_row.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  String _selectedChip = 'All';
  String _selectedSort = 'Recently Updated';
  bool _isSearching = false;
  final _searchController = TextEditingController();

  final filterChips = ['All', 'Mine', 'New', 'Follow-up', 'More >'];

  void _openFilterSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => LeadFilterSortSheet(
        selectedSort: _selectedSort,
        onSortChanged: (sort) {
          setState(() {
            _selectedSort = sort;
          });
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Follow-up':
        return AppColors.warning;
      case 'Interested':
        return AppColors.leadInterested;
      case 'New':
        return AppColors.brandLight;
      case 'Visit Scheduled':
        return AppColors.leadVisit;
      case 'Negotiation':
        return AppColors.leadNegotiation;
      case 'Lost':
        return AppColors.error;
      case 'Won':
        return AppColors.success;
      default:
        return AppColors.neutral;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

    final allLeads = [
      {
        'id': 'lead_1',
        'company': 'Sea Pearl Resort',
        'subtitle': "Cox's Bazar · Resort",
        'status': 'Follow-up',
        'scheduleNote': 'Follow-up call · Tomorrow, 11:30 AM',
        'isOverdue': false,
        'assigneeInitials': 'SA',
        'assigneeName': 'Shahina',
        'isMine': true,
        'isNew': false,
        'isFollowUp': true,
        'group': 'TOMORROW',
      },
      {
        'id': 'lead_2',
        'company': 'Blue Wave Resort',
        'subtitle': "Cox's Bazar · Resort",
        'status': 'Interested',
        'scheduleNote': 'Follow-up · Today, 4:00 PM',
        'isOverdue': false,
        'assigneeInitials': 'SA',
        'assigneeName': 'Shahina',
        'isMine': true,
        'isNew': false,
        'isFollowUp': true,
        'group': 'TODAY',
      },
      {
        'id': 'lead_3',
        'company': 'Ocean Paradise Hotel',
        'subtitle': "Cox's Bazar · Hotel",
        'status': 'New',
        'scheduleNote': 'Just now',
        'isOverdue': false,
        'assigneeInitials': '??',
        'assigneeName': 'Unassigned',
        'isMine': false,
        'isNew': true,
        'isFollowUp': false,
        'group': 'TODAY',
      },
      {
        'id': 'lead_4',
        'company': 'Hotel Sea Crown',
        'subtitle': "Cox's Bazar · Hotel",
        'status': 'Visit Scheduled',
        'scheduleNote': 'Site visit · Today, 2:00 PM',
        'isOverdue': false,
        'assigneeInitials': 'RM',
        'assigneeName': 'Rahul',
        'isMine': false,
        'isNew': false,
        'isFollowUp': false,
        'group': 'TODAY',
      },
      {
        'id': 'lead_5',
        'company': 'Royal Tulip Sea Pearl',
        'subtitle': "Cox's Bazar · Hotel",
        'status': 'Negotiation',
        'scheduleNote': 'Contract review · Yesterday',
        'isOverdue': false,
        'assigneeInitials': 'SA',
        'assigneeName': 'Shahina',
        'isMine': true,
        'isNew': false,
        'isFollowUp': false,
        'group': 'TODAY',
      },
      {
        'id': 'lead_6',
        'company': 'Long Beach Hotel',
        'subtitle': "Cox's Bazar · Hotel",
        'status': 'Follow-up',
        'scheduleNote': 'Follow-up · 2h overdue',
        'isOverdue': true,
        'assigneeInitials': 'PD',
        'assigneeName': 'Priya',
        'isMine': false,
        'isNew': false,
        'isFollowUp': true,
        'group': 'OVERDUE',
      },
      {
        'id': 'lead_7',
        'company': 'Seagull Hotel',
        'subtitle': "Cox's Bazar · Hotel",
        'status': 'Follow-up',
        'scheduleNote': 'Callback · 4h overdue',
        'isOverdue': true,
        'assigneeInitials': 'PD',
        'assigneeName': 'Priya',
        'isMine': false,
        'isNew': false,
        'isFollowUp': true,
        'group': 'OVERDUE',
      },
      {
        'id': 'lead_8',
        'company': 'Aqua Dream Resort',
        'subtitle': "Cox's Bazar · Resort",
        'status': 'Visit Scheduled',
        'scheduleNote': 'Site visit · Tomorrow, 10:00 AM',
        'isOverdue': false,
        'assigneeInitials': 'SA',
        'assigneeName': 'Shahina',
        'isMine': true,
        'isNew': false,
        'isFollowUp': false,
        'group': 'TOMORROW',
      },
    ];

    final query = _searchController.text.trim().toLowerCase();

    List<Map<String, dynamic>> filteredLeads = allLeads.where((item) {
      if (query.isNotEmpty) {
        final companyMatch =
            item['company'].toString().toLowerCase().contains(query);
        final subtitleMatch =
            item['subtitle'].toString().toLowerCase().contains(query);
        final assigneeMatch =
            item['assigneeName'].toString().toLowerCase().contains(query);
        if (!companyMatch && !subtitleMatch && !assigneeMatch) {
          return false;
        }
      }
      if (!_isSearching) {
        if (_selectedChip == 'Mine') return item['isMine'] == true;
        if (_selectedChip == 'New') return item['isNew'] == true;
        if (_selectedChip == 'Follow-up') return item['isFollowUp'] == true;
      }
      return true;
    }).toList();

    final isFollowUpTab = !_isSearching && _selectedChip == 'Follow-up';

    return Scaffold(
      backgroundColor: nec.bg,
      appBar: AppBar(
        backgroundColor: nec.bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _isSearching
              ? Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: nec.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.search,
                              size: 16,
                              color: nec.textTertiary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                onChanged: (v) => setState(() {}),
                                style: TextStyle(
                                  color: nec.textPrimary,
                                  fontSize: 15,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Business, contact, phone...',
                                  hintStyle: TextStyle(
                                    color: nec.textTertiary,
                                    fontSize: 15,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                child: Icon(
                                  CupertinoIcons.xmark_circle_fill,
                                  size: 16,
                                  color: nec.textTertiary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          _isSearching = false;
                          _searchController.clear();
                        });
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: nec.brand,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Leads',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: nec.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _isSearching = true;
                            });
                          },
                          icon: Icon(
                            CupertinoIcons.search,
                            color: nec.textPrimary,
                            size: 20,
                          ),
                        ),
                        IconButton(
                          onPressed: _openFilterSortSheet,
                          icon: Icon(
                            CupertinoIcons.slider_horizontal_3,
                            color: nec.textPrimary,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isSearching) ...[
                const SizedBox(height: 12),
                const LeadMetricSummaryRow(),
                const SizedBox(height: 16),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: filterChips.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final chip = filterChips[index];
                      final isSelected = _selectedChip == chip;

                      return GestureDetector(
                        onTap: () {
                          if (chip == 'More >') {
                            _openFilterSortSheet();
                          } else {
                            setState(() {
                              _selectedChip = chip;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? nec.brand : nec.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? nec.brand
                                  : nec.separator.withValues(alpha: 0.3),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            chip,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color:
                                  isSelected ? Colors.white : nec.textSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ] else
                const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _isSearching && _searchController.text.trim().isNotEmpty
                      ? '${filteredLeads.length} leads for "${_searchController.text.trim()}"'
                      : '${filteredLeads.length} leads',
                  style: TextStyle(
                    fontSize: 13,
                    color: nec.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_isSearching && filteredLeads.isEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.search,
                          size: 56,
                          color: nec.textTertiary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No leads found',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: nec.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No leads match your search. Try different terms.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: nec.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (isFollowUpTab) ...[
                _buildLeadGroup(
                  context: context,
                  title: 'OVERDUE',
                  titleColor: AppColors.error,
                  showWarningIcon: true,
                  leads: filteredLeads
                      .where((x) => x['group'] == 'OVERDUE')
                      .toList(),
                ),
                _buildLeadGroup(
                  context: context,
                  title: 'TOMORROW',
                  leads: filteredLeads
                      .where((x) => x['group'] == 'TOMORROW')
                      .toList(),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Material(
                    color: nec.surface,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: List.generate(filteredLeads.length, (index) {
                        final item = filteredLeads[index];
                        final isLast = index == filteredLeads.length - 1;

                        return Column(
                          children: [
                            LeadCardItem(
                              company: item['company'] as String,
                              subtitle: item['subtitle'] as String,
                              status: item['status'] as String,
                              statusColor:
                                  _getStatusColor(item['status'] as String),
                              scheduleNote: item['scheduleNote'] as String?,
                              isOverdue: item['isOverdue'] as bool,
                              assigneeInitials:
                                  item['assigneeInitials'] as String,
                              assigneeName: item['assigneeName'] as String,
                              onTap: () => context.push('/leads/${item['id']}'),
                            ),
                            if (!isLast)
                              Divider(
                                height: 1,
                                color: nec.separator.withValues(alpha: 0.3),
                                indent: 16,
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              const SizedBox(height: 28),
              Center(
                child: Text(
                  'SYNCED · JUST NOW',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: nec.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadGroup({
    required BuildContext context,
    required String title,
    Color? titleColor,
    bool showWarningIcon = false,
    required List<Map<String, dynamic>> leads,
  }) {
    final nec = Theme.of(context).extension<NecColors>()!;
    if (leads.isEmpty) return const SizedBox.shrink();

    final headerColor = titleColor ?? nec.textSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showWarningIcon) ...[
                const Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  size: 14,
                  color: AppColors.error,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: headerColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Material(
            color: nec.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: List.generate(leads.length, (index) {
                final item = leads[index];
                final isLast = index == leads.length - 1;

                return Column(
                  children: [
                    LeadCardItem(
                      company: item['company'] as String,
                      subtitle: item['subtitle'] as String,
                      status: item['status'] as String,
                      statusColor: _getStatusColor(item['status'] as String),
                      scheduleNote: item['scheduleNote'] as String?,
                      isOverdue: item['isOverdue'] as bool,
                      assigneeInitials: item['assigneeInitials'] as String,
                      assigneeName: item['assigneeName'] as String,
                      onTap: () => context.push('/leads/${item['id']}'),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: nec.separator.withValues(alpha: 0.3),
                        indent: 16,
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
