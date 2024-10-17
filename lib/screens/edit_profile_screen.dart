import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:alumniconnect/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:blurhash_dart/blurhash_dart.dart' as blurhash_dart;
import 'package:image/image.dart' as img;
import 'package:alumniconnect/Widgets/snack_bar.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alumniconnect/providers/user_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _organizationController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _linkedInController = TextEditingController();
  File? _image;
  bool _isLoading = false;
  bool _isChanged = false;
  bool _isButtonLoading = false;
  String? _selectedYear;
  String? _selectedCourse;
  String? _existingImageUrl;
  String? _blurHash;

  final List<String> _courses = [
    'Civil & Rural Engineering',
    'Information Technology',
    'Computer Engineering',
    'Electronics & Tele-communication Engineering',
    'Electrical Engineering',
    'Mechanical Engineering',
  ];

  Map<String, dynamic> _initialValues = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
    });
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _organizationController.dispose();
    _designationController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _linkedInController.dispose();
  }

  Future<void> _loadUserProfile() async {
    // Fetch user data from the provider
    final userState = ref.read(userProvider);
    _populateUserProfile(userState);
  }

  void _populateUserProfile(UserState userState) {
    _removeListeners(); // Remove listeners to prevent unnecessary _checkForChanges calls during initialization.

    _nameController.text = userState.name;
    _emailController.text = userState.email;
    _phoneController.text = userState.phone ?? '';
    _dobController.text = userState.dob ?? '';
    _organizationController.text = userState.organization ?? '';
    _designationController.text = userState.designation ?? '';
    _cityController.text = userState.city ?? '';
    _addressController.text = userState.address ?? '';
    _linkedInController.text = userState.linkedin ?? '';
    _selectedYear = userState.year;
    _selectedCourse = userState.course;
    _existingImageUrl = userState.imageUrl;
    _blurHash = userState.blurHash;

    _initialValues = {
      'name': _nameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'dob': _dobController.text,
      'organization': _organizationController.text,
      'designation': _designationController.text,
      'city': _cityController.text,
      'address': _addressController.text,
      'linkedin':_linkedInController.text,
      'year': _selectedYear,
      'course': _selectedCourse,
      'imageUrl': _existingImageUrl,
      'blurHash': _blurHash,
    };

    _addListeners(); // Add listeners back after initialization.
  }

  void _removeListeners() {
    _nameController.removeListener(_debouncedCheckForChanges);
    _emailController.removeListener(_debouncedCheckForChanges);
    _phoneController.removeListener(_debouncedCheckForChanges);
    _dobController.removeListener(_debouncedCheckForChanges);
    _organizationController.removeListener(_debouncedCheckForChanges);
    _designationController.removeListener(_debouncedCheckForChanges);
    _cityController.removeListener(_debouncedCheckForChanges);
    _addressController.removeListener(_debouncedCheckForChanges);
    _linkedInController.removeListener(_debouncedCheckForChanges);
  }

  void _addListeners() {
    _nameController.addListener(_checkForRelevantChanges);
    _emailController.addListener(_checkForRelevantChanges);
    _phoneController.addListener(_checkForRelevantChanges);
    _dobController.addListener(_checkForRelevantChanges);
    _organizationController.addListener(_checkForRelevantChanges);
    _designationController.addListener(_checkForRelevantChanges);
    _cityController.addListener(_checkForRelevantChanges);
    _addressController.addListener(_checkForRelevantChanges);
    _linkedInController.addListener(_checkForRelevantChanges);
  }

  void _checkForRelevantChanges() {
    if (_isRelevantChange()) {
      _checkForChanges();
    }
  }

  bool _isRelevantChange() {
    return _nameController.text != _initialValues['name'] ||
        _emailController.text != _initialValues['email'] ||
        _phoneController.text != _initialValues['phone'] ||
        _dobController.text != _initialValues['dob'] ||
        _organizationController.text != _initialValues['organization'] ||
        _designationController.text != _initialValues['designation'] ||
        _cityController.text != _initialValues['city'] ||
        _addressController.text != _initialValues['address'] ||
        _linkedInController.text != _initialValues['linkedin'] ||
        _selectedYear != _initialValues['year'] ||
        _selectedCourse != _initialValues['course'] ||
        _image != null ||
        (_existingImageUrl == null && _initialValues['imageUrl'] != null) ||
        (_existingImageUrl != null && _initialValues['imageUrl'] == null) ||
        (_existingImageUrl != null &&
            _existingImageUrl != _initialValues['imageUrl']);
  }

  List<String> _generateYears() {
    return List<String>.generate(
      DateTime.now().year - 1956,
      (index) => (DateTime.now().year - index).toString(),
    );
  }

  void _debouncedCheckForChanges() {
    Future.delayed(const Duration(milliseconds: 300), _checkForChanges);
  }

  void _checkForChanges() {
    final hasChanges = _isRelevantChange();

    if (hasChanges != _isChanged) {
      setState(() {
        _isChanged = hasChanges;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime now = DateTime.now();
    DateTime eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);

    DateTime initialDate = DateTime.now();
    if (_dobController.text.isNotEmpty) {
      initialDate = DateFormat('dd/MM/yyyy').parse(_dobController.text);
    }

    DateTime? selectedDate = await showDatePicker(
      fieldLabelText: "Enter Date (DD/MM/YYYY)",
      context: context,
      firstDate: DateTime(1924),
      lastDate: eighteenYearsAgo,
      initialEntryMode: DatePickerEntryMode.input,
      initialDate: initialDate,
      locale: const Locale(
          'en', 'GB'), // Set locale to 'en_GB' for dd/MM/yyyy format
    );

    if (selectedDate != null) {
      String formattedDate = DateFormat('dd/MM/yyyy').format(selectedDate);
      setState(() {
        _dobController.text = formattedDate;
        _checkForChanges();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);

    return WillPopScope(
      onWillPop: () async {
        // Disable back button if loading is in progress
        return !_isButtonLoading;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xff986ae7),
          iconTheme: const IconThemeData(
              color: Colors.white), // Set the back arrow color to white
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AbsorbPointer(
                    absorbing: _isButtonLoading || _isLoading,
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          children: <Widget>[
                            ProfileImage(
                              image: _image,
                              existingImageUrl: userState.imageUrl,
                              blurHash: userState.blurHash,
                              pickImage: _pickImage,
                              removeImage: _removeImage,
                              showImageSourceActionSheet:
                                  _showImageSourceActionSheet,
                            ),
                            const SizedBox(height: 20.0),
                            CustomTextFormField(
                              controller: _nameController,
                              labelText: 'Full Name',
                              validator: _requiredValidator,
                            ),
                            const SizedBox(height: 16.0),
                            CustomTextFormField(
                              controller: _emailController,
                              labelText: 'Email',
                              keyboardType: TextInputType.emailAddress,
                              validator: _emailValidator,
                            ),
                            const SizedBox(height: 16.0),
                            CustomTextFormField(
                              controller: _phoneController,
                              labelText: 'Phone Number',
                              keyboardType: TextInputType.phone,
                              validator: _phoneValidator,
                            ),
                            const SizedBox(height: 16.0),
                            CustomTextFormField(
                              controller: _dobController,
                              labelText: 'Date of Birth',
                              keyboardType: TextInputType.datetime,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d{1,2}/\d{1,2}/\d{4}$')),
                              ],
                              validator: _dateValidator,
                              readOnly: true,
                              onTap: () {
                                FocusScope.of(context)
                                    .requestFocus(FocusNode());
                                _selectDate(context);
                              },
                            ),
                            const SizedBox(height: 16.0),
                            CustomTextFormField(
                              controller: _organizationController,
                              labelText: 'Organization',
                              validator: _requiredValidator,
                            ),
                            const SizedBox(height: 16.0),
                            CustomTextFormField(
                              controller: _designationController,
                              labelText: 'Designation',
                              validator: _requiredValidator,
                            ),
                            const SizedBox(height: 16.0),
                            CustomTextFormField(
                              controller: _cityController,
                              labelText: 'City',
                              validator: _requiredValidator,
                            ),
                            const SizedBox(height: 16.0),
                            CustomTextFormField(
                              controller: _addressController,
                              labelText: 'Address',
                              validator: _requiredValidator,
                            ),
                            const SizedBox(height: 16.0),
                            CustomTextFormField(
                              controller: _linkedInController,
                              labelText: 'LinkedIn Profile (optional)',
                              validator: (value) {
                                final linkedInRegex = RegExp(r'^https:\/\/(www\.)?linkedin\.com\/in\/[a-zA-Z0-9-]{5,30}\/?$');
                                if (value == null || !linkedInRegex.hasMatch(value.trim())) {
                                  return 'Please enter a valid LinkedIn Profile Link';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16.0),
                            CustomDropdownFormField(
                              labelText: 'Graduation Year',
                              value: _selectedYear ?? userState.year,
                              items: _generateYears(),
                              validator: _requiredValidator,
                              onChanged: (value) {
                                setState(() {
                                  _selectedYear = value;
                                });
                                _checkForChanges();
                              },
                            ),
                            const SizedBox(height: 16.0),
                            CustomDropdownFormField(
                              labelText: 'Course',
                              value: _selectedCourse ?? userState.course,
                              items: _courses,
                              validator: _requiredValidator,
                              onChanged: (value) {
                                setState(() {
                                  _selectedCourse = value;
                                });
                                _checkForChanges();
                              },
                            ),
                            const SizedBox(height: 30.0),
                            _isButtonLoading
                                ? const CircularProgressIndicator()
                                : ElevatedButton(
                                    onPressed: _isButtonLoading || !_isChanged
                                        ? null
                                        : () => _updateProfile(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      shape:RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10.0),
                                      ),
                                      minimumSize: const Size(double.infinity, 50),
                                    ),
                                    child: const Text(
                                      'Update Profile',
                                      style: TextStyle(
                                        fontSize: 18.0,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                            const SizedBox(height: 30.0)
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    final phoneRegex = RegExp(r'^\+?\d{10,15}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? _dateValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your date of birth';
    }
    final dateRegex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!dateRegex.hasMatch(value)) {
      return 'Please enter a valid date (dd/MM/yyyy)';
    }
    return null;
  }

  Future<void> _updateProfile() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (_formKey.currentState!.validate() && _isChanged) {
      setState(() {
        _isButtonLoading = true;
      });
      try {
        final FirebaseAuth auth = FirebaseAuth.instance;
        final User? user = auth.currentUser;

        if (user != null) {
          String? imageUrl = _existingImageUrl;
          String? blurHash = _blurHash;
          if (_image != null) {
            if (_existingImageUrl != null) {
              // Clear the cached image before uploading the new one
              await CachedNetworkImage.evictFromCache(imageUrl!);
              await CachedNetworkImage.evictFromCache('$imageUrl?t=1');
            }

            imageUrl = await _uploadImage(user.uid);
            imageUrl = imageUrl?.replaceAll('.${imageUrl.split('.').last}',
                '_200x200.${imageUrl.split('.').last}');
            blurHash = await _generateBlurHash(_image!);
          }

          // Update user email in Firebase Authentication
          if (_emailController.text.trim() != user.email) {
            await user.verifyBeforeUpdateEmail(_emailController.text.trim());
          }

          await _updateUserProfile(user.uid, imageUrl, blurHash);

          if (mounted) {
            showSnackBar(scaffoldMessenger, "Profile updated successfully!",
                Colors.green);
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (Route<dynamic> route) => false,
            );
          }
        } else {
          if (mounted) {
            showSnackBar(
                scaffoldMessenger, "User not authenticated.", Colors.red);
          }
        }
      } catch (e) {
        if (mounted) {
          showSnackBar(scaffoldMessenger, "An error occurred: ${e.toString()}",
              Colors.red);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isButtonLoading = false;
          });
        }
      }
    }
  }

  Future<String?> _uploadImage(String uid) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_images')
        .child('$uid.${_image!.path.split('.').last}');
    await storageRef.putFile(_image!);
    return await storageRef.getDownloadURL();
  }

  Future<String> _generateBlurHash(File image) async {
    final imageBytes = await image.readAsBytes();
    final decodedImage = img.decodeImage(imageBytes);
    return blurhash_dart.BlurHash.encode(decodedImage!,
            numCompX: 4, numCompY: 4)
        .hash;
  }

  Future<void> _updateUserProfile(
      String uid, String? imageUrl, String? blurHash) async {
    if (_selectedCourse == null) {
      throw Exception("User's course is not selected.");
    }

    // Check if the course has changed
    if (_selectedCourse != _initialValues['course']) {
      final oldCourse = _initialValues['course'];
      final newCourse = _selectedCourse;

      DatabaseReference oldCourseRef =
          FirebaseDatabase.instance.ref('alumni/$oldCourse/$uid');
      DatabaseReference newCourseRef =
          FirebaseDatabase.instance.ref('alumni/$newCourse/$uid');

      // Move data to new course node
      final snapshot = await oldCourseRef.get();
      if (snapshot.exists) {
        await newCourseRef.set(snapshot.value); // Copy data to new node
        await oldCourseRef.remove(); // Delete old node
      }
    }

    // Update user profile data
    DatabaseReference dbRef =
        FirebaseDatabase.instance.ref('alumni/$_selectedCourse/$uid');
    await dbRef.update({
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'dob': _dobController.text.trim(),
      'organization': _organizationController.text.trim(),
      'designation': _designationController.text.trim(),
      'city': _cityController.text.trim(),
      'address': _addressController.text.trim(),
      'linkedin':_linkedInController.text.trim(),
      'year': _selectedYear,
      'course': _selectedCourse,
      'imageUrl': imageUrl,
      'blurHash': blurHash,
    });

    // Update filters node
    await _updateFilters(uid);

    // Update initial values to reflect the latest data after update
    _initialValues['course'] = _selectedCourse;
  }

  Future<void> _updateFilters(String uid) async {
    DatabaseReference citiesRef =
        FirebaseDatabase.instance.ref('filters/cities/$uid');
    DatabaseReference designationsRef =
        FirebaseDatabase.instance.ref('filters/designations/$uid');

    await citiesRef.set(_cityController.text.trim());
    await designationsRef.set(_designationController.text.trim());
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profile photo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (_image != null || _existingImageUrl != null)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.grey),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _removeImage();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildImageOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.of(context).pop();
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _buildImageOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.of(context).pop();
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: const Color(0xffad7bff)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final fileSize = await file.length();

        // 2MB in bytes
        const int maxFileSize = 2 * 1024 * 1024;

        if (fileSize <= maxFileSize) {
          setState(() {
            _image = file;
          });
          _checkForChanges();
        } else {
          if (mounted) {
            showSnackBar(scaffoldMessenger,
                "Image size should be less than 2MB.", Colors.red);
          }
        }
      } else {
        if (mounted) {
          showSnackBar(scaffoldMessenger, "No image selected.", Colors.red);
        }
      }
    } catch (e) {
      showSnackBar(
          scaffoldMessenger, "An error occurred: ${e.toString()}", Colors.red);
    }
  }

  Future<void> _removeImage() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() {
      _isLoading = true;
    });
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? user = auth.currentUser;

      if (user != null && _existingImageUrl != null) {
        final storageRef =
            FirebaseStorage.instance.refFromURL(_existingImageUrl!);
        await storageRef.delete();

        // Clear the image from cache
        await CachedNetworkImage.evictFromCache(_existingImageUrl!);
        await CachedNetworkImage.evictFromCache(
            '${_existingImageUrl!}?t=1'); // Ensure complete cache clear

        setState(() {
          _existingImageUrl = null;
        });
      }
      setState(() {
        _image = null;
      });
      _checkForChanges();
    } catch (e) {
      if (mounted) {
        showSnackBar(
            scaffoldMessenger,
            "An error occurred while removing the image: ${e.toString()}",
            Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class ProfileImage extends StatelessWidget {
  final File? image;
  final String? existingImageUrl;
  final String? blurHash;
  final Function(ImageSource) pickImage;
  final VoidCallback removeImage;
  final VoidCallback showImageSourceActionSheet;

  const ProfileImage({
    super.key,
    required this.image,
    required this.existingImageUrl,
    required this.blurHash,
    required this.pickImage,
    required this.removeImage,
    required this.showImageSourceActionSheet,
  });

  @override
  Widget build(BuildContext context) {
    String? imageUrl = existingImageUrl;
    return Stack(
      children: [
        Container(
          margin:
              const EdgeInsets.all(8.0), // Add margin around the CircleAvatar
          child: CircleAvatar(
            key: ValueKey(imageUrl), // Use a unique key to force rebuild
            radius: 60,
            backgroundColor: Colors.grey.shade300,
            child: ClipOval(
              child: image != null
                  ? Image.file(
                      image!,
                      fit: BoxFit.cover,
                      width: 120,
                      height: 120,
                    )
                  : (imageUrl != null
                      ? Stack(
                          children: [
                            BlurHash(
                              hash: blurHash ?? 'LKO2?U%2Tw=w]~RBVZRi};RPxuwH',
                              imageFit: BoxFit.cover,
                              decodingWidth: 200,
                              decodingHeight: 200,
                            ),
                            CachedNetworkImage(
                              key: ValueKey(
                                  imageUrl), // Ensure cache-busting by using a unique key
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              width: 200,
                              height: 200,
                              placeholder: (context, url) => BlurHash(
                                hash:
                                    blurHash ?? 'LKO2?U%2Tw=w]~RBVZRi};RPxuwH',
                              ),
                              errorWidget: (context, url, error) => BlurHash(
                                hash:
                                    blurHash ?? 'LKO2?U%2Tw=w]~RBVZRi};RPxuwH',
                              ),
                            ),
                          ],
                        )
                      : const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey,
                        )),
            ),
          ),
        ),
        Positioned(
          bottom: -5,
          right: -5,
          child: Container(
            margin: const EdgeInsets.only(right: 5.0, bottom: 5.0),
            decoration: const BoxDecoration(
              color: Color(0xffc1a8ff),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              onPressed: showImageSourceActionSheet,
            ),
          ),
        ),
      ],
    );
  }
}

class CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?) validator;
  final bool readOnly;
  final VoidCallback? onTap;

  const CustomTextFormField({
    super.key,
    required this.controller,
    required this.labelText,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    required this.validator,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      readOnly: readOnly,
      onTap: onTap,
    );
  }
}

class CustomDropdownFormField extends StatelessWidget {
  final String labelText;
  final String? value;
  final List<String> items;
  final String? Function(String?) validator;
  final void Function(String?) onChanged;

  const CustomDropdownFormField({
    super.key,
    required this.labelText,
    required this.value,
    required this.items,
    required this.validator,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      isExpanded: true,
    );
  }
}
