import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewProfilePage extends StatelessWidget {
  final Map<dynamic, dynamic> userProfile;

  const ViewProfilePage({super.key, required this.userProfile});

  Future<void> _launchEmail(String email, BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri).catchError((error) {
        _handleError(context, 'Could not launch email app. Please check your email settings.');
      });
    } else {
      _handleError(context, 'No email app found. Please install an email app.');
    }
  }

  Future<void> _launchDialer(String phoneNumber, BuildContext context) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri).catchError((error) {
        _handleError(context, 'Could not launch dialer. Please check your phone settings.');
      });
    } else {
      _handleError(context, 'No dialer app found. Please install a phone app.');
    }
  }

  void _handleError(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  }

  Widget _buildProfileTile(BuildContext context, IconData icon, String title, String? subtitle, {void Function()? onTap}) {
    if (subtitle == null || subtitle.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        ListTile(
          leading: Icon(icon),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 18),
          ),
          onTap: onTap,
        ),
        const Divider(thickness: 0.5),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uid = userProfile['uid'] ?? 'unknown';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xff986ae7),
        iconTheme: const IconThemeData(color: Colors.white), // Set the back arrow color to white
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Hero(
                  tag: 'profileImage-$uid',
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: userProfile['imageUrl'] != null ? NetworkImage(userProfile['imageUrl']) : null,
                    child: userProfile['imageUrl'] == null ? const Icon(Icons.person_outline, size: 60) : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Hero(
                tag: 'profileName-$uid',
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(userProfile['name'] ?? 'No Name', style: const TextStyle(fontSize: 18)),
                  ),
                ),
              ),
              const Divider(thickness: 0.5),
              Hero(
                tag: 'profileEmail-$uid',
                child: Material(
                  color: Colors.transparent,
                  child: _buildProfileTile(
                    context,
                    Icons.email_outlined,
                    'Email',
                    userProfile['email'],
                    onTap: () async {
                      await _launchEmail(userProfile['email'] ?? '', context);
                    },
                  ),
                ),
              ),
              _buildProfileTile(context, Icons.cake_outlined, 'Date of Birth', userProfile['dob']),
              _buildProfileTile(
                context,
                Icons.phone_outlined,
                'Phone',
                userProfile['phone'],
                onTap: () async {
                  await _launchDialer(userProfile['phone'] ?? '', context);
                },
              ),
              _buildProfileTile(context, Icons.location_city_outlined, 'City', userProfile['city']),
              _buildProfileTile(context, Icons.home_outlined, 'Address', userProfile['address']),
              _buildProfileTile(context, Icons.business_center_outlined, 'Designation', userProfile['designation']),
              _buildProfileTile(context, Icons.business_outlined, 'Organization', userProfile['organization']),
              _buildProfileTile(context, Icons.school_outlined, 'Course', userProfile['course']),
              _buildProfileTile(context, Icons.calendar_today_outlined, 'Graduation Year', userProfile['year']),
            ],
          ),
        ),
      ),
    );
  }
}
