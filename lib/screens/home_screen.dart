import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:alumniconnect/screens/profile_page.dart';
import 'package:alumniconnect/screens/search_page.dart';
import 'package:alumniconnect/providers/user_provider.dart';
import 'package:alumniconnect/providers/birthday_provider.dart';
import 'package:alumniconnect/widgets/user_info_card.dart';
import 'package:alumniconnect/widgets/upcoming_birthdays_section.dart';


class HomeScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    final userNotifier = ref.read(userProvider.notifier);
    final birthdayNotifier = ref.read(birthdayProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      userNotifier.fetchUserData().catchError((error) {
        _showErrorSnackBar(error.toString());
      });
      birthdayNotifier.fetchUpcomingBirthdays().catchError((error) {
        _showErrorSnackBar(error.toString());
      });
    });
  }

  void _showErrorSnackBar(String message) {
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
    final userState = ref.watch(userProvider);
    final birthdayState = ref.watch(birthdayProvider);

    final List<Widget> widgetOptions = [
      userState.isLoading || birthdayState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildHomeContent(userState, birthdayState),
      SearchPage(
        currentCourse: userState.course,
        currentYear: userState.year,
      ),
      ProfilePage(
        userName: userState.name,
        userEmail: userState.email,
        userImageUrl: userState.imageUrl,
        blurHash: userState.blurHash,
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

  Widget _buildHomeContent(UserState userState, BirthdayState birthdayState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${userState.name}!',
            style: const TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          UserInfoCard(
            userName: userState.name,
            userEmail: userState.email,
            userCourse: userState.course,
            userYear: userState.year,
            imageUrl: userState.imageUrl,
            blurHash: userState.blurHash,
          ),
          const SizedBox(height: 20),
          UpcomingBirthdaysSection(upcomingBirthdays: birthdayState.upcomingBirthdays),
        ],
      ),
    );
  }
}
