enum UserMode {
  creator('CREATOR'),
  runner('RUNNER');

  const UserMode(this.apiValue);

  final String apiValue;

  static UserMode fromApi(String raw) {
    return values.firstWhere(
      (mode) => mode.apiValue == raw,
      orElse: () => UserMode.creator,
    );
  }
}

enum OtpPurpose {
  login('LOGIN'),
  register('REGISTER');

  const OtpPurpose(this.apiValue);

  final String apiValue;

  static OtpPurpose fromApi(String raw) {
    return values.firstWhere(
      (purpose) => purpose.apiValue == raw,
      orElse: () => OtpPurpose.login,
    );
  }
}

class OtpReceipt {
  const OtpReceipt({
    required this.requestId,
    required this.phoneNumber,
    required this.purpose,
    required this.otpCode,
    required this.expiresAt,
    required this.registered,
  });

  final String requestId;
  final String phoneNumber;
  final OtpPurpose purpose;
  final String otpCode;
  final DateTime expiresAt;
  final bool registered;

  factory OtpReceipt.fromJson(Map<String, dynamic> json) {
    return OtpReceipt(
      requestId: json['requestId'].toString(),
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      purpose: OtpPurpose.fromApi(json['purpose']?.toString() ?? 'LOGIN'),
      otpCode: json['otpCode']?.toString() ?? '',
      expiresAt:
          DateTime.tryParse(json['expiresAt']?.toString() ?? '') ??
          DateTime.now().add(const Duration(minutes: 5)),
      registered: json['registered'] == true,
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.userId,
    required this.displayName,
    required this.avatarEmoji,
    required this.phoneNumber,
    required this.currentMode,
    required this.creditScore,
    required this.communityName,
    required this.buildingName,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresInSeconds,
  });

  final String userId;
  final String displayName;
  final String avatarEmoji;
  final String phoneNumber;
  final UserMode currentMode;
  final double creditScore;
  final String? communityName;
  final String? buildingName;
  final String accessToken;
  final String refreshToken;
  final int expiresInSeconds;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      userId: json['userId'].toString(),
      displayName: json['displayName']?.toString() ?? '社区用户',
      avatarEmoji: json['avatarEmoji']?.toString() ?? '邻',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      currentMode: UserMode.fromApi(
        json['currentMode']?.toString() ?? 'CREATOR',
      ),
      creditScore: (json['creditScore'] as num?)?.toDouble() ?? 90,
      communityName: json['communityName']?.toString(),
      buildingName: json['buildingName']?.toString(),
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt() ?? 1800,
    );
  }
}

class UserSettingsPayload {
  const UserSettingsPayload({
    this.displayName,
    this.avatarEmoji,
    this.bio,
    this.communityName,
    this.communityId,
    this.buildingName,
    this.buildingId,
    this.roomMask,
    this.notificationsEnabled,
    this.privacyMasked,
    this.latitude,
    this.longitude,
  });

  final String? displayName;
  final String? avatarEmoji;
  final String? bio;
  final String? communityName;
  final String? communityId;
  final String? buildingName;
  final String? buildingId;
  final String? roomMask;
  final bool? notificationsEnabled;
  final bool? privacyMasked;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'displayName': displayName,
      'avatarEmoji': avatarEmoji,
      'bio': bio,
      'communityName': communityName,
      'communityId': communityId,
      'buildingName': buildingName,
      'buildingId': buildingId,
      'roomMask': roomMask,
      'notificationsEnabled': notificationsEnabled,
      'privacyMasked': privacyMasked,
      'latitude': latitude,
      'longitude': longitude,
    }..removeWhere((_, value) => value == null);
  }
}

class UserProfile {
  const UserProfile({
    required this.userId,
    required this.displayName,
    required this.avatarEmoji,
    required this.bio,
    required this.phoneNumber,
    required this.currentMode,
    required this.creditScore,
    required this.communityName,
    required this.buildingName,
    required this.roomMask,
    required this.notificationsEnabled,
    required this.privacyMasked,
    required this.communityVerified,
    required this.creatorWalletBalance,
    required this.creatorFrozenBalance,
    required this.runnerWalletBalance,
    required this.runnerFrozenBalance,
    required this.latitude,
    required this.longitude,
  });

  final String userId;
  final String displayName;
  final String avatarEmoji;
  final String bio;
  final String phoneNumber;
  final UserMode currentMode;
  final double creditScore;
  final String? communityName;
  final String? buildingName;
  final String? roomMask;
  final bool notificationsEnabled;
  final bool privacyMasked;
  final bool communityVerified;
  final double creatorWalletBalance;
  final double creatorFrozenBalance;
  final double runnerWalletBalance;
  final double runnerFrozenBalance;
  final double? latitude;
  final double? longitude;

  String get maskedPhoneNumber {
    if (phoneNumber.length < 7) {
      return phoneNumber;
    }
    return '${phoneNumber.substring(0, 3)}****${phoneNumber.substring(phoneNumber.length - 4)}';
  }

  UserProfile copyWith({
    UserMode? currentMode,
    String? displayName,
    String? avatarEmoji,
    String? bio,
    String? communityName,
    String? buildingName,
    String? roomMask,
    bool? notificationsEnabled,
    bool? privacyMasked,
    double? latitude,
    double? longitude,
  }) {
    return UserProfile(
      userId: userId,
      displayName: displayName ?? this.displayName,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      bio: bio ?? this.bio,
      phoneNumber: phoneNumber,
      currentMode: currentMode ?? this.currentMode,
      creditScore: creditScore,
      communityName: communityName ?? this.communityName,
      buildingName: buildingName ?? this.buildingName,
      roomMask: roomMask ?? this.roomMask,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      privacyMasked: privacyMasked ?? this.privacyMasked,
      communityVerified: communityVerified,
      creatorWalletBalance: creatorWalletBalance,
      creatorFrozenBalance: creatorFrozenBalance,
      runnerWalletBalance: runnerWalletBalance,
      runnerFrozenBalance: runnerFrozenBalance,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'].toString(),
      displayName: json['displayName']?.toString() ?? '社区用户',
      avatarEmoji: json['avatarEmoji']?.toString() ?? '邻',
      bio: json['bio']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      currentMode: UserMode.fromApi(
        json['currentMode']?.toString() ?? 'CREATOR',
      ),
      creditScore: (json['creditScore'] as num?)?.toDouble() ?? 98.0,
      communityName: json['communityName']?.toString(),
      buildingName: json['buildingName']?.toString(),
      roomMask: json['roomMask']?.toString(),
      notificationsEnabled: json['notificationsEnabled'] != false,
      privacyMasked: json['privacyMasked'] != false,
      communityVerified: json['communityVerified'] == true,
      creatorWalletBalance:
          (json['creatorWalletBalance'] as num?)?.toDouble() ?? 0,
      creatorFrozenBalance:
          (json['creatorFrozenBalance'] as num?)?.toDouble() ?? 0,
      runnerWalletBalance:
          (json['runnerWalletBalance'] as num?)?.toDouble() ?? 0,
      runnerFrozenBalance:
          (json['runnerFrozenBalance'] as num?)?.toDouble() ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
