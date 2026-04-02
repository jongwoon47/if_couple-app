import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.userId,
    required this.email,
    required this.nickname,
    required this.partnerNickname,
    required this.statusMessage,
    required this.birthday,
    required this.language,
    required this.hasSeenConnectionComplete,
    required this.notificationAllEnabled,
    required this.notificationMessageEnabled,
    required this.notificationAlbumEnabled,
    required this.notificationAnniversaryEnabled,
    required this.notificationScheduleEnabled,
    required this.notificationTime,
    this.gender,
    this.coupleId,
    this.startDate,
    this.coupleJoinedAt,
    this.createdAt,
    this.lastCoupleId,
    this.coupleDisconnectedAt,
    this.privacyPolicyAcceptedAt,
    this.termsOfServiceAcceptedAt,
    this.ageConfirmedAt,
    this.marketingConsentAcceptedAt,
    this.privacyPolicyVersion,
    this.termsOfServiceVersion,
  });

  final String userId;
  final String email;
  final String nickname;
  final String partnerNickname;
  final String statusMessage;
  final DateTime? birthday;
  final String language;
  final bool hasSeenConnectionComplete;
  final bool notificationAllEnabled;
  final bool notificationMessageEnabled;
  final bool notificationAlbumEnabled;
  final bool notificationAnniversaryEnabled;
  final bool notificationScheduleEnabled;
  final String notificationTime;
  final String? gender;
  final String? coupleId;
  final DateTime? startDate;
  final DateTime? coupleJoinedAt;
  final DateTime? createdAt;
  /// 연결 해제 후 복구용(커플 문서 ID). 탈퇴 시에도 동일 ID로 데이터 정리에 사용.
  final String? lastCoupleId;
  final DateTime? coupleDisconnectedAt;
  /// 개인정보·이용약관 동의 시각. null이면 동의 화면을 띄움.
  final DateTime? privacyPolicyAcceptedAt;
  final DateTime? termsOfServiceAcceptedAt;
  final DateTime? ageConfirmedAt;
  final DateTime? marketingConsentAcceptedAt;
  final String? privacyPolicyVersion;
  final String? termsOfServiceVersion;

  bool get isProfileCompleted {
    // 프로필 완료 조건: 닉네임, 생일, 언어만 필수
    return nickname.trim().isNotEmpty &&
        birthday != null &&
        language.trim().isNotEmpty;
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'nickname': nickname,
      'partnerNickname': partnerNickname,
      'statusMessage': statusMessage,
      'birthday': birthday == null ? null : Timestamp.fromDate(birthday!),
      'language': language,
      'hasSeenConnectionComplete': hasSeenConnectionComplete,
      'notificationAllEnabled': notificationAllEnabled,
      'notificationMessageEnabled': notificationMessageEnabled,
      'notificationAlbumEnabled': notificationAlbumEnabled,
      'notificationAnniversaryEnabled': notificationAnniversaryEnabled,
      'notificationScheduleEnabled': notificationScheduleEnabled,
      'notificationTime': notificationTime,
      'gender': gender,
      'coupleId': coupleId,
      'startDate': startDate == null ? null : Timestamp.fromDate(startDate!),
      'coupleJoinedAt':
          coupleJoinedAt == null ? null : Timestamp.fromDate(coupleJoinedAt!),
      'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
      'lastCoupleId': lastCoupleId,
      'coupleDisconnectedAt': coupleDisconnectedAt == null
          ? null
          : Timestamp.fromDate(coupleDisconnectedAt!),
      'privacyPolicyAcceptedAt': privacyPolicyAcceptedAt == null
          ? null
          : Timestamp.fromDate(privacyPolicyAcceptedAt!),
      'termsOfServiceAcceptedAt': termsOfServiceAcceptedAt == null
          ? null
          : Timestamp.fromDate(termsOfServiceAcceptedAt!),
      'ageConfirmedAt':
          ageConfirmedAt == null ? null : Timestamp.fromDate(ageConfirmedAt!),
      'marketingConsentAcceptedAt': marketingConsentAcceptedAt == null
          ? null
          : Timestamp.fromDate(marketingConsentAcceptedAt!),
      'privacyPolicyVersion': privacyPolicyVersion,
      'termsOfServiceVersion': termsOfServiceVersion,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    DateTime? parseTimestamp(dynamic value) {
      if (value is Timestamp) return value.toDate();
      return null;
    }

    String? parseOptionalNonEmptyString(dynamic value) {
      if (value is String && value.trim().isNotEmpty) return value.trim();
      return null;
    }

    return AppUser(
      userId: (map['userId'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      nickname: (map['nickname'] ?? '') as String,
      partnerNickname: (map['partnerNickname'] ?? '') as String,
      statusMessage: (map['statusMessage'] ?? '') as String,
      birthday: parseTimestamp(map['birthday']),
      language: (map['language'] ?? '') as String,
      hasSeenConnectionComplete: (map['hasSeenConnectionComplete'] ?? true) as bool,
      notificationAllEnabled: (map['notificationAllEnabled'] ?? true) as bool,
      notificationMessageEnabled: (map['notificationMessageEnabled'] ?? true) as bool,
      notificationAlbumEnabled: (map['notificationAlbumEnabled'] ?? true) as bool,
      notificationAnniversaryEnabled: (map['notificationAnniversaryEnabled'] ?? true) as bool,
      notificationScheduleEnabled: (map['notificationScheduleEnabled'] ?? true) as bool,
      notificationTime: (map['notificationTime'] ?? '09:00') as String,
      gender: map['gender'] as String?,
      coupleId: map['coupleId'] as String?,
      startDate: parseTimestamp(map['startDate']),
      coupleJoinedAt: parseTimestamp(map['coupleJoinedAt']),
      createdAt: parseTimestamp(map['createdAt']),
      lastCoupleId: parseOptionalNonEmptyString(map['lastCoupleId']),
      coupleDisconnectedAt: parseTimestamp(map['coupleDisconnectedAt']),
      privacyPolicyAcceptedAt: parseTimestamp(map['privacyPolicyAcceptedAt']),
      termsOfServiceAcceptedAt: parseTimestamp(map['termsOfServiceAcceptedAt']),
      ageConfirmedAt: parseTimestamp(map['ageConfirmedAt']),
      marketingConsentAcceptedAt: parseTimestamp(map['marketingConsentAcceptedAt']),
      privacyPolicyVersion: parseOptionalNonEmptyString(map['privacyPolicyVersion']),
      termsOfServiceVersion: parseOptionalNonEmptyString(map['termsOfServiceVersion']),
    );
  }
}
