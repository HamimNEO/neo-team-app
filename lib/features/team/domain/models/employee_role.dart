class EmployeeRole {
  const EmployeeRole(
      {required this.key, required this.name, this.modules = const []});

  final String key, name;
  final List<Map<String, dynamic>> modules;
  static const operations =
      EmployeeRole(key: 'TEAM_OPERATIONS', name: 'Operations');

  factory EmployeeRole.fromJson(Map<String, dynamic> json) {
    final key = json['key'] ?? json['role_key'];
    final name = json['name'];
    if (key is! String || !key.startsWith('TEAM_') || name is! String) {
      throw const FormatException(
          'The server returned an invalid employee role.');
    }
    return EmployeeRole(
        key: key,
        name: name,
        modules: (json['modules'] as List? ?? [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList());
  }
}
