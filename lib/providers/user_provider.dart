import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier();
});

class UserNotifier extends StateNotifier<UserState> {
  UserNotifier() : super(UserState.initial());

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<void> fetchUserData() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not signed in');
      }

      final snapshot = await _database.child('alumni').get();

      if (snapshot.exists) {
        bool userFound = false;
        for (var courseNode in snapshot.children) {
          final courseKey = courseNode.key;
          final userSnapshot = await _database
              .child('alumni')
              .child(courseKey!)
              .child(user.uid)
              .get();

          if (userSnapshot.exists) {
            final userData =
                Map<String, dynamic>.from(userSnapshot.value as Map);
            final visibilityData =
                Map<String, dynamic>.from(userData['visibility'] as Map);

            state = state.copyWith(
              isLoading: false,
              name: userData['name'] ?? 'User',
              email: userData['email'] ?? 'No email',
              imageUrl: userData['imageUrl'],
              blurHash: userData['blurHash'],
              course: userData['course'] ?? 'Unknown course',
              year: userData['year'] ?? 'Unknown year',
              address: userData['address'] ?? 'No address',
              city: userData['city'] ?? 'No city',
              designation: userData['designation'] ?? 'No designation',
              dob: userData['dob'] ?? 'No DOB',
              organization: userData['organization'] ?? 'No organization',
              phone: userData['phone'] ?? 'No phone',
              linkedin: userData['linkedin'] ?? 'No LinkedIn',
              role: userData['role'] ?? 'user',
              error: null,
              addressVisibility: visibilityData['address'] ?? false,
              cityVisibility: visibilityData['city'] ?? false,
              courseVisibility: visibilityData['course'] ?? false,
              designationVisibility: visibilityData['designation'] ?? false,
              dobVisibility: visibilityData['dob'] ?? false,
              emailVisibility: visibilityData['email'] ?? false,
              nameVisibility: visibilityData['name'] ?? false,
              organizationVisibility: visibilityData['organization'] ?? false,
              phoneVisibility: visibilityData['phone'] ?? false,
              linkedinVisibility: visibilityData['linkedin'] ?? false,
            );
            userFound = true;
            break;
          }
        }

        if (!userFound) {
          throw Exception('User data not found');
        }
      } else {
        throw Exception('No alumni data found');
      }
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  void updateVisibilitySettings({
    required bool addressVisibility,
    required bool cityVisibility,
    required bool courseVisibility,
    required bool designationVisibility,
    required bool dobVisibility,
    required bool emailVisibility,
    required bool linkedinVisibility,
    required bool nameVisibility,
    required bool organizationVisibility,
    required bool phoneVisibility,
    required bool yearVisibility,
  }) {
    state = state.copyWith(
      addressVisibility: addressVisibility,
      cityVisibility: cityVisibility,
      courseVisibility: courseVisibility,
      designationVisibility: designationVisibility,
      dobVisibility: dobVisibility,
      emailVisibility: emailVisibility,
      linkedinVisibility: linkedinVisibility,
      nameVisibility: nameVisibility,
      organizationVisibility: organizationVisibility,
      phoneVisibility: phoneVisibility,
      yearVisibility: yearVisibility,
    );
  }
}

class UserState {
  final bool isLoading;
  final String name;
  final String email;
  final String course;
  final String year;
  final String? imageUrl;
  final String? blurHash;
  final String? address;
  final String? city;
  final String? designation;
  final String? dob;
  final String? organization;
  final String? phone;
  final String? linkedin;
  final String? error;
  final String? role;

  // Visibility fields
  final bool addressVisibility;
  final bool cityVisibility;
  final bool courseVisibility;
  final bool designationVisibility;
  final bool dobVisibility;
  final bool emailVisibility;
  final bool nameVisibility;
  final bool organizationVisibility;
  final bool phoneVisibility;
  final bool linkedinVisibility;
  final bool yearVisibility;

  UserState({
    required this.isLoading,
    required this.name,
    required this.email,
    required this.course,
    required this.year,
    this.imageUrl,
    this.blurHash,
    this.address,
    this.city,
    this.designation,
    this.dob,
    this.organization,
    this.phone,
    this.linkedin,
    this.error,
    this.role,
    required this.addressVisibility,
    required this.cityVisibility,
    required this.courseVisibility,
    required this.designationVisibility,
    required this.dobVisibility,
    required this.emailVisibility,
    required this.nameVisibility,
    required this.organizationVisibility,
    required this.phoneVisibility,
    required this.linkedinVisibility,
    required this.yearVisibility,
  });

  factory UserState.initial() {
    return UserState(
        isLoading: false,
        name: '',
        email: '',
        course: '',
        year: '',
        role: 'user',
        imageUrl: null,
        blurHash: null,
        address: null,
        city: null,
        designation: null,
        dob: null,
        organization: null,
        phone: null,
        linkedin: null,
        error: null,
        addressVisibility: false,
        cityVisibility: true,
        courseVisibility: true,
        designationVisibility: true,
        dobVisibility: false,
        emailVisibility: false,
        nameVisibility: true,
        organizationVisibility: false,
        phoneVisibility: false,
        linkedinVisibility: true,
        yearVisibility: true);
  }

  UserState copyWith({
    bool? isLoading,
    String? name,
    String? email,
    String? course,
    String? year,
    String? imageUrl,
    String? blurHash,
    String? address,
    String? city,
    String? designation,
    String? dob,
    String? organization,
    String? phone,
    String? linkedin,
    String? error,
    String? role,
    bool? addressVisibility,
    bool? cityVisibility,
    bool? courseVisibility,
    bool? designationVisibility,
    bool? dobVisibility,
    bool? emailVisibility,
    bool? nameVisibility,
    bool? organizationVisibility,
    bool? phoneVisibility,
    bool? linkedinVisibility,
    bool? yearVisibility,
  }) {
    return UserState(
      isLoading: isLoading ?? this.isLoading,
      name: name ?? this.name,
      email: email ?? this.email,
      course: course ?? this.course,
      year: year ?? this.year,
      imageUrl: imageUrl ?? this.imageUrl,
      blurHash: blurHash ?? this.blurHash,
      address: address ?? this.address,
      city: city ?? this.city,
      designation: designation ?? this.designation,
      dob: dob ?? this.dob,
      organization: organization ?? this.organization,
      phone: phone ?? this.phone,
      linkedin: linkedin ?? this.linkedin,
      error: error ?? this.error,
      role: role ?? this.role,
      addressVisibility: addressVisibility ?? this.addressVisibility,
      cityVisibility: cityVisibility ?? this.cityVisibility,
      courseVisibility: courseVisibility ?? this.courseVisibility,
      designationVisibility:
          designationVisibility ?? this.designationVisibility,
      dobVisibility: dobVisibility ?? this.dobVisibility,
      emailVisibility: emailVisibility ?? this.emailVisibility,
      nameVisibility: nameVisibility ?? this.nameVisibility,
      organizationVisibility:
          organizationVisibility ?? this.organizationVisibility,
      phoneVisibility: phoneVisibility ?? this.phoneVisibility,
      linkedinVisibility: linkedinVisibility ?? this.linkedinVisibility,
      yearVisibility: yearVisibility ?? this.yearVisibility,
    );
  }
}
