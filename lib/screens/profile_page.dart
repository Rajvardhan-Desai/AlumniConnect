import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:alumniconnect/screens/edit_profile_screen.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';

class ProfilePage extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? userImageUrl;
  final String? blurHash;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ProfilePage({
    super.key,
    required this.userName,
    required this.userEmail,
    this.userImageUrl,
    this.blurHash,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ProfileImageWithLoading(
              userImageUrl: userImageUrl,
              blurHash: blurHash,
            ),
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
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EditProfileScreen()),
                );

                if (result == true && userImageUrl != null) {
                  await CachedNetworkImage.evictFromCache(userImageUrl!);
                }
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
                if (context.mounted) {
                  _signOut(context);
                }
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
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, 'SignInScreen', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out. Please try again. $e'),
          ),
        );
      }
    }
  }
}

class ProfileImageWithLoading extends StatelessWidget {
  final String? userImageUrl;
  final String? blurHash;

  const ProfileImageWithLoading({super.key, this.userImageUrl, this.blurHash});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.grey[300],
      child: ClipOval(
        child: userImageUrl != null
            ? Stack(
          children: [
            BlurHash(
              hash: blurHash ?? 'LKO2?U%2Tw=w]~RBVZRi};RPxuwH',
              imageFit: BoxFit.cover,
              decodingWidth: 120,
              decodingHeight: 120,
            ),
            CachedNetworkImage(
              imageUrl: userImageUrl!,
              fit: BoxFit.cover,
              width: 120,
              height: 120,
              placeholder: (context, url) => BlurHash(
                hash: blurHash ?? 'LKO2?U%2Tw=w]~RBVZRi};RPxuwH',
              ),
              errorWidget: (context, url, error) => BlurHash(
                hash: blurHash ?? 'LKO2?U%2Tw=w]~RBVZRi};RPxuwH',
              ),
            ),
          ],
        )
            : const Icon(
          Icons.person,
          size: 60,
          color: Colors.white,
        ),
      ),
    );
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
