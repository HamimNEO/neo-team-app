import 'package:flutter_test/flutter_test.dart';
import 'package:neonecy_team_app/features/meals/domain/models/lunch_preference.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('LunchStatus recognizes not_taking_lunch as skipped', () {
    final pref = LunchPreference(
      employeeId: 'api_emp_2',
      day: '2026-10-17',
      takeLunch: false,
      actorId: 'admin',
      updatedAt: DateTime.now(),
      serverStatus: 'not_taking_lunch',
    );

    // Using serverStatus switch logic
    final status = switch (pref.serverStatus) {
      'day_off' => LunchStatus.offDay,
      'on_leave' => LunchStatus.leave,
      'inactive' => LunchStatus.inactive,
      'not_scheduled' => LunchStatus.notIncluded,
      'skipping_lunch' || 'not_taking_lunch' => LunchStatus.skipped,
      'taking_lunch' => LunchStatus.receiving,
      _ => pref.takeLunch ? LunchStatus.receiving : LunchStatus.skipped,
    };

    expect(status, LunchStatus.skipped);
    expect(status.label, 'Skipping lunch');
  });
}
