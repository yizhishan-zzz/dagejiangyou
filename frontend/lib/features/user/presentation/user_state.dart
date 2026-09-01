import 'package:flutter/foundation.dart';

import '../../../core/config/app_settings.dart';
import '../../../core/network/api_client.dart';
import '../data/user_repository.dart';
import '../domain/user_profile.dart';

class UserState extends ChangeNotifier {
  UserState({required this.settings, required this.repository}) {
    settings.addListener(_handleSessionChange);
  }

  final AppSettings settings;
  final UserRepository repository;

  UserProfile? profile;
  UserMode _currentMode = UserMode.creator;
  OtpReceipt? latestOtpReceipt;
  bool isLoadingProfile = false;
  bool isTogglingMode = false;
  bool isSendingOtp = false;
  bool isAuthenticating = false;
  bool isSavingSettings = false;
  String? errorMessage;

  void _handleSessionChange() {
    if (!settings.isLoggedIn && profile != null) {
      profile = null;
      latestOtpReceipt = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    settings.removeListener(_handleSessionChange);
    super.dispose();
  }

  UserMode get currentMode => profile?.currentMode ?? _currentMode;
  bool get isCreator => currentMode == UserMode.creator;
  bool get isRunner => currentMode == UserMode.runner;
  bool get isLoggedIn => settings.isLoggedIn;

  Future<void> initialize() async {
    if (settings.isLoggedIn) {
      await refreshProfile(silent: true);
    }
  }

  Future<void> refreshProfile({bool silent = false}) async {
    if (!settings.isLoggedIn) {
      profile = null;
      errorMessage = null;
      notifyListeners();
      return;
    }

    if (!silent) {
      isLoadingProfile = true;
      notifyListeners();
    }

    try {
      profile = await repository.fetchProfile();
      _currentMode = profile!.currentMode;
      final latitude = profile!.latitude;
      final longitude = profile!.longitude;
      if (latitude != null && longitude != null) {
        await settings.saveLocation(latitude: latitude, longitude: longitude);
      }
      errorMessage = null;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } finally {
      isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<void> sendOtp({
    required String phoneNumber,
    required OtpPurpose purpose,
  }) async {
    isSendingOtp = true;
    notifyListeners();

    try {
      latestOtpReceipt = await repository.sendOtp(
        phoneNumber: phoneNumber,
        purpose: purpose,
      );
      errorMessage = null;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } finally {
      isSendingOtp = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String requestId,
    required String phoneNumber,
    required String otpCode,
  }) async {
    isAuthenticating = true;
    notifyListeners();

    try {
      final session = await repository.login(
        requestId: requestId,
        phoneNumber: phoneNumber,
        otpCode: otpCode,
      );
      await settings.saveSession(
        session.userId,
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      latestOtpReceipt = null;
      errorMessage = null;
      await refreshProfile(silent: true);
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return false;
    } finally {
      isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithPassword({
    required String phoneNumber,
    required String password,
  }) async {
    isAuthenticating = true;
    notifyListeners();

    try {
      final session = await repository.loginWithPassword(
        phoneNumber: phoneNumber,
        password: password,
      );
      await settings.saveSession(
        session.userId,
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      latestOtpReceipt = null;
      errorMessage = null;
      await refreshProfile(silent: true);
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return false;
    } finally {
      isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String phoneNumber,
    required String password,
    required String displayName,
    required String communityName,
    required String buildingName,
    required bool termsAccepted,
  }) async {
    isAuthenticating = true;
    notifyListeners();

    try {
      final session = await repository.register(
        phoneNumber: phoneNumber,
        password: password,
        displayName: displayName,
        communityName: communityName,
        buildingName: buildingName,
        termsAccepted: termsAccepted,
      );
      await settings.saveSession(
        session.userId,
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      latestOtpReceipt = null;
      errorMessage = null;
      await refreshProfile(silent: true);
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return false;
    } finally {
      isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<void> toggleMode() async {
    if (!settings.isLoggedIn) {
      errorMessage = '当前尚未登录，暂时无法切换身份。';
      notifyListeners();
      return;
    }

    isTogglingMode = true;
    notifyListeners();

    try {
      final nextMode = await repository.toggleMode();
      _currentMode = nextMode;
      profile = profile?.copyWith(currentMode: nextMode);
      errorMessage = null;
      await refreshProfile(silent: true);
    } on ApiException catch (error) {
      errorMessage = error.message;
    } finally {
      isTogglingMode = false;
      notifyListeners();
    }
  }

  Future<bool> updateSettings(UserSettingsPayload payload) async {
    isSavingSettings = true;
    notifyListeners();

    try {
      profile = await repository.updateProfileSettings(payload);
      _currentMode = profile!.currentMode;
      errorMessage = null;
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return false;
    } finally {
      isSavingSettings = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (settings.refreshToken.isNotEmpty) {
      try {
        await repository.logout(settings.refreshToken);
      } on ApiException {
        // Clear the local session even when the network is unavailable.
      }
    }
    await settings.clearSession();
    profile = null;
    latestOtpReceipt = null;
    _currentMode = UserMode.creator;
    errorMessage = null;
    notifyListeners();
  }
}
