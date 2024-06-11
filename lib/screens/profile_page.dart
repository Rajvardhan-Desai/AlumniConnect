import 'package:alumniconnect/screens/edit_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? userImageUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ProfilePage({
    super.key,
    required this.userName,
    required this.userEmail,
    this.userImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ProfileImageWithLoading(userImageUrl: userImageUrl),
            const SizedBox(height: 10),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              userEmail,
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            ProfileOption(
              icon: Icons.edit,
              text: 'Edit Profile',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EditProfileScreen()),
                );
              },
            ),
            const Divider(),
            ProfileOption(
              icon: Icons.support,
              text: 'Support',
              onTap: () {
                // Implement support navigation or function
              },
            ),
            ProfileOption(
              icon: Icons.article,
              text: 'Terms of Service',
              onTap: () {
                // Implement terms of service navigation or function
              },
            ),
            ProfileOption(
              icon: Icons.group_add,
              text: 'Invite Friends',
              onTap: () {
                // Implement invite friends function
              },
            ),
            ProfileOption(
              icon: Icons.logout,
              text: 'Sign Out',
              onTap: () {
                _confirmSignOut(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _signOut(context);
              },
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

  void _signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      Navigator.pushNamedAndRemoveUntil(
          context, 'SignInScreen', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error signing out. Please try again.'),
        ),
      );
    }
  }
}

class ProfileImageWithLoading extends StatefulWidget {
  final String? userImageUrl;

  const ProfileImageWithLoading({Key? key, this.userImageUrl}) : super(key: key);

  @override
  _ProfileImageWithLoadingState createState() => _ProfileImageWithLoadingState();
}

class _ProfileImageWithLoadingState extends State<ProfileImageWithLoading> {
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey[300],
          backgroundImage: widget.userImageUrl != null
              ? NetworkImage(widget.userImageUrl!)
              : null,
          child: widget.userImageUrl == null
              ? const Icon(
            Icons.person,
            size: 60,
            color: Colors.white,
          )
              : null,
          onBackgroundImageError: (_, __) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
        if (_isLoading && widget.userImageUrl != null)
          const CircularProgressIndicator(),
      ],
    );
  }

  @override
  void didUpdateWidget(covariant ProfileImageWithLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userImageUrl != oldWidget.userImageUrl) {
      setState(() {
        _isLoading = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.userImageUrl != null) {
      final image = NetworkImage(widget.userImageUrl!);
      image.resolve(const ImageConfiguration()).addListener(
        ImageStreamListener(
              (_, __) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onError: (_, __) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      );
    } else {
      _isLoading = false;
    }
  }
}

class ProfileOption extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const ProfileOption({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(text),
        onTap: onTap,
      ),
    );
  }
}
