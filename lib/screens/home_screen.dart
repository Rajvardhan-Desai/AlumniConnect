import 'package:alumniconnect/screens/profile_page.dart';
import 'package:alumniconnect/screens/search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/birthday_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/upcoming_birthdays_section.dart';
import '../widgets/user_info_card.dart';
import 'gallery_screen.dart';
import 'news_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  late int _selectedIndex;
  List<String>? _cachedImageUrls;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    final userNotifier = ref.read(userProvider.notifier);
    final birthdayNotifier = ref.read(birthdayProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await userNotifier.fetchUserData();
        await birthdayNotifier.fetchUpcomingBirthdays();

        _cachedImageUrls = await _getCachedSlideshowImages();
        if (_cachedImageUrls == null || _cachedImageUrls!.isEmpty) {
          final imageUrls = await _fetchSlideshowImages();
          await _cacheSlideshowImages(imageUrls);
          _cachedImageUrls = imageUrls;
        }

        setState(() {
          _isLoading = false;
        });
      } catch (error) {
        _showErrorSnackBar(error.toString());
      }
    });
  }

  Future<void> _cacheSlideshowImages(List<String> imageUrls) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('gallery_images', imageUrls);
  }

  Future<List<String>?> _getCachedSlideshowImages() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('gallery_images');
  }

  Future<List<String>> _fetchSlideshowImages() async {
    final storageRef = FirebaseStorage.instance.ref('Gallery');
    final ListResult result = await storageRef.listAll();
    List<String> allImages = [];

    for (var prefix in result.prefixes) {
      final ListResult subFolderResult = await prefix.listAll();
      final List<String> urls = await Future.wait(
        subFolderResult.items.map((ref) => ref.getDownloadURL()).toList(),
      );
      allImages.addAll(urls);
    }

    return allImages;
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
      _isLoading
          ? _buildShimmerHomeContent()
          : _buildHomeContent(userState, birthdayState),
      SearchPage(
        currentCourse: userState.course,
        currentYear: userState.year,
      ),
      const NewsPage(),
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
          icon: Icon(Icons.newspaper_outlined),
          selectedIcon: Icon(Icons.newspaper, color: Color(0xff986ae7)),
          label: 'News',
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

  Widget _buildShimmerHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 214,
                  height: 34.0,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  height: 145.0,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  height: 30.0,
                  color: Colors.white,
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 200.0,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                Container(
                  width: 200,
                  height: 30.0,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  height: 70.0,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  height: 70.0,
                  color: Colors.white,
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 200.0,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gallery',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward, color: Color(0xff986ae7)),
                onPressed: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GalleryScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          _cachedImageUrls == null
              ? _buildShimmerSlideshow()
              : _buildImageSlideshow(_cachedImageUrls!),
          if (birthdayState.upcomingBirthdays.isNotEmpty)
            UpcomingBirthdaysSection(
                upcomingBirthdays: birthdayState.upcomingBirthdays),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildShimmerSlideshow() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 200.0,
        color: Colors.white,
      ),
    );
  }

  Widget _buildImageSlideshow(List<String> imageUrls) {
    return CarouselSlider.builder(
      itemCount: imageUrls.length,
      itemBuilder: (context, index, realIdx) {
        return SizedBox(
          height: 300.0,
          child: CachedNetworkImage(
            imageUrl: imageUrls[index],
            placeholder: (context, url) => Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 300.0, // Match the container height
                color: Colors.white,
              ),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
            fit: BoxFit.cover, // Ensures the image covers the entire container
            width: double.infinity,
            height: 300.0,
            // Set the same height for the image
          ),
        );
      },
      options: CarouselOptions(
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.8,
        enlargeFactor: 0.3,
        // Optionally adjust aspect ratio or set it to null
        aspectRatio: 16 / 9,
      ),
    );
  }
}

