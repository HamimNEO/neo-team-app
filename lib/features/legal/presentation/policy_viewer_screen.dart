import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../data/policy_repository.dart';
import '../domain/models/policy_model.dart';
import 'widgets/contact_modal_sheet.dart';

class PolicyViewerScreen extends StatefulWidget {
  final String slug;

  const PolicyViewerScreen({
    super.key,
    required this.slug,
  });

  @override
  State<PolicyViewerScreen> createState() => _PolicyViewerScreenState();
}

class _PolicyViewerScreenState extends State<PolicyViewerScreen> {
  late PolicyModel _policy;
  bool _isLoading = false;
  bool _isLiveFetched = false;

  @override
  void initState() {
    super.initState();
    _policy = PolicyRepository.instance.getBundledPolicy(widget.slug);
    _loadPolicy(forceRefresh: false);
  }

  @override
  void didUpdateWidget(covariant PolicyViewerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slug != widget.slug) {
      _policy = PolicyRepository.instance.getBundledPolicy(widget.slug);
      _loadPolicy(forceRefresh: false);
    }
  }

  Future<void> _loadPolicy({required bool forceRefresh}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final updated = await PolicyRepository.instance.getPolicy(
        widget.slug,
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          _policy = updated;
          _isLiveFetched = true;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch $url: $e');
    }
  }

  Future<void> _sendEmail(
      {required String subject, required String body}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'bingi.startup@gmail.com',
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Could not launch mailto: $e');
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'shield':
        return CupertinoIcons.shield_fill;
      case 'document':
        return CupertinoIcons.doc_text_fill;
      case 'trash':
        return CupertinoIcons.trash_fill;
      case 'database':
        return CupertinoIcons.chart_pie_fill;
      case 'message':
        return CupertinoIcons.chat_bubble_2_fill;
      default:
        return CupertinoIcons.info_circle_fill;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;

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
                  _policy.title,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: nec.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  CupertinoIcons.compass,
                  size: 22,
                  color: nec.brand,
                ),
                tooltip: 'Open in browser',
                onPressed: () => _openUrl(_policy.webUrl),
              ),
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
        child: RefreshIndicator.adaptive(
          onRefresh: () => _loadPolicy(forceRefresh: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: nec.brand.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getIconData(_policy.icon),
                            size: 14,
                            color: nec.brand,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _policy.label.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: nec.brand,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (_isLoading)
                      const CupertinoActivityIndicator(radius: 8)
                    else if (_isLiveFetched)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x1A34C759),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.checkmark_alt,
                              size: 12,
                              color: Color(0xFF34C759),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Live Synced',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF34C759),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _policy.title,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: nec.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                if (_policy.description.isNotEmpty) ...[
                  Text(
                    _policy.description,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.4,
                      color: nec.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: nec.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: nec.separator.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Updated October 8, 2026 · NEC TEAM by NEONECY',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: nec.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_policy.intro.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: nec.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: nec.brand.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Text(
                      _policy.intro,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: nec.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                ..._policy.sections
                    .map((section) => _buildSectionCard(nec, section)),
                if (_policy.requestForm || widget.slug == 'data-deletion')
                  _buildDataDeletionActionCard(nec),
                if (widget.slug == 'support') _buildSupportActionCard(nec),
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _openUrl('https://neonecy.com/'),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Visit neonecy.com',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: nec.brand,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              CupertinoIcons.arrow_up_right,
                              size: 12,
                              color: nec.brand,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '© 2026 NEONECY. All rights reserved.\nNEC TEAM official policies.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          color: nec.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(NecColors nec, PolicySection section) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: nec.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: nec.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...section.paragraphs.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                p,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: nec.textSecondary,
                ),
              ),
            ),
          ),
          if (section.items.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...section.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, right: 8.0),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: nec.brand,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: nec.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (section.links.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...section.links.map(
              (link) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: InkWell(
                  onTap: () => _openUrl(link.href),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.link,
                        size: 14,
                        color: nec.brand,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          link.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: nec.brand,
                            decoration: TextDecoration.underline,
                            decorationColor: nec.brand,
                          ),
                        ),
                      ),
                      Icon(
                        CupertinoIcons.arrow_up_right,
                        size: 12,
                        color: nec.brand,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataDeletionActionCard(NecColors nec) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0x14FF3B30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0x33FF3B30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.trash_circle_fill,
                color: Color(0xFFFF3B30),
                size: 24,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Send Deletion Request',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF3B30),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Need records removed from NEONECY systems? Submit an official deletion request directly inside the app to notify the operations team.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: nec.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: const Color(0xFFFF3B30),
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(vertical: 12),
              onPressed: () => ContactModalSheet.show(
                context,
                initialType: 'Account & Data Deletion',
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.paperplane_fill,
                      size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Submit Request in App',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _sendEmail(
                subject: 'NEC TEAM Data Deletion Request',
                body: 'Hello NEONECY Team,\n\n'
                    'I am submitting an official request to delete my records from NEC TEAM.\n\n'
                    'Work Email: \n'
                    'Full Name: \n'
                    'Request Scope: Account and associated data\n\n'
                    'Thank you.',
              ),
              child: Text(
                'Or email directly: bingi.startup@gmail.com',
                style: TextStyle(
                  fontSize: 11.5,
                  color: nec.textTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportActionCard(NecColors nec) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: nec.brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: nec.brand.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.chat_bubble_2_fill,
                color: nec.brand,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Contact NEONECY Operations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: nec.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Have feedback, discovered a bug, or need help with NEC TEAM? Send a message directly inside the app to receive prompt support.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: nec.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: nec.brand,
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(vertical: 12),
              onPressed: () => ContactModalSheet.show(
                context,
                initialType: 'Support & Assistance',
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.paperplane_fill,
                      size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Send Message in App',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _sendEmail(
                subject: 'NEC TEAM Support & Inquiry',
                body: 'Hello NEONECY Team,\n\n'
                    'I need help regarding NEC TEAM.\n\n'
                    'Details: \n\n'
                    'Device Model & OS: \n\n'
                    'Thank you.',
              ),
              child: Text(
                'Or email directly: bingi.startup@gmail.com',
                style: TextStyle(
                  fontSize: 11.5,
                  color: nec.textTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
