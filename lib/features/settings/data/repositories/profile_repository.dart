import '../../domain/models/account_profile.dart';
import '../../../team/domain/models/employee.dart';
import '../datasources/profile_api.dart';
import '../datasources/profile_cache.dart';

class ProfileRepository {
  const ProfileRepository(
      {required ProfileApi api, required ProfileCache cache})
      : _api = api,
        _cache = cache;

  final ProfileApi _api;
  final ProfileCache _cache;

  Future<AccountProfile> fetch(String token) => _api.fetch(token);

  Future<AccountProfile> update(String token, Employee employee,
      {String? photo}) async {
    await _api.update(token, employee, photo: photo);
    try {
      final fresh = await _api.fetch(token);
      final saved = fresh.employeeProfile;
      if (saved == null) {
        throw const FormatException(
            'Profile updated, but the employee details could not be confirmed. Reopen your profile to refresh.');
      }
      if (saved.dateOfBirth != employee.dateOfBirth ||
          saved.emergencyContactName != employee.emergencyContactName ||
          saved.emergencyContactPhone != employee.emergencyContactPhone) {
        throw const FormatException(
            'Profile updated, but the backend did not save all personal or emergency details. Reopen your profile to check the saved values.');
      }
      if (photo != null && saved.photoUrl != null) {
        return AccountProfile.fromJson({
          ...fresh.toJson(),
          'employee_profile': {...saved.toJson(), 'photoBase64': photo},
        });
      }
      if (photo != null) {
        throw const FormatException(
            'Profile updated, but the server did not return the uploaded photo. Reopen your profile to refresh.');
      }
      return fresh;
    } catch (error) {
      throw FormatException(error is FormatException &&
              error.message.startsWith('Profile updated')
          ? error.message
          : 'Profile updated, but it could not be refreshed. Reopen your profile to load the saved information.');
    }
  }

  Future<AccountProfile?> readCache(String userId) => _cache.read(userId);

  Future<void> saveCache(AccountProfile profile) => _cache.save(profile);
}
