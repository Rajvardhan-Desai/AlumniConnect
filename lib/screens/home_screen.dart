import 'package:alumniconnect/screens/profile_page.dart';
import 'package:alumniconnect/screens/search_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

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
  int _selectedIndex = 0;
  bool _isLoading = false;

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
      _isLoading = true;
    });
    try {
      final snapshot = await _database.child('alumni').child(userId).get();
      if (snapshot.exists) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          _currentUserName = userData['name'] ?? 'User';
          _currentUserEmail = userData['email'] ?? 'No email';
          _currentUserImageUrl = userData['imageUrl'];
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
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUpcomingBirthdays() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final snapshot = await _database.child('alumni').get();
      if (snapshot.exists) {
        final Map<String, dynamic> allUsersData = Map<String, dynamic>.from(snapshot.value as Map);

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
      _showErrorSnackbar('Error fetching upcoming birthdays: ${error.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
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
      _isLoading ? _buildShimmerHomeContent() : _buildHomeContent(),
      SearchPage(currentCourse: _currentUserCourse, currentYear: _currentUserYear),
      ProfilePage(userName: _currentUserName, userEmail: _currentUserEmail, userImageUrl: _currentUserImageUrl),
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
          _buildUserInfoCard(),
          // const SizedBox(height: 20),
          // _buildRecentActivitiesSection(),
          const SizedBox(height: 20),
          _buildUpcomingBirthdaysSection(),
        ],
      ),
    );
  }

  Widget _buildShimmerHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: double.infinity,
              height: 24.0,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          _buildShimmerUserInfoCard(),
          // const SizedBox(height: 20),
          // _buildShimmerRecentActivitiesSection(),
          const SizedBox(height: 20),
          _buildShimmerUpcomingBirthdaysSection(),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            _currentUserImageUrl != null
                ? CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(_currentUserImageUrl!),
            )
                : CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey.shade300,
              child: const Icon(Icons.person, size: 30, color: Colors.white),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentUserName,
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _currentUserEmail,
                    style: const TextStyle(
                      fontSize: 16.0,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _currentUserCourse,
                    style: const TextStyle(
                      fontSize: 16.0,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _currentUserYear,
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

  Widget _buildShimmerUserInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      width: double.infinity,
                      height: 20.0,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      width: double.infinity,
                      height: 16.0,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      width: double.infinity,
                      height: 16.0,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      width: double.infinity,
                      height: 16.0,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activities',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        _buildActivityTile(
          icon: Icons.event,
          title: 'Alumni Meetup Event',
          subtitle: 'Join the upcoming alumni meetup event on 25th June.',
        ),
        _buildActivityTile(
          icon: Icons.article,
          title: 'Alumni News',
          subtitle: 'Check out the latest news in the alumni community.',
        ),
      ],
    );
  }

  Widget _buildShimmerRecentActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: double.infinity,
            height: 20.0,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        _buildShimmerActivityTile(),
        _buildShimmerActivityTile(),
      ],
    );
  }

  Widget _buildActivityTile({required IconData icon, required String title, required String subtitle}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xff986ae7)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0, color: Colors.grey),
      onTap: () {
        // Handle activity tile tap
      },
    );
  }

  Widget _buildShimmerActivityTile() {
    return ListTile(
      leading: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: const CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white,
        ),
      ),
      title: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          width: double.infinity,
          height: 16.0,
          color: Colors.white,
        ),
      ),
      subtitle: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          width: double.infinity,
          height: 14.0,
          color: Colors.white,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0, color: Colors.grey),
    );
  }

  Widget _buildUpcomingBirthdaysSection() {
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
        ..._upcomingBirthdays.map((birthday) => _buildBirthdayCard(
            birthday['name'], birthday['dob'], birthday['imageUrl'])),
      ],
    );
  }

  Widget _buildShimmerUpcomingBirthdaysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: double.infinity,
            height: 20.0,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        _buildShimmerBirthdayCard(),
        _buildShimmerBirthdayCard(),
      ],
    );
  }

  Widget _buildBirthdayCard(String name, String birthday, String? imageUrl) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: imageUrl != null
            ? CircleAvatar(
          radius: 30,
          backgroundImage: NetworkImage(imageUrl),
        )
            : CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey.shade300,
          child: const Icon(Icons.person, size: 30, color: Colors.white),
        ),
        title: Text(name),
        subtitle: Text('Birthday: $birthday'),
        onTap: () => (),
      ),
    );
  }

  Widget _buildShimmerBirthdayCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
          ),
        ),
        title: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: double.infinity,
            height: 16.0,
            color: Colors.white,
          ),
        ),
        subtitle: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: double.infinity,
            height: 14.0,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
