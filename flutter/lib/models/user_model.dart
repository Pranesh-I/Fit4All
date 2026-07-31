// lib/models/user_model.dart
// SAI Sports Talent Assessment - User Data Model

class UserModel {
  final String id;
  final String fullName;
  final DateTime dateOfBirth;
  final String gender;
  final String mobileNumber;
  final String state;
  final String district;
  final String sportInterest;
  final double heightCm;
  final double weightKg;
  final bool isPhoneVerified;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    required this.mobileNumber,
    required this.state,
    required this.district,
    required this.sportInterest,
    required this.heightCm,
    required this.weightKg,
    required this.isPhoneVerified,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      dateOfBirth: DateTime.parse(json['date_of_birth'] as String),
      gender: json['gender'] as String,
      mobileNumber: json['mobile_number'] as String,
      state: json['state'] as String,
      district: json['district'] as String,
      sportInterest: json['sport_interest'] as String,
      heightCm: (json['height_cm'] as num).toDouble(),
      weightKg: (json['weight_kg'] as num).toDouble(),
      isPhoneVerified: json['is_phone_verified'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'date_of_birth': dateOfBirth.toIso8601String().split('T')[0],
        'gender': gender,
        'mobile_number': mobileNumber,
        'state': state,
        'district': district,
        'sport_interest': sportInterest,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'is_phone_verified': isPhoneVerified,
        'created_at': createdAt.toIso8601String(),
      };

  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    DateTime? dateOfBirth,
    String? gender,
    String? mobileNumber,
    String? state,
    String? district,
    String? sportInterest,
    double? heightCm,
    double? weightKg,
    bool? isPhoneVerified,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      state: state ?? this.state,
      district: district ?? this.district,
      sportInterest: sportInterest ?? this.sportInterest,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
