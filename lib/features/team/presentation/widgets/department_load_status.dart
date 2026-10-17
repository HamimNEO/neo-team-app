import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class DepartmentLoadStatus extends StatelessWidget {
  const DepartmentLoadStatus(
      {super.key,
      required this.loading,
      this.error,
      this.empty = false,
      required this.onRetry});

  final bool loading, empty;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    if (!loading && error == null && !empty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(children: [
        if (loading) const LinearProgressIndicator(minHeight: 2),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: nec.textSecondary)),
          TextButton(
              onPressed: loading ? null : onRetry, child: const Text('Retry')),
        ] else if (empty && !loading)
          Text('No departments yet.',
              style: TextStyle(color: nec.textSecondary)),
      ]),
    );
  }
}
