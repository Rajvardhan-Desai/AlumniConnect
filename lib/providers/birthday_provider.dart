import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

final birthdayProvider =
StateNotifierProvider<BirthdayNotifier, BirthdayState>((ref) {
  return BirthdayNotifier();
});

class BirthdayNotifier extends StateNotifier<BirthdayState> {
  BirthdayNotifier() : super(BirthdayState.initial());

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<void> fetchUpcomingBirthdays() async {
    state = state.copyWith(isLoading: true);
    try {
      final snapshot = await _database.child('alumni').get();
      if (snapshot.exists) {
        final Map<String, dynamic> allUsersData =
        Map<String, dynamic>.from(snapshot.value as Map);

        DateTime now = DateTime.now();
        List<Map<String, dynamic>> birthdays = [];

        allUsersData.forEach((key, value) {
          final userData = Map<String, dynamic>.from(value as Map);
          if (userData.containsKey('dob')) {
            DateTime dob = DateFormat('dd/MM/yyyy').parse(userData['dob']);
            DateTime nextBirthday = DateTime(now.year, dob.month, dob.day);
            if (nextBirthday.isBefore(now)) {
              nextBirthday = DateTime(now.year + 1, dob.month, dob.day);
            }
            if (nextBirthday.difference(now).inDays <= 30) {
              birthdays.add({
                'name': userData['name'],
                'dob': userData['dob'],
                'designation': userData['designation'],
                'address': userData['address'],
                'city': userData['city'],
                'course': userData['course'],
                'email': userData['email'],
                'organization': userData['organization'],
                'phone': userData['phone'],
                'imageUrl': userData['imageUrl'],
                'blurHash': userData['blurHash'],
                'year': userData['year'],
                'nextBirthday': nextBirthday,
              });
            }
          }
        });

        birthdays.sort((a, b) => a['nextBirthday'].compareTo(b['nextBirthday']));
        state = state.copyWith(isLoading: false, upcomingBirthdays: birthdays);
      } else {
        throw Exception('No alumni data found');
      }
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }
}

class BirthdayState {
  final bool isLoading;
  final List<Map<String, dynamic>> upcomingBirthdays;
  final String? error;

  BirthdayState({
    required this.isLoading,
    required this.upcomingBirthdays,
    this.error,
  });

  factory BirthdayState.initial() {
    return BirthdayState(
      isLoading: false,
      upcomingBirthdays: [],
      error: null,
    );
  }

  BirthdayState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? upcomingBirthdays,
    String? error,
  }) {
    return BirthdayState(
      isLoading: isLoading ?? this.isLoading,
      upcomingBirthdays: upcomingBirthdays ?? this.upcomingBirthdays,
      error: error ?? this.error,
    );
  }
}
