import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewProfilePage extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const ViewProfilePage({super.key, required this.userProfile});

  @override
  ViewProfilePageState createState() => ViewProfilePageState();
}

class ViewProfilePageState extends State<ViewProfilePage> {
  Future<void> _launchEmail(String? email) async {
    if (email == null || email.isEmpty) {
      _showError('Email address is not available.');
      return;
    }
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        _showError('No email app found. Please install an email app.');
      }
    } catch (error) {
      _showError('Could not launch email app. Please check your email settings.');
    }
  }

  Future<void> _launchDialer(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      _showError('Phone number is not available.');
      return;
    }
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        _showError('No dialer app found. Please install a phone app.');
      }
    } catch (error) {
      _showError('Could not launch dialer. Please check your phone settings.');
    }
  }

  void _showError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error), duration: const Duration(seconds: 3)),
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
        const Padding(
          padding: EdgeInsets.only(left: 55.0),
          child: Divider(thickness: 0.5),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uid = widget.userProfile['uid'] ?? 'unknown';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xff986ae7),
        iconTheme: const IconThemeData(color: Colors.white),
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
                    backgroundImage: widget.userProfile['imageUrl'] != null ? NetworkImage(widget.userProfile['imageUrl']) : null,
                    child: widget.userProfile['imageUrl'] == null ? const Icon(Icons.person_outline, size: 60) : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(widget.userProfile['name'] ?? 'No Name', style: const TextStyle(fontSize: 18)),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 55.0),
                child: Divider(thickness: 0.5),
              ),
              _buildProfileTile(
                context,
                Icons.email_outlined,
                'Email',
                widget.userProfile['email'],
                onTap: () {
                  final email = widget.userProfile['email'];
                  if (email != null && email.isNotEmpty) {
                    _launchEmail(email);
                  } else {
                    _showError('Email address is not available.');
                  }
                },
              ),
              _buildProfileTile(context, Icons.cake_outlined, 'Date of Birth', widget.userProfile['dob']),
              _buildProfileTile(
                context,
                Icons.phone_outlined,
                'Phone',
                widget.userProfile['phone'],
                onTap: () {
                  final phone = widget.userProfile['phone'];
                  if (phone != null && phone.isNotEmpty) {
                    _launchDialer(phone);
                  } else {
                    _showError('Phone number is not available.');
                  }
                },
              ),
              _buildProfileTile(context, Icons.location_city_outlined, 'City', widget.userProfile['city']),
              _buildProfileTile(context, Icons.home_outlined, 'Address', widget.userProfile['address']),
              _buildProfileTile(context, Icons.business_center_outlined, 'Designation', widget.userProfile['designation']),
              _buildProfileTile(context, Icons.business_outlined, 'Organization', widget.userProfile['organization']),
              _buildProfileTile(context, Icons.school_outlined, 'Course', widget.userProfile['course']),
              _buildProfileTile(context, Icons.calendar_today_outlined, 'Graduation Year', widget.userProfile['year']),
            ],
          ),
        ),
      ),
    );
  }
}
