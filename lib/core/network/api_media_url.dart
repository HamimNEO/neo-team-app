/// Public uploaded photos never receive the API bearer token.
String? apiMediaUrl(String? path, String baseUrl) {
  if (path == null || path.trim().isEmpty) return null;
  final trimmed = path.trim();
  final base = Uri.tryParse(baseUrl);
  final media = Uri.tryParse(trimmed);
  if (base == null || media == null) return null;

  if (media.hasScheme) {
    if (media.scheme == 'https' || media.scheme == 'http') {
      if (media.host == 'api.bingi.com.bd' &&
          (media.path.contains('team-operations') ||
              media.path.contains('profiles'))) {
        final cleanPath = media.path
            .replaceFirst(RegExp(r'^/+storage/+'), '/')
            .replaceFirst(RegExp(r'^/+'), '');
        return 'https://media.bingi.com.bd/$cleanPath';
      }
      if (media.scheme == 'http' && media.host == base.host) {
        return media.replace(scheme: 'https').toString();
      }
      return media.toString();
    }
    return null;
  }
  if (media.hasAuthority) return null;

  final relative = trimmed.replaceFirst(RegExp(r'^/+'), '');
  final withoutStorage = relative.replaceFirst(RegExp(r'^storage/+'), '');

  if (base.host == 'api.bingi.com.bd' ||
      withoutStorage.startsWith('team-operations/')) {
    return 'https://media.bingi.com.bd/$withoutStorage';
  }

  return base
      .replace(
          path: relative.startsWith('storage/')
              ? '/$relative'
              : '/storage/$relative',
          query: null,
          fragment: null)
      .toString();
}
