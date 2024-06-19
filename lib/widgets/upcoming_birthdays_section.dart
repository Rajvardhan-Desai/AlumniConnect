import 'package:flutter/material.dart';
import 'user_avatar.dart';

class UpcomingBirthdaysSection extends StatelessWidget {
  final List<Map<String, dynamic>> upcomingBirthdays;

  const UpcomingBirthdaysSection({super.key, required this.upcomingBirthdays});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.cake, color: Color(0xff986ae7)),
            SizedBox(width: 8),
            Text(
              'Upcoming Birthdays',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...upcomingBirthdays.map((birthday) => BirthdayCard(
            name: birthday['name'],
            birthday: birthday['dob'],
            imageUrl: birthday['imageUrl'],
            blurHash: birthday['blurHash'])),
      ],
    );
  }
}

class BirthdayCard extends StatelessWidget {
  final String name;
  final String birthday;
  final String? imageUrl;
  final String? blurHash;

  const BirthdayCard({
    super.key,
    required this.name,
    required this.birthday,
    this.imageUrl,
    this.blurHash,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: UserAvatar(imageUrl: imageUrl, blurHash: blurHash),
        title: Text(name),
        subtitle: Text('Birthday: $birthday'),
        onTap: () => {},
      ),
    );
  }
}
