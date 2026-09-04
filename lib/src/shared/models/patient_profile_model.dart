import 'dart:convert';

class PatientProfileModel {
  final String userId;
  final String bloodType;
  final String allergies;
  final String dateOfBirth;
  final String gender;
  final Map<String, dynamic> demographics;

  PatientProfileModel({
    required this.userId,
    this.bloodType = 'B+',
    this.allergies = 'None',
    this.dateOfBirth = '1985-06-15',
    this.gender = 'Male',
    Map<String, dynamic>? demographics,
  }) : demographics = demographics ?? {};

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'blood_type': bloodType,
      'allergies': allergies,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'demographics_json': jsonEncode(demographics),
    };
  }

  factory PatientProfileModel.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> parsedDemographics = {};
    if (map['demographics_json'] != null) {
      try {
        parsedDemographics = jsonDecode(map['demographics_json'] as String) as Map<String, dynamic>;
      } catch (_) {}
    }

    return PatientProfileModel(
      userId: map['user_id'] as String,
      bloodType: map['blood_type'] as String? ?? 'B+',
      allergies: map['allergies'] as String? ?? 'None',
      dateOfBirth: map['date_of_birth'] as String? ?? '1985-06-15',
      gender: map['gender'] as String? ?? 'Male',
      demographics: parsedDemographics,
    );
  }

  PatientProfileModel copyWith({
    String? userId,
    String? bloodType,
    String? allergies,
    String? dateOfBirth,
    String? gender,
    Map<String, dynamic>? demographics,
  }) {
    return PatientProfileModel(
      userId: userId ?? this.userId,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      demographics: demographics ?? this.demographics,
    );
  }
}
