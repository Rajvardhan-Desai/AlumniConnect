import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

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

      // Fetch the user's course from the general path
      final snapshot = await _database.child('alumni').get();

      if (snapshot.exists) {
        bool userFound = false;
        for (var courseNode in snapshot.children) {
          final courseKey = courseNode.key;
          final userSnapshot = await _database.child('alumni').child(courseKey!).child(user.uid).get();

          if (userSnapshot.exists) {
            final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
            state = state.copyWith(
              isLoading: false,
              name: userData['name'] ?? 'User',
              email: userData['email'] ?? 'No email',
              imageUrl: userData['imageUrl'],
              blurHash: userData['blurHash'],
              course: userData['course'] ?? 'Unknown course',
              year: userData['year'] ?? 'Unknown year',
              error: null,
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
}

class UserState {
  final bool isLoading;
  final String name;
  final String email;
  final String course;
  final String year;
  final String? imageUrl;
  final String? blurHash;
  final String? error;

  UserState({
    required this.isLoading,
    required this.name,
    required this.email,
    required this.course,
    required this.year,
    this.imageUrl,
    this.blurHash,
    this.error,
  });

  factory UserState.initial() {
    return UserState(
      isLoading: false,
      name: '',
      email: '',
      course: '',
      year: '',
      imageUrl: null,
      blurHash: null,
      error: null,
    );
  }

  UserState copyWith({
    bool? isLoading,
    String? name,
    String? email,
    String? course,
    String? year,
    String? imageUrl,
    String? blurHash,
    String? error,
  }) {
    return UserState(
      isLoading: isLoading ?? this.isLoading,
      name: name ?? this.name,
      email: email ?? this.email,
      course: course ?? this.course,
      year: year ?? this.year,
      imageUrl: imageUrl ?? this.imageUrl,
      blurHash: blurHash ?? this.blurHash,
      error: error ?? this.error,
    );
  }
}
