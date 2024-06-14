import 'dart:io';
import 'package:alumniconnect/screens/home_screen.dart';
import 'package:alumniconnect/util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:image/image.dart' as img;

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  CreateProfileScreenState createState() => CreateProfileScreenState();
}

class CreateProfileScreenState extends State<CreateProfileScreen> {
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
  String? _selectedYear;
  String? _selectedCourse;

  static const int maxFileSize = 2 * 1024 * 1024; // 2MB in bytes

  Future<void> _pickImage(ImageSource source) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final fileSize = await file.length();

      if (fileSize <= maxFileSize) {
        setState(() {
          _image = file;
        });
      } else {
        showSnackBar(scaffoldMessenger, "Image size should be less than 2MB.", Colors.red);
      }
    } else {
      showSnackBar(scaffoldMessenger, "No image selected.", Colors.red);
    }
  }

  void _removeImage() {
    setState(() {
      _image = null;
    });
  }

  List<String> _getYears() {
    int currentYear = DateTime.now().year;
    return List<String>.generate(currentYear - 1956, (index) => (currentYear - index).toString());
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime now = DateTime.now();
    DateTime eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);

    DateTime? selectedDate = await showDatePicker(
      fieldLabelText: "Enter Date (DD/MM/YYYY)",
      context: context,
      firstDate: DateTime(1924),
      lastDate: eighteenYearsAgo,
      initialEntryMode: DatePickerEntryMode.input,
      initialDate: eighteenYearsAgo,
      locale: const Locale('en', 'GB'),
    );

    if (selectedDate != null) {
      String formattedDate = DateFormat('dd/MM/yyyy').format(selectedDate);
      _dobController.text = formattedDate;
    }
  }

  Future<void> _createProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final scaffoldMessenger = ScaffoldMessenger.of(context);

      try {
        final FirebaseAuth auth = FirebaseAuth.instance;
        final User? user = auth.currentUser;

        if (user != null) {
          String? imageUrl;
          String? blurHash;
          if (_image != null) {
            final storageRef = FirebaseStorage.instance.ref().child('profile_images').child('${user.uid}.${_image!.path.split('.').last}');
            await storageRef.putFile(_image!);
            imageUrl = await storageRef.getDownloadURL();
            // Generate BlurHash
            final imageBytes = await _image!.readAsBytes();
            final decodedImage = img.decodeImage(imageBytes);
            // final Uint8List uint8List = Uint8List.fromList(imageBytes);
            blurHash = BlurHash.encode(decodedImage!, numCompX: 4, numCompY: 3).hash;
            imageUrl = imageUrl.replaceAll('.${imageUrl.split('.').last}', '_200x200.${imageUrl.split('.').last}');
          }

          DatabaseReference dbRef = FirebaseDatabase.instance.ref('alumni/${user.uid}');
          await dbRef.set({
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

          showSnackBar(scaffoldMessenger, "Profile created successfully!", Colors.green);

          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (Route<dynamic> route) => false,
            );
          }
        } else {
          showSnackBar(scaffoldMessenger, "User not authenticated.", Colors.red);
        }
      } catch (e) {
        showSnackBar(scaffoldMessenger, "An error occurred: ${e.toString()}", Colors.red);
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
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
                  if (_image != null)
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

  Widget _buildImageOption({required IconData icon, required String label, required VoidCallback onTap}) {
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
        title: const Text('Create Profile'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  ProfileImage(
                    image: _image,
                    showImageSourceActionSheet: _showImageSourceActionSheet,
                  ),
                  const SizedBox(height: 20.0),
                  CustomTextFormField(
                    controller: _nameController,
                    labelText: 'Full Name',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  CustomTextFormField(
                    controller: _emailController,
                    labelText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  CustomTextFormField(
                    controller: _phoneController,
                    labelText: 'Phone Number',
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      final phoneRegex = RegExp(r'^\+?\d{10,15}$');
                      if (!phoneRegex.hasMatch(value)) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your date of birth';
                      }
                      final dateRegex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
                      if (!dateRegex.hasMatch(value)) {
                        return 'Please enter a valid date (dd/MM/yyyy)';
                      }
                      return null;
                    },
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your organization';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  CustomTextFormField(
                    controller: _designationController,
                    labelText: 'Designation',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your designation';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  CustomTextFormField(
                    controller: _cityController,
                    labelText: 'City',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your city';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  CustomTextFormField(
                    controller: _addressController,
                    labelText: 'Address',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  CustomDropdownFormField(
                    labelText: 'Graduation Year',
                    value: _selectedYear,
                    items: _getYears(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select your graduation year';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _selectedYear = value;
                      });
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select your course';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _selectedCourse = value;
                      });
                    },
                  ),
                  const SizedBox(height: 30.0),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                    onPressed: _createProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      'Create Profile',
                      style: TextStyle(
                        fontSize: 18.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileImage extends StatelessWidget {
  final File? image;
  final VoidCallback showImageSourceActionSheet;

  const ProfileImage({
    super.key,
    required this.image,
    required this.showImageSourceActionSheet,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.all(8.0), // Add margin around the CircleAvatar
          child: CircleAvatar(
            radius: 60,
            backgroundImage: image != null ? FileImage(image!) : null,
            child: image == null
                ? const Icon(
              Icons.person,
              size: 60,
              color: Colors.grey,
            )
                : null,
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
