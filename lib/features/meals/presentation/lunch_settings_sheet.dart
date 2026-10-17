import 'package:flutter/material.dart';
import '../../../core/widgets/nec_toast.dart';
import '../data/meal_store.dart';

class LunchSettingsSheet extends StatefulWidget {
  const LunchSettingsSheet({super.key});

  @override
  State<LunchSettingsSheet> createState() => _LunchSettingsSheetState();
}

class _LunchSettingsSheetState extends State<LunchSettingsSheet> {
  final _store = MealStore.instance;
  late final _cutoff = TextEditingController(
      text: (_store.policy['cutoff_time']?.toString() ?? '')
          .split(':')
          .take(2)
          .join(':'));
  late final _price = TextEditingController(
      text: _store.policy['price_per_meal']?.toString() ?? '');
  late final _subsidy = TextEditingController(
      text: _store.policy['subsidy_per_meal']?.toString() ?? '');
  late bool _enabled = _store.policy['is_enabled'] == true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _cutoff.dispose();
    _price.dispose();
    _subsidy.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final price = num.tryParse(_price.text),
        subsidy = num.tryParse(_subsidy.text);
    if (!RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(_cutoff.text) ||
        price == null ||
        subsidy == null ||
        price < 0 ||
        subsidy < 0 ||
        subsidy > price) {
      setState(() => _error =
          'Enter a valid cutoff (HH:mm), price and subsidy. Subsidy cannot exceed price.');
      return;
    }
    setState(() => _saving = true);
    try {
      await _store.updateSettings({
        'cutoff_time': _cutoff.text,
        'price_per_meal': price,
        'subsidy_per_meal': subsidy,
        'is_enabled': _enabled
      });
      if (!mounted) return;
      NecToast.show(context, message: 'Lunch settings saved');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            e is FormatException ? e.message : 'Unable to save settings.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Lunch Settings', style: Theme.of(context).textTheme.titleLarge),
        SwitchListTile(
            value: _enabled,
            onChanged: _saving ? null : (v) => setState(() => _enabled = v),
            title: const Text('Office lunch enabled')),
        TextField(
            controller: _cutoff,
            enabled: !_saving,
            decoration: const InputDecoration(
                labelText: 'Same-day cutoff (HH:mm, Asia/Dhaka)')),
        TextField(
            controller: _price,
            enabled: !_saving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Price per meal')),
        TextField(
            controller: _subsidy,
            enabled: !_saving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration:
                const InputDecoration(labelText: 'Company subsidy per meal')),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 16),
        FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save settings')),
      ])));
}
