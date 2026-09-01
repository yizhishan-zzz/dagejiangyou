import '../../../core/network/api_client.dart';
import '../domain/user_profile.dart';

class UserRepository {
  const UserRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<OtpReceipt> sendOtp({
    required String phoneNumber,
    required OtpPurpose purpose,
  }) async {
    final data =
        await _apiClient.post(
              '/users/auth/send-otp',
              withAuth: false,
              data: {'phoneNumber': phoneNumber, 'purpose': purpose.apiValue},
            )
            as Map<String, dynamic>;
    return OtpReceipt.fromJson(data);
  }

  Future<AuthSession> login({
    required String requestId,
    required String phoneNumber,
    required String otpCode,
  }) async {
    final data =
        await _apiClient.post(
              '/users/auth/login',
              withAuth: false,
              data: {
                'requestId': requestId,
                'phoneNumber': phoneNumber,
                'otpCode': otpCode,
              },
            )
            as Map<String, dynamic>;
    return AuthSession.fromJson(data);
  }

  Future<AuthSession> loginWithPassword({
    required String phoneNumber,
    required String password,
  }) async {
    final data =
        await _apiClient.post(
              '/users/auth/password-login',
              withAuth: false,
              data: {'phoneNumber': phoneNumber, 'password': password},
            )
            as Map<String, dynamic>;
    return AuthSession.fromJson(data);
  }

  Future<AuthSession> register({
    required String phoneNumber,
    required String password,
    required String displayName,
    required String communityName,
    required String buildingName,
    required bool termsAccepted,
  }) async {
    final data =
        await _apiClient.post(
              '/users/auth/register',
              withAuth: false,
              data: {
                'phoneNumber': phoneNumber,
                'password': password,
                'displayName': displayName,
                'communityName': communityName,
                'buildingName': buildingName,
                'termsAccepted': termsAccepted,
              },
            )
            as Map<String, dynamic>;
    return AuthSession.fromJson(data);
  }

  Future<UserProfile> fetchProfile() async {
    final data = await _apiClient.get('/users/profile') as Map<String, dynamic>;
    return UserProfile.fromJson(data);
  }

  Future<UserProfile> updateProfileSettings(UserSettingsPayload payload) async {
    final data =
        await _apiClient.put('/users/profile/settings', data: payload.toJson())
            as Map<String, dynamic>;
    return UserProfile.fromJson(data);
  }

  Future<UserMode> toggleMode() async {
    final data =
        await _apiClient.post('/users/auth/toggle-mode')
            as Map<String, dynamic>;
    return UserMode.fromApi(data['currentMode']?.toString() ?? 'CREATOR');
  }

  Future<void> logout(String refreshToken) async {
    await _apiClient.post(
      '/users/auth/logout',
      withAuth: false,
      data: {'refreshToken': refreshToken},
    );
  }

  Future<AuthSession> refresh(String refreshToken) async {
    final data =
        await _apiClient.post(
              '/users/auth/refresh',
              withAuth: false,
              data: {'refreshToken': refreshToken},
            )
            as Map<String, dynamic>;
    return AuthSession.fromJson(data);
  }
}
