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
        List<Map<String, dynamic>> birthdays = [];
        DateTime now = DateTime.now();
        DateTime today = DateTime(now.year, now.month, now.day);

        // Loop through each course node
        for (var courseNode in snapshot.children) {
          final Map<String, dynamic> usersData =
          Map<String, dynamic>.from(courseNode.value as Map);

          usersData.forEach((uid, userData) {
            final userMap = Map<String, dynamic>.from(userData as Map);
            if (userMap.containsKey('dob')) {
              DateTime dob = DateFormat('dd/MM/yyyy').parse(userMap['dob']);
              DateTime nextBirthday = DateTime(today.year, dob.month, dob.day);

              // Adjust logic to include today’s birthday and those within 30 days
              if (nextBirthday.isBefore(today)) {
                nextBirthday = DateTime(today.year + 1, dob.month, dob.day);
              }

              if (nextBirthday.difference(today).inDays <= 30) {
                birthdays.add({
                  'name': userMap['name'],
                  'dob': userMap['dob'],
                  'designation': userMap['designation'],
                  'address': userMap['address'],
                  'city': userMap['city'],
                  'course': userMap['course'],
                  'email': userMap['email'],
                  'organization': userMap['organization'],
                  'phone': userMap['phone'],
                  'imageUrl': userMap['imageUrl'],
                  'blurHash': userMap['blurHash'],
                  'year': userMap['year'],
                  'nextBirthday': nextBirthday,
                });
              }
            }
          });
        }

        // Sort the birthdays by the upcoming date
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
