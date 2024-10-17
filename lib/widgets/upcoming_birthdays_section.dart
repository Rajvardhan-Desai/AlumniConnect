import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../screens/view_profile_page.dart';
import 'user_avatar.dart';

class UpcomingBirthdaysSection extends StatelessWidget {
  final List<Map<String, dynamic>> upcomingBirthdays;

  const UpcomingBirthdaysSection({super.key, required this.upcomingBirthdays});

  @override
  Widget build(BuildContext context) {
    // Limit to the first 5 birthdays
    final limitedBirthdays = upcomingBirthdays.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Row(
          children: [
            Text(
              'Birthdays',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...limitedBirthdays.map((birthday) {
          DateTime dob = DateFormat('dd/MM/yyyy').parse(birthday['dob']);
          DateTime now = DateTime.now();
          DateTime today = DateTime(now.year, now.month, now.day);
          DateTime nextBirthday = DateTime(today.year, dob.month, dob.day);

          if (nextBirthday.isBefore(today)) {
            nextBirthday = DateTime(today.year + 1, dob.month, dob.day);
          }

          int daysLeft = nextBirthday.difference(today).inDays;

          return BirthdayCard(
            name: birthday['name'],
            birthday: dob, // Pass DateTime object instead of string
            daysLeft: daysLeft,
            isToday: daysLeft == 0,
            imageUrl: birthday['imageUrl'],
            blurHash: birthday['blurHash'],
            userProfile: birthday, // Passing the entire user profile
          );
        })
      ],
    );
  }
}

class BirthdayCard extends StatelessWidget {
  final String name;
  final DateTime birthday; // Change to DateTime type
  final int daysLeft;
  final bool isToday;
  final String? imageUrl;
  final String? blurHash;
  final Map<String, dynamic> userProfile;

  const BirthdayCard({
    super.key,
    required this.name,
    required this.birthday,
    required this.daysLeft,
    required this.isToday,
    this.imageUrl,
    this.blurHash,
    required this.userProfile,
  });

  @override
  Widget build(BuildContext context) {
    final String formattedBirthday = DateFormat('MMMM d').format(birthday); // Format the date

    return Card(
      elevation: isToday ? 8 : 4, // Highlight today's birthday with higher elevation
      color: isToday ? Colors.purple[200] : null, // Special color for today's birthday
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: UserAvatar(imageUrl: imageUrl, blurHash: blurHash),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            fontSize: isToday ? 18 : 16,
          ),
        ),
        subtitle: Text(
          isToday
              ? '🎉 Today is the birthday!'
              : 'Birthday: $formattedBirthday\nDays left: $daysLeft',
          style: TextStyle(
            fontSize: isToday ? 14 : 12,
            color: isToday ? Colors.white : Colors.black54,
          ),
        ),
        onTap: () {
          // Navigate to the profile page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewProfilePage(userProfile: userProfile),
            ),
          );
        },
      ),
    );
  }
}
