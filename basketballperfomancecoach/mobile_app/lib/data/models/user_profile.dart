class AthleteInfo {
  const AthleteInfo({
    required this.bmi,
    required this.bmiCategory,
    required this.profileLabel,
  });

  final double? bmi;
  final String bmiCategory;
  final String profileLabel;

  factory AthleteInfo.fromJson(Map<String, dynamic>? json) {
    return AthleteInfo(
      bmi: (json?['bmi'] as num?)?.toDouble(),
      bmiCategory: json?['bmi_category']?.toString() ?? 'Not set',
      profileLabel: json?['profile_label']?.toString() ?? 'Setup required',
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.height,
    required this.weight,
    required this.age,
    required this.gender,
    required this.profilePhotoUrl,
    required this.trainingLevel,
    required this.intermediateAccessApproved,
    required this.isPersonalized,
    required this.athleteInfo,
  });

  final int id;
  final String name;
  final String email;
  final double? height;
  final double? weight;
  final int? age;
  final String? gender;
  final String? profilePhotoUrl;
  final String? trainingLevel;
  final bool intermediateAccessApproved;
  final bool isPersonalized;
  final AthleteInfo athleteInfo;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      age: (json['age'] as num?)?.toInt(),
      gender: json['gender']?.toString(),
      profilePhotoUrl: json['profile_photo_url']?.toString(),
      trainingLevel: json['training_level']?.toString(),
      intermediateAccessApproved: json['intermediate_access_approved'] == true,
      isPersonalized: json['is_personalized'] == true,
      athleteInfo: AthleteInfo.fromJson(
        json['athlete_info'] as Map<String, dynamic>?,
      ),
    );
  }
}
