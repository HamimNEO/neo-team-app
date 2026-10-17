import 'package:shared_preferences/shared_preferences.dart';

/// A small storage boundary shared by feature caches.
class PreferencesStore {
  const PreferencesStore();

  static Future<void> _mutations = Future.value();

  static Future<void> _mutate(Future<void> Function() action) {
    final pending = _mutations.then((_) => action());
    _mutations =
        pending.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return pending;
  }

  Future<String?> read(String key) async =>
      (await SharedPreferences.getInstance()).getString(key);

  Future<void> write(String key, String value) => _mutate(() async {
        if (!await (await SharedPreferences.getInstance())
            .setString(key, value)) {
          throw const FormatException(
              'Unable to save your session. Please try again.');
        }
      });

  Future<void> remove(String key) => _mutate(() async {
        final preferences = await SharedPreferences.getInstance();
        if (preferences.containsKey(key) && !await preferences.remove(key)) {
          throw const FormatException(
              'Unable to clear your session. Please try again.');
        }
      });

  Future<void> removeByPrefixes(List<String> prefixes) => _mutate(() async {
        final preferences = await SharedPreferences.getInstance();
        for (final key in preferences.getKeys()) {
          if (prefixes.any(key.startsWith) && !await preferences.remove(key)) {
            throw const FormatException('Unable to clear cached account data.');
          }
        }
      });
}
