import 'package:easelink/pages/profile.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class User {
  final String email;
  final String name;
  final String username;
  final String phone;
  final String gender;
  final String avatarUrl;

  User({
    required this.email,
    required this.name,
    required this.username,
    required this.phone,
    required this.gender,
    required this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'],
      name: json['fullname'],
      username: json['username'],
      phone: json['phone'],
      gender: json['gender'],
      avatarUrl: json['avatarUrl'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'fullname': name,
      'username': username,
      'phone': phone,
      'gender': gender,
      'avatarUrl': avatarUrl,
    };
  }
}

class UserDataPage extends StatefulWidget {
  const UserDataPage({super.key});

  @override
  _UserDataPageState createState() => _UserDataPageState();
}

class _UserDataPageState extends State<UserDataPage> {
  final emailController = TextEditingController();
  final fullNameController = TextEditingController();
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  String? selectedGender;

  bool isEditMode = false; // Track edit mode
  double _position = 800; // Start off-screen (bottom)
  double _opacity = 0.0; // Start invisible

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 200), () {
      setState(() {
        _position = 0; // Move to top
        _opacity = 1.0; // Make visible
      });
    });
  }

  final picker = ImagePicker();
  String? avatarPath;

  Future<void> pickImage() async {
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = pickedFile.path.split('/').last;
        final savedImage = File('${appDir.path}/$fileName');
        await File(pickedFile.path).copy(savedImage.path);

        final prefs = await SharedPreferences.getInstance();
        setState(() {
          avatarPath = savedImage.path;
        });

        final accessToken = prefs.getString('access_token');
        if (accessToken != null) {
          final url = Uri.parse('http://192.168.1.108:8000/profile/');
          final response = await http.put(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: json.encode({'avatarUrl': savedImage.path}),
          );

          if (response.statusCode == 200) {
            print('Avatar updated successfully');
          } else {
            print('Failed to update avatar: ${response.statusCode}');
          }
        }

        print('Image saved at: ${savedImage.path}');
      } else {
        print('No image picked');
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken == null) {
        print('getCurrentUser: No access token found');
        Navigator.pushReplacementNamed(context, '/Flutter_Y/lib/pages/login.dart');
        return null;
      }

      final url = Uri.parse('http://192.168.1.108:8000/profile/');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('getCurrentUser: Data fetched successfully: $data');
        return User.fromJson(data);
      } else if (response.statusCode == 401) {
        print('getCurrentUser: Access token expired, refreshing...');
        await _refreshToken();
        return getCurrentUser();
      } else {
        print('getCurrentUser: Failed to load user: ${response.statusCode}');
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting current user: $e');
      Navigator.pushReplacementNamed(context, '/Flutter_Y/lib/pages/login.dart');
      return null;
    }
  }

  Future<void> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null) {
        print('No refresh token found');
        Navigator.pushReplacementNamed(context, '/Flutter_Y/lib/pages/login.dart');
        return;
      }

      final url = Uri.parse('http://127.0.0.1:8000/token/refresh/');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await prefs.setString('access_token', data['access_token']);
        print('Token refreshed successfully');
      } else {
        print('Failed to refresh token: ${response.statusCode}');
        Navigator.pushReplacementNamed(context, '/Flutter_Y/lib/pages/login.dart');
      }
    } catch (e) {
      print('Error refreshing token: $e');
      Navigator.pushReplacementNamed(context, '/Flutter_Y/lib/pages/login.dart');
    }
  }

  Future<void> updateUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    if (accessToken == null) {
      print('updateUser: No access token found');
      Navigator.pushReplacementNamed(context, '/Flutter_Y/lib/pages/login.dart');
      return;
    }

    final url = Uri.parse('http://192.168.1.108:8000/profile/');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: json.encode(user.toJson()),
    );

    if (response.statusCode == 200) {
      print('User updated successfully');
    } else {
      print('Failed to update user: ${response.statusCode}');
      throw Exception('Failed to update user: ${response.statusCode}');
    }
  }

  Widget buildEditableField(String label, TextEditingController controller, String title, IconData icon, Color color) {
    return Card(
      color: const Color.fromARGB(255, 255, 255, 255),
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, color: color),
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Enter Your $title',
                  border: InputBorder.none,
                ),
                enabled: isEditMode, // Enable/disable based on edit mode
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        title: Text('Edit Profile', style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0))),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_outlined, color: const Color.fromARGB(255, 0, 0, 0)),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(isEditMode ? Icons.save : Icons.edit, color: const Color.fromARGB(255, 0, 0, 0)),
            onPressed: () {
              setState(() {
                isEditMode = !isEditMode; // Toggle edit mode
              });

              if (!isEditMode) {
                // Save changes when exiting edit mode
                final updatedUser = User(
                  name: fullNameController.text,
                  username: usernameController.text,
                  email: emailController.text,
                  phone: phoneController.text,
                  gender: selectedGender!,
                  avatarUrl: avatarPath ?? "null",
                );
                updateUser(updatedUser);
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<User?>(
        future: getCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData) {
            return Center(child: Text('Error loading profile'));
          }

          final user = snapshot.data!;
          emailController.text = user.email;
          fullNameController.text = user.name;
          usernameController.text = user.username;
          phoneController.text = user.phone;
          selectedGender = user.gender;
          avatarPath = user.avatarUrl;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: (user.avatarUrl == 'null' || user.avatarUrl.isEmpty)
                        ? AssetImage('assets/images/default_profile.png')
                        : FileImage(File(user.avatarUrl)) as ImageProvider,
                  ),
                ),
                SizedBox(height: 20),
                Text(user.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                Text(user.gender, style: TextStyle(fontSize: 16, color: Colors.grey)),
                SizedBox(height: 30),
                Card(
                  color: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 15),
                        buildEditableField('Full Name', fullNameController, 'Full Name', Icons.person, Colors.blue),
                        buildEditableField('Username', usernameController, 'Username', Icons.person_add_alt, Colors.green),
                        buildEditableField('Email', emailController, 'Email', Icons.email, Colors.orange),
                        buildEditableField('Phone', phoneController, 'Phone', Icons.phone, Colors.purple),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}