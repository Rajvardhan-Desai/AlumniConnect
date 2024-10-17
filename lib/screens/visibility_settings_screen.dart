import 'package:alumniconnect/Widgets/snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/user_provider.dart';

class VisibilitySettingsScreen extends ConsumerStatefulWidget {
  const VisibilitySettingsScreen({super.key});

  @override
  VisibilitySettingsScreenState createState() =>
      VisibilitySettingsScreenState();
}

class VisibilitySettingsScreenState
    extends ConsumerState<VisibilitySettingsScreen> {
  bool _isAddressVisible = false;
  bool _isCourseVisible = true;
  bool _isDesignationVisible = true;
  bool _isDobVisible = false;
  bool _isEmailVisible = false;
  bool _isLinkedInVisible = true;
  bool _isOrganizationVisible = false;
  bool _isPhoneVisible = false;
  bool _isYearVisible = true;
  bool _isNameVisible = true;
  bool _isCityVisible = true;

  late final String? course;

  late DatabaseReference _dbRef;
  late String _userId;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser!.uid;
    _dbRef = FirebaseDatabase.instance.ref('alumni');
    _loadVisibilitySettings();
  }

  void _loadVisibilitySettings() {
    final userState = ref.read(userProvider);

    setState(() {
      course = userState.course;
      _isAddressVisible = userState.addressVisibility;
      _isCourseVisible = userState.courseVisibility;
      _isDesignationVisible = userState.designationVisibility;
      _isDobVisible = userState.dobVisibility;
      _isEmailVisible = userState.emailVisibility;
      _isLinkedInVisible = userState.linkedinVisibility;
      _isOrganizationVisible = userState.organizationVisibility;
      _isPhoneVisible = userState.phoneVisibility;
      _isYearVisible = userState.yearVisibility;
      _isNameVisible = userState.nameVisibility;
      _isCityVisible = userState.cityVisibility;
    });
  }

  Future<void> _saveVisibilitySettings() async {
    // Update visibility settings in the provider
    ref.read(userProvider.notifier).updateVisibilitySettings(
          addressVisibility: _isAddressVisible,
          courseVisibility: _isCourseVisible,
          designationVisibility: _isDesignationVisible,
          dobVisibility: _isDobVisible,
          emailVisibility: _isEmailVisible,
          linkedinVisibility : _isLinkedInVisible,
          organizationVisibility: _isOrganizationVisible,
          phoneVisibility: _isPhoneVisible,
          yearVisibility: _isYearVisible,
          nameVisibility: _isNameVisible,
          cityVisibility: _isCityVisible,
        );

    // Update the database
    await _dbRef.child('$course/$_userId').update({
      'visibility': {
        'address': _isAddressVisible,
        'course': _isCourseVisible,
        'designation': _isDesignationVisible,
        'dob': _isDobVisible,
        'email': _isEmailVisible,
        'linkedin': _isLinkedInVisible,
        'organization': _isOrganizationVisible,
        'phone': _isPhoneVisible,
        'year': _isYearVisible,
        'name': _isNameVisible,
        'city': _isCityVisible,
      }
    });

    // Check if the widget is still mounted before using context
    if (!mounted) return;

    _showSnackBar(context, 'Privacy settings updated successfully!', Colors.green);

  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visibility',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xff986ae7),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(

        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Manage what personal information you make visible to others when they see your profile.',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Color(0xff444746),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xffd5c3ff),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Icon(Icons.lock, color: Color(0xff535353)),
                            Text(
                              'Only you',
                              style: TextStyle(
                                  color: Color(0xff535353),
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.people, color: Color(0xff535353)),
                            Text(
                              'Anyone',
                              style: TextStyle(
                                  color: Color(0xff535353),
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: Color(0xff474747)),
                      SizedBox(width: 8),
                      Text(
                          'Name, Designation, City, Year, Course\n (Required)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xff757575))),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      _showSnackBar(context,"This setting can’t be changed for your account",const Color(
                          0xff959595));
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30.0),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 6.0, horizontal: 16.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.0),
                              color: const Color(0xff757575),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              VisibilityToggle(
                title: 'Date of Birth',
                initialValue: _isDobVisible,
                suffixIcon: Icons.cake_outlined,
                onChanged: (value) {
                  setState(() {
                    _isDobVisible = value;
                  });
                },
              ),
              VisibilityToggle(
                title: 'Phone',
                initialValue: _isPhoneVisible,
                suffixIcon: Icons.phone_outlined,
                onChanged: (value) {
                  setState(() {
                    _isPhoneVisible = value;
                  });
                },
              ),
              VisibilityToggle(
                title: 'Email',
                initialValue: _isEmailVisible,
                suffixIcon: Icons.email_outlined,
                onChanged: (value) {
                  setState(() {
                    _isEmailVisible = value;
                  });
                },
              ),
              VisibilityToggle(
                title: 'Organization',
                initialValue: _isOrganizationVisible,
                suffixIcon: Icons.business_outlined,
                onChanged: (value) {
                  setState(() {
                    _isOrganizationVisible = value;
                  });
                },
              ),
              VisibilityToggle(
                title: 'Address',
                initialValue: _isAddressVisible,
                suffixIcon: Icons.home_outlined,
                onChanged: (value) {
                  setState(() {
                    _isAddressVisible = value;
                  });
                },
              ),
              VisibilityToggle(
                title: 'LinkedIn',
                initialValue: _isLinkedInVisible, // Adjust this variable if you have a separate one for LinkedIn
                suffixIcon: FontAwesomeIcons.linkedin, // This uses the LinkedIn icon
                onChanged: (value) {
                  setState(() {
                    _isLinkedInVisible = value; // Adjust this if you have a separate LinkedIn visibility variable
                  });
                },
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveVisibilitySettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffa57eff),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Save Settings',
                  style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context,String msg,Color color) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showSnackBar(scaffoldMessenger, msg, color);
  }
}

class VisibilityToggle extends StatefulWidget {
  final String title;
  final bool initialValue;
  final ValueChanged<bool> onChanged;
  final IconData suffixIcon;

  const VisibilityToggle({
    required this.title,
    required this.initialValue,
    required this.onChanged,
    required this.suffixIcon,
    super.key,
  });

  @override
  VisibilityToggleState createState() => VisibilityToggleState();
}

class VisibilityToggleState extends State<VisibilityToggle> {
  late bool isVisible;

  @override
  void initState() {
    super.initState();
    isVisible = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(widget.suffixIcon, color: const Color(0xff474747)),
              const SizedBox(width: 8),
              Text(widget.title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                isVisible = !isVisible;
                widget.onChanged(isVisible);
              });
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.0),
                border: Border.all(color: Colors.grey),
                color: isVisible ? Colors.white : Colors.blue.shade100,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 6.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: isVisible ? const Color(0xff757575) : Colors.white,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isVisible ? Icons.people : Icons.lock,
                          color: isVisible
                              ? Colors.white
                              : const Color(0xff757575),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
