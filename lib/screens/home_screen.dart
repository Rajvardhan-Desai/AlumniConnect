import 'package:alumniconnect/screens/profile_page.dart';
import 'package:alumniconnect/screens/search_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  String _currentUserName = '';
  String _currentUserEmail = '';
  String _currentUserCourse = '';
  String _currentUserYear = '';
  String? _currentUserImageUrl;
  String? _currentUserBlurHash;
  int _selectedIndex = 0;
  bool _isLoadingUserData = false;
  bool _isLoadingBirthdays = false;

  List<Map<String, dynamic>> _upcomingBirthdays = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _auth.authStateChanges().listen((user) {
        if (user == null) {
          Navigator.pushNamedAndRemoveUntil(
              context, 'SignInScreen', (route) => false);
        } else {
          _fetchUserData(user.uid);
          _fetchUpcomingBirthdays();
        }
      });
    });
  }

  Future<void> _fetchUserData(String userId) async {
    setState(() {
      _isLoadingUserData = true;
    });
    try {
      final snapshot = await _database.child('alumni').child(userId).get();
      if (snapshot.exists) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          _currentUserName = userData['name'] ?? 'User';
          _currentUserEmail = userData['email'] ?? 'No email';
          _currentUserImageUrl = userData['imageUrl'];
          _currentUserBlurHash = userData['blurHash'];
          _currentUserCourse = userData['course'] ?? 'Unknown course';
          _currentUserYear = userData['year'] ?? 'Unknown year';
        });
      } else {
        _showErrorSnackbar('User data not found');
      }
    } catch (error) {
      _showErrorSnackbar('Error fetching user data: ${error.toString()}');
    } finally {
      setState(() {
        _isLoadingUserData = false;
      });
    }
  }

  Future<void> _fetchUpcomingBirthdays() async {
    setState(() {
      _isLoadingBirthdays = true;
    });
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
                'imageUrl': userData['imageUrl'],
                'blurHash': userData['blurHash'],
                'nextBirthday': nextBirthday,
              });
            }
          }
        });

        birthdays.sort((a, b) => a['nextBirthday'].compareTo(b['nextBirthday']));

        setState(() {
          _upcomingBirthdays = birthdays;
        });
      } else {
        _showErrorSnackbar('No alumni data found');
      }
    } catch (error) {
      _showErrorSnackbar(
          'Error fetching upcoming birthdays: ${error.toString()}');
    } finally {
      setState(() {
        _isLoadingBirthdays = false;
      });
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = [
      _isLoadingUserData || _isLoadingBirthdays
          ? const Center(child: CircularProgressIndicator())
          : _buildHomeContent(),
      SearchPage(
          currentCourse: _currentUserCourse, currentYear: _currentUserYear),
      ProfilePage(
        userName: _currentUserName,
        userEmail: _currentUserEmail,
        userImageUrl: _currentUserImageUrl,
        blurHash: _currentUserBlurHash,
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          'AlumniConnect',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 22.0,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xff986ae7),
        automaticallyImplyLeading: false,
      ),
      body: widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: _buildNavigationBar(),
    );
  }

  Widget _buildNavigationBar() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onItemTapped,
      destinations: const <NavigationDestination>[
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: Color(0xff986ae7)),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.search_outlined),
          selectedIcon: Icon(Icons.search, color: Color(0xff986ae7)),
          label: 'Search',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: Color(0xff986ae7)),
          label: 'Profile',
        ),
      ],
      backgroundColor: Colors.white,
      elevation: 5.0,
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, $_currentUserName!',
            style: const TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          UserInfoCard(
            userName: _currentUserName,
            userEmail: _currentUserEmail,
            userCourse: _currentUserCourse,
            userYear: _currentUserYear,
            imageUrl: _currentUserImageUrl,
            blurHash: _currentUserBlurHash,
          ),
          const SizedBox(height: 20),
          UpcomingBirthdaysSection(upcomingBirthdays: _upcomingBirthdays),
        ],
      ),
    );
  }
}

class UserInfoCard extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String userCourse;
  final String userYear;
  final String? imageUrl;
  final String? blurHash;

  const UserInfoCard({
    Key? key,
    required this.userName,
    required this.userEmail,
    required this.userCourse,
    required this.userYear,
    this.imageUrl,
    this.blurHash,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            UserAvatar(imageUrl: imageUrl, blurHash: blurHash),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    userEmail,
                    style: const TextStyle(
                      fontSize: 16.0,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    userCourse,
                    style: const TextStyle(
                      fontSize: 16.0,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    userYear,
                    style: const TextStyle(
                      fontSize: 16.0,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? blurHash;

  const UserAvatar({
    Key? key,
    this.imageUrl,
    this.blurHash,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      key: UniqueKey(),
      radius: 30,
      backgroundColor: Colors.grey.shade300,
      child: ClipOval(
        child: imageUrl != null
            ? Stack(
          children: [
            if (blurHash != null)
              BlurHash(
                hash: blurHash ?? 'LKO2?U%2Tw=w]~RBVZRi};RPxuwH',
                imageFit: BoxFit.cover,
                decodingWidth: 60,
                decodingHeight: 60,
              ),
            Image.network(
              '$imageUrl?${DateTime.now().millisecondsSinceEpoch}',
              fit: BoxFit.cover,
              width: 60,
              height: 60,
              errorBuilder: (context, error, stackTrace) {
                return blurHash != null
                    ? BlurHash(
                  hash: blurHash ?? 'LKO2?U%2Tw=w]~RBVZRi};RPxuwH',
                )
                    : const Icon(
                  Icons.person,
                  color: Colors.grey,
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                } else {
                  return blurHash != null
                      ? BlurHash(
                    hash: blurHash ?? 'LKO2?U%2Tw=w]~RBVZRi};RPxuwH',
                  )
                      : const CircularProgressIndicator();
                }
              },
            ),
          ],
        )
            : const Icon(
          Icons.person,
          color: Colors.grey,
        ),
      ),
    );
  }
}


class UpcomingBirthdaysSection extends StatelessWidget {
  final List<Map<String, dynamic>> upcomingBirthdays;

  const UpcomingBirthdaysSection({Key? key, required this.upcomingBirthdays})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Birthdays',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
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
    Key? key,
    required this.name,
    required this.birthday,
    this.imageUrl,
    this.blurHash,
  }) : super(key: key);

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
