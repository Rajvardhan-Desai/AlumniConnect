import 'dart:io';
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
import 'package:alumniconnect/util.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _organizationController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  File? _image;
  bool _isLoading = false;
  bool _isChanged = false;
  bool _isButtonLoading = false;
  String? _selectedYear;
  String? _selectedCourse;
  String? _existingImageUrl;
  String? _blurHash;

  late Map<String, dynamic> _initialValues;
  bool _initialValuesSet = false;

  @override
  void initState() {
    super.initState();
    _selectedYear = _generateYears().first;
    _selectedCourse = 'Information Technology'; // default course
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
  }

  void _addListeners() {
    _nameController.addListener(_debouncedCheckForChanges);
    _emailController.addListener(_debouncedCheckForChanges);
    _phoneController.addListener(_debouncedCheckForChanges);
    _dobController.addListener(_debouncedCheckForChanges);
    _organizationController.addListener(_debouncedCheckForChanges);
    _designationController.addListener(_debouncedCheckForChanges);
    _cityController.addListener(_debouncedCheckForChanges);
    _addressController.addListener(_debouncedCheckForChanges);
  }

  Future<void> _loadUserProfile() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() {
      _isLoading = true;
    });
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? user = auth.currentUser;

      if (user != null) {
        DatabaseReference dbRef =
        FirebaseDatabase.instance.ref('alumni/${user.uid}');
        final snapshot = await dbRef.get();

        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          _populateUserProfile(data);
          _storeInitialValues(data);
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
          _isLoading = false;
        });
      }
    }
  }

  void _populateUserProfile(Map<dynamic, dynamic> data) {
    _nameController.text = data['name'] ?? '';
    _emailController.text = data['email'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    _dobController.text = data['dob'] ?? '';
    _organizationController.text = data['organization'] ?? '';
    _designationController.text = data['designation'] ?? '';
    _cityController.text = data['city'] ?? '';
    _addressController.text = data['address'] ?? '';
    _selectedYear = data['year'] ?? '';
    _selectedCourse = data['course'] ?? '';
    _existingImageUrl = data['imageUrl'];
    _blurHash = data['blurHash'];
    _addListeners(); // Add listeners after populating the data
  }

  void _storeInitialValues(Map<dynamic, dynamic> data) {
    _initialValues = {
      'name': data['name'],
      'email': data['email'],
      'phone': data['phone'],
      'dob': data['dob'],
      'organization': data['organization'],
      'designation': data['designation'],
      'city': data['city'],
      'address': data['address'],
      'year': data['year'],
      'course': data['course'],
      'imageUrl': data['imageUrl'],
      'blurHash': data['blurHash'],
    };
    _initialValuesSet = true; // Set flag after initializing values
  }

  void _debouncedCheckForChanges() {
    Future.delayed(const Duration(milliseconds: 300), _checkForChanges);
  }

  void _checkForChanges() {
    if (!_initialValuesSet) {
      return; // Avoid checking changes if initial values are not set
    }

    bool hasChanges = _nameController.text != _initialValues['name'] ||
        _emailController.text != _initialValues['email'] ||
        _phoneController.text != _initialValues['phone'] ||
        _dobController.text != _initialValues['dob'] ||
        _organizationController.text != _initialValues['organization'] ||
        _designationController.text != _initialValues['designation'] ||
        _cityController.text != _initialValues['city'] ||
        _addressController.text != _initialValues['address'] ||
        _selectedYear != _initialValues['year'] ||
        _selectedCourse != _initialValues['course'] ||
        _image != null ||
        (_existingImageUrl == null && _initialValues['imageUrl'] != null) ||
        (_existingImageUrl != null && _initialValues['imageUrl'] == null) ||
        (_existingImageUrl != null &&
            _existingImageUrl != _initialValues['imageUrl']);

    if (hasChanges != _isChanged) {
      setState(() {
        _isChanged = hasChanges;
      });
    }
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
            showSnackBar(scaffoldMessenger, "Image size should be less than 2MB.",
                Colors.red);
          }
        }
      } else {
        if (mounted) {
          showSnackBar(scaffoldMessenger, "No image selected.", Colors.red);
        }
      }
    } catch (e) {
      showSnackBar(scaffoldMessenger, "An error occurred: ${e.toString()}",
          Colors.red);
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

  List<String> _generateYears() {
    return List<String>.generate(DateTime.now().year - 1956,
            (index) => (DateTime.now().year - index).toString());
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.input,
      initialDate: DateTime.now(),
    );

    if (selectedDate != null) {
      String formattedDate = DateFormat('dd/MM/yyyy').format(selectedDate);
      setState(() {
        _dobController.text = formattedDate;
        _checkForChanges();
      });
    }
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
            imageUrl = await _uploadImage(user.uid);
            blurHash = await _generateBlurHash(_image!);
            imageUrl = imageUrl?.replaceAll('.${imageUrl.split('.').last}', '_200x200.${imageUrl.split('.').last}');
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
    return blurhash_dart.BlurHash.encode(decodedImage!, numCompX: 4, numCompY: 3).hash;
  }

  Future<void> _updateUserProfile(String uid, String? imageUrl, String? blurHash) async {
    DatabaseReference dbRef = FirebaseDatabase.instance.ref('alumni/$uid');
    await dbRef.update({
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'dob': _dobController.text.trim(),
      'organization': _organizationController.text.trim(),
      'designation': _designationController.text.trim(),
      'city': _cityController.text.trim(),
      'address': _addressController.text.trim(),
      'year': _selectedYear,
      'course': _selectedCourse,
      'imageUrl': imageUrl,
      'blurHash': blurHash,
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xff986ae7),
        iconTheme: const IconThemeData(
            color: Colors.white), // Set the back arrow color to white
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  ProfileImage(
                    image: _image,
                    existingImageUrl: _existingImageUrl,
                    blurHash: _blurHash,
                    pickImage: _pickImage,
                    removeImage: _removeImage,
                    showImageSourceActionSheet: _showImageSourceActionSheet,
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
                      FocusScope.of(context).requestFocus(FocusNode());
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
                  CustomDropdownFormField(
                    labelText: 'Graduation Year',
                    value: _selectedYear,
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
                    value: _selectedCourse,
                    items: const [
                      'Civil & Rural Engineering',
                      'Information Technology',
                      'Computer Engineering',
                      'Electronics & Tele-communication Engineering',
                      'Electrical Engineering',
                      'Mechanical Engineering',
                    ],
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
                      shape: RoundedRectangleBorder(
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
    // Add a cache-busting parameter to the URL
    String? imageUrl = existingImageUrl != null ? '$existingImageUrl?${DateTime.now().millisecondsSinceEpoch}' : null;

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
                    decodingWidth: 120,
                    decodingHeight: 120,
                  ),
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: 120,
                    height: 120,
                    errorBuilder: (context, error, stackTrace) {
                      return BlurHash(
                        hash: blurHash ?? 'LKO2?U%2Tw=w]~RBVZRi};RPxuwH',
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      } else {
                        return BlurHash(
                          hash: blurHash ?? 'LKO2?U%2Tw=w]~RBVZRi};RPxuwH',
                        );
                      }
                    },
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
