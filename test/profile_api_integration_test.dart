import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Profile API Integration Tests', () {
    test('ProfileModel should serialize and deserialize correctly', () {
      // Test profile model serialization
      final profile = ProfileModel(
        id: 1,
        fullName: 'John Doe',
        email: 'john.doe@example.com',
        phoneNumber: '+1234567890',
        reraNumber: 'RERA123456',
        teamLeaderName: 'Jane Smith',
        idNumber: 'ID123456789',
        profilePhotoUrl: 'https://example.com/photo.jpg',
        isActive: true,
      );

      // Test toJson
      final json = profile.toJson();
      expect(json['id'], equals(1));
      expect(json['full_name'], equals('John Doe'));
      expect(json['email'], equals('john.doe@example.com'));
      expect(json['phone_number'], equals('+1234567890'));
      expect(json['rera_number'], equals('RERA123456'));
      expect(json['team_leader_name'], equals('Jane Smith'));
      expect(json['id_number'], equals('ID123456789'));
      expect(json['profile_photo_url'], equals('https://example.com/photo.jpg'));
      expect(json['is_active'], equals(true));

      // Test fromJson
      final deserializedProfile = ProfileModel.fromJson(json);
      expect(deserializedProfile.id, equals(1));
      expect(deserializedProfile.fullName, equals('John Doe'));
      expect(deserializedProfile.email, equals('john.doe@example.com'));
      expect(deserializedProfile.phoneNumber, equals('+1234567890'));
      expect(deserializedProfile.reraNumber, equals('RERA123456'));
      expect(deserializedProfile.teamLeaderName, equals('Jane Smith'));
      expect(deserializedProfile.idNumber, equals('ID123456789'));
      expect(deserializedProfile.profilePhotoUrl, equals('https://example.com/photo.jpg'));
      expect(deserializedProfile.isActive, equals(true));
    });

    test('ProfileApiResponse should handle success response correctly', () {
      final json = {
        'success': true,
        'message': 'Profile retrieved successfully',
        'data': {
          'id': 1,
          'full_name': 'John Doe',
          'email': 'john.doe@example.com',
          'phone_number': '+1234567890',
        },
      };

      final response = ProfileApiResponse.fromJson(json);
      expect(response.success, equals(true));
      expect(response.message, equals('Profile retrieved successfully'));
      expect(response.data, isNotNull);
      expect(response.data!.fullName, equals('John Doe'));
      expect(response.data!.email, equals('john.doe@example.com'));
    });

    test('ProfileApiResponse should handle error response correctly', () {
      final json = {
        'success': false,
        'message': 'Profile not found',
        'errors': {
          'email': ['Email is required'],
          'phone_number': ['Phone number is invalid'],
        },
      };

      final response = ProfileApiResponse.fromJson(json);
      expect(response.success, equals(false));
      expect(response.message, equals('Profile not found'));
      expect(response.data, isNull);
      expect(response.errors, isNotNull);
      expect(response.errors!['email'], equals(['Email is required']));
    });

    test('UpdateProfileRequest should serialize correctly', () {
      final request = UpdateProfileRequest(
        fullName: 'John Updated',
        email: 'john.updated@example.com',
        phoneNumber: '+9876543210',
        teamLeaderName: 'Updated Leader',
      );

      final json = request.toJson();
      expect(json['full_name'], equals('John Updated'));
      expect(json['email'], equals('john.updated@example.com'));
      expect(json['phone_number'], equals('+9876543210'));
      expect(json['team_leader_name'], equals('Updated Leader'));
      
      // Should not include null values
      expect(json.containsKey('rera_number'), equals(false));
      expect(json.containsKey('id_number'), equals(false));
    });

    test('ProfileModel should generate correct initials', () {
      final profile1 = ProfileModel(
        fullName: 'John Doe',
        email: 'john.doe@example.com',
        phoneNumber: '+1234567890',
      );
      expect(profile1.initials, equals('JD'));

      final profile2 = ProfileModel(
        fullName: 'Jane',
        email: 'jane@example.com',
        phoneNumber: '+1234567890',
      );
      expect(profile2.initials, equals('J'));

      final profile3 = ProfileModel(
        fullName: '',
        email: 'user@example.com',
        phoneNumber: '+1234567890',
      );
      expect(profile3.initials, equals('U'));

      final profile4 = ProfileModel(
        fullName: '',
        email: '',
        phoneNumber: '+1234567890',
      );
      expect(profile4.initials, equals('U'));
    });

    test('ProfileModel should generate correct display name', () {
      final profile1 = ProfileModel(
        fullName: 'John Doe',
        email: 'john.doe@example.com',
        phoneNumber: '+1234567890',
      );
      expect(profile1.displayName, equals('John Doe'));

      final profile2 = ProfileModel(
        fullName: '',
        email: 'jane.smith@example.com',
        phoneNumber: '+1234567890',
      );
      expect(profile2.displayName, equals('jane.smith'));
    });
  });
}

