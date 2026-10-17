class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isSuperAdmin,
    required this.modules,
    required this.employee,
    required this.mustChangePassword,
    this.phone,
    this.photo,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final bool isSuperAdmin;
  final List<String> modules;
  final Map<String, dynamic> employee;
  final bool mustChangePassword;
  final String? phone, photo;

  String get employeeId => employee['id']?.toString() ?? id;

  String get accessScope => employee['access_scope'] as String? ?? 'assigned';

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null ||
        json['name'] is! String ||
        json['email'] is! String ||
        json['role'] is! String) {
      throw const FormatException('The server returned an invalid user.');
    }
    return AuthUser(
      id: json['id'].toString(),
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      isSuperAdmin:
          json['is_super_admin'] == true || json['role'] == 'SUPER_ADMIN',
      modules:
          List.unmodifiable((json['modules'] as List? ?? []).cast<String>()),
      employee: Map.unmodifiable(
          Map<String, dynamic>.from(json['employee'] as Map? ?? {})),
      mustChangePassword: json['must_change_password'] == true,
      phone: json['phone'] as String?,
      photo: (json['photo_url'] ?? json['photo']) as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'is_super_admin': isSuperAdmin,
        'modules': modules,
        'employee': employee,
        'must_change_password': mustChangePassword,
        'phone': phone,
        'photo': photo,
      };
}
