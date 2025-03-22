import 'dart:io';
import 'package:easelink/classes/categories.dart';
import 'package:easelink/classes/service.dart';
import 'package:easelink/pages/ServiceDetailPage.dart';
import 'package:easelink/pages/profile.dart';
import 'package:easelink/pages/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:badges/badges.dart' as custom_badge;

import 'package:geolocator/geolocator.dart';  // Import Geolocator
import 'package:geocoding/geocoding.dart';
import 'dart:async';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _showResults = false;
  int Current_User = 0;

  List<Cate> Cate_list = [];
  String _locationMessage = "Getting location...";

  @override
  void initState() {
    super.initState();
    print("initState called");
    // Set the status bar color to red
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Color(0xFFFF3131), // Set the status bar color to red
    ));
      _loadCategories();
      _getCurrentLocation();
    // Timer.periodic(Duration(seconds: 5), (timer) {
    //   _loadCategories();
    //   _getCurrentLocation();

    // });
  }
  Future<void> _getCurrentLocation() async {
  LocationPermission permission = await Geolocator.requestPermission();

  if (permission == LocationPermission.denied) {
    setState(() {
      _locationMessage = "Location permission denied";
    });
    return;
  }

  Position position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );

  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];

      setState(() {
        _locationMessage =
            // "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
            "${place.locality}, ${place.administrativeArea}, ${place.country}";
      });
    } else {
      setState(() {
        _locationMessage = "No address found";
      });
    }
  } catch (e) {
    setState(() {
      _locationMessage = "Error getting address: $e";
    });
  }
}

  Future<void> _loadCategories() async {
    try {
      List<Cate> categories = (await fetchCategories(context)) ?? [];
      setState(() {
        Cate_list = categories;
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return FutureBuilder(
          future: getUser(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data == null) {
              return Center(child: Text('No user data found'));
            } else {
              final user = snapshot.data!;
              Current_User = user.id;

              return Container(
                padding: EdgeInsets.all(20),
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
                    SizedBox(height: 20),
                    UserAccountsDrawerHeader(
                      accountName: Text(user.name ?? 'No Name'),
                      accountEmail: Text(user.email ?? 'No Email'),

                      currentAccountPicture: CircleAvatar(
                        radius: 40,
                        backgroundImage: (user.avatarUrl == 'null' || user.avatarUrl.isEmpty)
                            ? AssetImage('assets/images/default_profile.png')
                            : FileImage(File(user.avatarUrl)) as ImageProvider,
                        backgroundColor: Colors.white,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        children: [
                          _buildListTile(context, Icons.person, 'Profile', ProfilePage()),
                          _buildListTile(context, Icons.settings, 'Settings', ProfilePage()),
                          _buildListTile(context, Icons.logout, 'Logout', ProfilePage()),
                          SizedBox(height: 20),
                          Text('Version 1.0.0', style: TextStyle(color: Colors.grey)),
                          SizedBox(height: 10),
                          Text('2025 ServiceLink. All rights reserved.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red,
                image: DecorationImage(
                  image: AssetImage('assets/images/cover2.png'), // Replace with your image path
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.red.withOpacity(0.5), BlendMode.dstATop),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Location',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          custom_badge.Badge(
                            badgeContent: Text('3', style: TextStyle(color: Colors.white)), // Example badge content
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white),
                              ),
                              child: Icon(Icons.notifications_none, color: Colors.red),
                            ),
                          ),
                          SizedBox(width: 10),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  FutureBuilder(
                    future: getUser(context),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text(
                          'Loading...',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        );
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data == null) {
                        return Center(child: Text('No address found'));
                      } else {
                        final user = snapshot.data!;
                        return Text(
                          _locationMessage,
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        );
                      }
                    },
                  ),
                  SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        suffixIcon: IconButton(
                          icon: Icon(_showResults ? Icons.close : Icons.search),
                          onPressed: () {
                            setState(() {
                              _controller.clear();
                              _showResults = false;
                              _searchResults = [];
                            });
                          },
                        ),
                      ),
                      onChanged: (value) async {
                        if (value.isEmpty) {
                          setState(() {
                            _showResults = false;
                            _searchResults = [];
                          });
                          return;
                        }
                        try {
                          List<Service>? results = await searchServices(value.trim(), context);
                          setState(() {
                            _searchResults = results ?? [];
                            _showResults = true;
                          });
                        } catch (e) {
                          print('Error: $e');
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            _showResults
                ? Expanded(
                    child: _searchResults.isEmpty
                        ? Center(child: Text('No results found'))
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final service = _searchResults[index] as Service;
                              return ListTile(
                                title: Text(service.name),
                                subtitle: Text(service.description),
                                trailing: Text("${service.price}DH"),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ServiceDetailPage(service: service, Current_User: Current_User),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  )
                  // ignore: avoid_unnecessary_containers
      : Container(
          child: SizedBox(
            // height: 150,
            width: double.infinity,
            child: Cate_list.isEmpty
                ? Center(
                    child: Text(
                      'No categories found',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
                    ),
                  )
                : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    height: 150,
                      // Reduced height for smaller cards
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: Cate_list.length,
                        itemBuilder: (context, index) {
                          final category = Cate_list[index];
                          return Container(
                            width: 300, // Smaller width for compact look
                            decoration: BoxDecoration(
                             color: const Color.fromARGB(255, 255, 255, 255),
                             borderRadius: BorderRadius.circular(10),
                            ),
                            margin: EdgeInsets.symmetric(horizontal: 8), // Adds space between cards
                            child: Card(
                              color: Colors.white,
                              elevation: 4, // Light shadow effect
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12), // Slightly rounded corners
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(8), // Reduced padding
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center, // Center content
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category.name,
                                      style: TextStyle(
                                        fontSize: 16, // Smaller text
                                        fontWeight: FontWeight.bold,
                                        color: const Color.fromARGB(255, 255, 8, 8), // Nice accent color
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      category.description,
                                      style: TextStyle(
                                        fontSize: 12, // Smaller description text
                                        color: Colors.black54,
                                      ),
                                      maxLines: 2, // Limits text overflow
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ),
          ),
        ),

          ],
        ),
      ),
      floatingActionButton: Builder(
        builder: (context) {
          return FloatingActionButton(
            onPressed: () {
              _showBottomSheet(context);
            },
            backgroundColor: Colors.red,
            child: Icon(Icons.menu, color: Colors.white),
          );
        },
      ),
    );
  }











  ListTile _buildListTile(BuildContext context, IconData icon, String title, Widget page) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        // Navigate to the selected page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
    );
  }
}