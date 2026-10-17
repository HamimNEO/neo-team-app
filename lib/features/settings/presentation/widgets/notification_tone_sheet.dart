import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/app_haptics.dart';
import '../../../../core/services/notification_alert_manager.dart';
import '../../../../core/theme/app_theme.dart';

class NotificationToneSheet extends StatefulWidget {
  const NotificationToneSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationToneSheet(),
    );
  }

  @override
  State<NotificationToneSheet> createState() => _NotificationToneSheetState();
}

class _NotificationToneSheetState extends State<NotificationToneSheet> {
  String? _previewingKey;
  bool _pickingFile = false;

  void _previewTone(NotificationTone tone) {
    setState(() => _previewingKey = tone.key);
    NotificationAlertManager.instance.previewTone(tone);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _previewingKey == tone.key) {
        setState(() => _previewingKey = null);
      }
    });
  }

  Future<void> _pickCustomAudioFile() async {
    if (_pickingFile) return;
    setState(() => _pickingFile = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'mp3',
          'wav',
          'm4a',
          'aac',
          'ogg',
          'opus',
          'flac',
          'wma'
        ],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.single;
      final path = file.path;
      if (path == null && (file.bytes == null || file.bytes!.isEmpty)) {
        throw const FormatException(
            'The selected audio file could not be read.');
      }

      AppHaptics.selectionClick();
      final tone = await NotificationAlertManager.instance.setCustomTone(
        sourcePath: path ?? file.name,
        fileName: file.name,
        bytes: file.bytes,
      );

      _previewTone(tone);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Custom notification tone set to "${file.name}"'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not set audio file: $e'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _pickingFile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final alertMgr = NotificationAlertManager.instance;
    const tones = NotificationAlertManager.availableTones;

    return ListenableBuilder(
      listenable: alertMgr,
      builder: (context, _) {
        final currentKey = alertMgr.selectedToneKey;
        final hasCustom = alertMgr.hasCustomTone;

        return FractionallySizedBox(
          heightFactor: hasCustom ? 0.84 : 0.78,
          child: Material(
            color: nec.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 38,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: nec.textTertiary.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Notification Tone',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: nec.textPrimary,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(28, 28),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Icon(
                            CupertinoIcons.xmark_circle_fill,
                            size: 24,
                            color: nec.textTertiary.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Select the tone played for incoming team notifications and chat messages.',
                        style: TextStyle(
                          fontSize: 13,
                          color: nec.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    color: nec.separator.withValues(alpha: 0.25),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      children: [
                        if (hasCustom) ...[
                          _buildCustomToneTile(
                              context, nec, alertMgr, currentKey),
                          Divider(
                            height: 14,
                            indent: 52,
                            color: nec.separator.withValues(alpha: 0.2),
                          ),
                        ],
                        for (var i = 0; i < tones.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              indent: 52,
                              color: nec.separator.withValues(alpha: 0.2),
                            ),
                          _buildToneTile(
                              context, nec, alertMgr, tones[i], currentKey),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _pickingFile ? null : _pickCustomAudioFile,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: nec.bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: nec.separator.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: nec.brand.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                CupertinoIcons.folder_badge_plus,
                                size: 20,
                                color: nec.brand,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Choose Audio File from Device',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: nec.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    'Select any MP3, WAV, or audio file from files',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: nec.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_pickingFile)
                              const CupertinoActivityIndicator()
                            else
                              Icon(
                                CupertinoIcons.chevron_right,
                                size: 14,
                                color: nec.textTertiary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomToneTile(
    BuildContext context,
    NecColors nec,
    NotificationAlertManager alertMgr,
    String currentKey,
  ) {
    final tone = alertMgr.selectedTone;
    final isSelected = currentKey == 'custom';
    final isPreviewing = _previewingKey == 'custom';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        AppHaptics.selectionClick();
        alertMgr.setSelectedToneKey('custom');
        _previewTone(tone);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification tone set to "${tone.title}"'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? nec.brand.withValues(alpha: 0.15) : nec.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                CupertinoIcons.music_note_2,
                size: 20,
                color: isSelected ? nec.brand : nec.textSecondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          tone.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: nec.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: nec.brand.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'CUSTOM',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: nec.brand,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Custom audio file from device files',
                    style: TextStyle(
                      fontSize: 12,
                      color: nec.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
              onPressed: () {
                AppHaptics.lightImpact();
                _previewTone(tone);
              },
              child: Icon(
                isPreviewing
                    ? CupertinoIcons.waveform
                    : CupertinoIcons.play_circle_fill,
                size: 22,
                color: isPreviewing ? nec.brand : nec.textTertiary,
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
              onPressed: () async {
                AppHaptics.heavyImpact();
                await alertMgr.clearCustomTone();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Custom tone removed. Reverted to default tone.'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Icon(
                CupertinoIcons.trash,
                size: 18,
                color: Colors.red.shade400,
              ),
            ),
            if (isSelected)
              Icon(
                CupertinoIcons.checkmark_alt_circle_fill,
                size: 22,
                color: nec.brand,
              )
            else
              const SizedBox(width: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildToneTile(
    BuildContext context,
    NecColors nec,
    NotificationAlertManager alertMgr,
    NotificationTone tone,
    String currentKey,
  ) {
    final isSelected = tone.key == currentKey;
    final isPreviewing = _previewingKey == tone.key;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        AppHaptics.selectionClick();
        alertMgr.setSelectedToneKey(tone.key);
        _previewTone(tone);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification tone set to ${tone.title}'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? nec.brand.withValues(alpha: 0.15) : nec.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isSelected
                    ? CupertinoIcons.speaker_3_fill
                    : CupertinoIcons.speaker_2,
                size: 19,
                color: isSelected ? nec.brand : nec.textSecondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tone.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: nec.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tone.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: nec.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
              onPressed: () {
                AppHaptics.lightImpact();
                _previewTone(tone);
              },
              child: Icon(
                isPreviewing
                    ? CupertinoIcons.waveform
                    : CupertinoIcons.play_circle_fill,
                size: 22,
                color: isPreviewing ? nec.brand : nec.textTertiary,
              ),
            ),
            const SizedBox(width: 4),
            if (isSelected)
              Icon(
                CupertinoIcons.checkmark_alt_circle_fill,
                size: 22,
                color: nec.brand,
              )
            else
              const SizedBox(width: 22),
          ],
        ),
      ),
    );
  }
}
