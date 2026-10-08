import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/demo_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_toast.dart';
import '../../../team/data/employee_store.dart';
import '../../data/email_service.dart';

class ContactModalSheet extends StatefulWidget {
  final String initialType;

  const ContactModalSheet({
    super.key,
    this.initialType = 'Support & Assistance',
  });

  static Future<void> show(
    BuildContext context, {
    String initialType = 'Support & Assistance',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContactModalSheet(initialType: initialType),
    );
  }

  @override
  State<ContactModalSheet> createState() => _ContactModalSheetState();
}

class _ContactModalSheetState extends State<ContactModalSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _messageController;
  late String _selectedType;

  bool _isSending = false;
  bool _isSuccess = false;
  String? _errorMessage;

  final List<String> _requestTypes = [
    'Support & Assistance',
    'Report a Bug',
    'Account & Data Deletion',
    'General Inquiry',
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    if (!_requestTypes.contains(_selectedType)) {
      _selectedType = _requestTypes.first;
    }

    final sessionEmail = DemoSession.instance.email;
    final currentEmp =
        EmployeeStore.instance.byId(DemoSession.instance.employeeId);
    final sessionName = currentEmp?.name ??
        (sessionEmail.isNotEmpty ? sessionEmail.split('@').first : '');

    _nameController = TextEditingController(text: sessionName);
    _emailController = TextEditingController(text: sessionEmail);
    _messageController = TextEditingController(
      text: widget.initialType == 'Account & Data Deletion'
          ? 'I would like to request the deletion of my stored demo/workplace records from NEC TEAM systems.'
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final message = _messageController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'Please enter a valid email address.';
      });
      return;
    }

    if (message.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter details for your request.';
      });
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final success = await EmailService.instance.sendEmail(
        name: name.isNotEmpty ? name : 'NEC TEAM User',
        email: email,
        requestType: _selectedType,
        message: message,
      );

      if (success && mounted) {
        setState(() {
          _isSending = false;
          _isSuccess = true;
        });
        NecToast.show(
          context,
          message: 'Request sent successfully to NEONECY!',
          type: NecToastType.success,
        );
      } else if (mounted) {
        setState(() {
          _isSending = false;
          _errorMessage = 'Failed to deliver message. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _errorMessage =
              'Connection error: ${e.toString().replaceAll('HttpException:', '').trim()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final mediaQuery = MediaQuery.of(context);

    return Container(
      padding: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: nec.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: _isSuccess ? _buildSuccessView(nec) : _buildFormView(nec),
        ),
      ),
    );
  }

  Widget _buildFormView(NecColors nec) {
    final isDeletion = _selectedType == 'Account & Data Deletion';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Handle bar
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: nec.separator.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isDeletion ? const Color(0xFFFF3B30) : nec.brand)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isDeletion
                    ? CupertinoIcons.trash_fill
                    : CupertinoIcons.paperplane_fill,
                color: isDeletion ? const Color(0xFFFF3B30) : nec.brand,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDeletion
                        ? 'Request Data Deletion'
                        : 'Contact NEONECY Support',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: nec.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Delivered directly to bingi.startup@gmail.com',
                    style: TextStyle(
                      fontSize: 12,
                      color: nec.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(CupertinoIcons.xmark_circle_fill,
                  color: nec.textTertiary, size: 22),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 18),

        Text(
          'REQUEST TYPE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: nec.textTertiary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _requestTypes.map((type) {
            final isSelected = _selectedType == type;
            final isDelType = type == 'Account & Data Deletion';
            final activeColor = isDelType ? const Color(0xFFFF3B30) : nec.brand;

            return ChoiceChip(
              label: Text(
                type,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : nec.textPrimary,
                ),
              ),
              selected: isSelected,
              selectedColor: activeColor,
              backgroundColor: nec.bg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected
                      ? activeColor
                      : nec.separator.withValues(alpha: 0.3),
                ),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedType = type;
                    if (type == 'Account & Data Deletion' &&
                        _messageController.text.isEmpty) {
                      _messageController.text =
                          'I would like to request the deletion of my stored demo/workplace records from NEC TEAM systems.';
                    }
                  });
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        Text(
          'YOUR NAME',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: nec.textTertiary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _nameController,
          style: TextStyle(fontSize: 14.5, color: nec.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. Mahmudul Hasan',
            hintStyle: TextStyle(color: nec.textTertiary, fontSize: 14),
            filled: true,
            fillColor: nec.bg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 14),

        Text(
          'WORK EMAIL',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: nec.textTertiary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(fontSize: 14.5, color: nec.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. employee@neonecy.com',
            hintStyle: TextStyle(color: nec.textTertiary, fontSize: 14),
            filled: true,
            fillColor: nec.bg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 14),

        Text(
          'DETAILS / MESSAGE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: nec.textTertiary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _messageController,
          maxLines: 4,
          style: TextStyle(fontSize: 14, color: nec.textPrimary),
          decoration: InputDecoration(
            hintText: 'Describe your request, question or feedback...',
            hintStyle: TextStyle(color: nec.textTertiary, fontSize: 13.5),
            filled: true,
            fillColor: nec.bg,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.exclamationmark_triangle_fill,
                    size: 16, color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style:
                        const TextStyle(fontSize: 12.5, color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: CupertinoButton(
            color: isDeletion ? const Color(0xFFFF3B30) : nec.brand,
            borderRadius: BorderRadius.circular(14),
            padding: EdgeInsets.zero,
            onPressed: _isSending ? null : _submit,
            child: _isSending
                ? const CupertinoActivityIndicator(color: Colors.white)
                : Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDeletion
                              ? CupertinoIcons.trash_fill
                              : CupertinoIcons.paperplane_fill,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isDeletion
                              ? 'Submit Deletion Request'
                              : 'Send Message Now',
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView(NecColors nec) {
    final isDeletion = _selectedType == 'Account & Data Deletion';

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: Color(0x2634C759),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.checkmark_alt,
              color: Color(0xFF34C759),
              size: 38,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isDeletion ? 'Deletion Request Sent' : 'Message Sent Successfully',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: nec.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Text(
              'Thank you! Your request has been securely delivered to NEONECY operations at bingi.startup@gmail.com. We will process it promptly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: nec.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: CupertinoButton(
              color: nec.brand,
              borderRadius: BorderRadius.circular(14),
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).pop(),
              child: const Center(
                child: Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
