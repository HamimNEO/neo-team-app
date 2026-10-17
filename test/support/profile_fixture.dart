Map<String, dynamic> profileJson(
        {String id = 'usr_test', String name = 'Test Admin'}) =>
    {
      'profile': {
        'id': id,
        'name': name,
        'email': 'admin@example.test',
        'phone': null,
        'photo': null,
        'role': 'Super Admin',
        'organization': 'Backend Organization',
        'status': 'active',
        'access_scope': 'all',
        'address': null,
        'employee': {
          'id': 0,
          'code': 'SUPER-ADMIN',
          'designation': 'Super Admin',
          'department': null,
          'team': 'Platform',
        },
      },
      'tabs': ['overview', 'manage', 'activity', 'more'],
      'employment': null,
      'salary': null,
      'benefits': [],
      'work': null,
      'activity': [],
    };
