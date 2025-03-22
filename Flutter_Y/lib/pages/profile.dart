import 'dart:io';

import 'package:easelink/pages/RequestDetailPage.dart';
import 'package:easelink/pages/user_data.dart';
import 'package:easelink/pages/welcomePage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<_ProfilePageState> profilePageKey = GlobalKey<_ProfilePageState>();

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<User?> getCurrentUser() async {
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
      _refreshToken();
    } else {
      print('getCurrentUser: Failed to load user: ${response.statusCode}');
      throw Exception('Failed to load user: ${response.statusCode}');
    }
    return null;
  }

  Future<void> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    if (refreshToken == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final url = Uri.parse('http://127.0.0.1:8000/token/refresh/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await prefs.setString('access_token', data['access']);
        await getCurrentUser();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please log in again.')),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Profile Page'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_outlined, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => WelcomePage()),
            );
          },
        ),
        actions: [
          Icon(Icons.settings, color: Colors.black),
          SizedBox(width: 16),
        ],
      ),
      body: FutureBuilder<User?>(
        future: getCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('No user data found'));
          } else {
            final user = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ProfileInfo(user: user),
                  StatsSection(user: user),
                  if (!(user.isVIP ?? true)) VIPFeatures(user: user),
                  _buildEventDashboard(), // Integrated EventDashboard content
                ],
              ),
            );
          }
        },
      ),
    );
  }

  // Integrated EventDashboard content
Widget _buildEventDashboard() {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24),
        Text(
          'DashBoard',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2, // Number of cards per row
          crossAxisSpacing: 16, // Horizontal spacing between cards
          mainAxisSpacing: 16, // Vertical spacing between cards
          shrinkWrap: true, // Ensures GridView doesn't expand infinitely
          physics: NeverScrollableScrollPhysics(), // Disables GridView's scrolling
          children: [
            _buildEventCard(
  Icons.favorite, // Icon for the card
  'Favorites',
  'Explore your favorites',
  Colors.red,
  context,
),
_buildEventCard(
  Icons.request_page, // Icon for the card
  'Requests',
  'Manage your requests',
   const Color.fromARGB(220, 86, 54, 244),
   context,
),
_buildEventCard(
  Icons.link, // Icon for the card
  'Links',
  'Manage your links',
   const Color.fromARGB(255, 40, 210, 117),
   context,
),
_buildEventCard(
  Icons.star, // Icon for the card
  'Rating',
  'Manage your rating',
   const Color.fromARGB(255, 87, 48, 148),
   context,
),
          ],
        ),
        // SizedBox(height: 16),
      ],
    ),
  );
}
  // Event Card Widget
Widget _buildEventCard(IconData icon, String title, String details, Color color, BuildContext context) {
  return SizedBox(
    child: Card(
      color: color, // Set card background color
      elevation: 4,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
              children: [
                Icon(
                  icon,
                  size: 40, // Set icon size
                  color: Colors.white, // Set icon color
                ),
                SizedBox(height: 16), // Add spacing between icon and text
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18, // Adjust font size
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Set text color to white
                  ),
                ),
                SizedBox(height: 8), // Add spacing between title and details
                Text(
                  details,
                  style: TextStyle(
                    fontSize: 14, // Adjust font size
                    color: Colors.white.withOpacity(0.8), // Set text color with opacity
                  ),
                ),
              ],
            ),
          ),
          // Clickable Icon at Top-Right
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                // Navigate to the RequestsPage when the icon is clicked
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RequestDetailPage(title: title), // Pass the title if needed
                  ),
                );
              },
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  Icons.arrow_circle_right_rounded, // Icon to display
                  size: 24, // Set icon size
                  color: Colors.white, // Set icon color
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}

class User {
  final String? name;
  final String username;
  final String? email;
  final bool isVIP;
  final String avatarUrl;

  User({
    required this.name,
    required this.username,
    required this.email,
    required this.isVIP,
    required this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['fullname'] as String?,
      username: json['username'] as String,
      email: json['email'] as String?,
      isVIP: json['is_vip'] as bool,
      avatarUrl: json['avatarUrl'] as String,
    );
  }
}

class ProfileInfo extends StatelessWidget {
  final User user;
  const ProfileInfo({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(user.isVIP ? "assets/images/test_cover_VIP.png" : "assets/images/test_cover.png"),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: (user.avatarUrl == 'null' || user.avatarUrl.isEmpty)
                  ? AssetImage('assets/images/default_profile.png')
                  : FileImage(File(user.avatarUrl)) as ImageProvider,
              backgroundColor: Colors.white,
            ),
            SizedBox(height: 8),
            Text(
              user.name ?? 'No Name',
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 0, 0),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              user.username ?? 'No Email',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => UserDataPage()));
              },
              icon: Icon(Icons.edit, size: 16, color: Colors.white),
              label: Text("Edit Profile", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 216, 11, 42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class StatsSection extends StatelessWidget {
  final User user;
  const StatsSection({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem("0", "Ongoing"),
          _buildStatItem("9", "Finished"),
          _buildStatItem("4", "Later"),
          _buildStatItem("13", "Total"),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}

class VIPFeatures extends StatelessWidget {
  final User user;
  const VIPFeatures({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 83, 26, 147),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "VIP Features",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255, 216, 11, 42)),
                child: Text("See all VIP Features", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildFeatureRow("Unlimited Services", true),
          _buildFeatureRow("Unlock More Features", true),
          _buildFeatureRow("Promotion of 5%", true),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String feature, bool isAvailable) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            feature,
            style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255), fontSize: 16),
          ),
          Icon(
            isAvailable ? Icons.check : Icons.close,
            color: isAvailable ? const Color.fromARGB(255, 255, 255, 255) : const Color.fromARGB(255, 238, 72, 12),
          ),
        ],
      ),
    );
  }
}