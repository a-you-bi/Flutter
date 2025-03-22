import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class User {
  final int id;
  final String? name;
  final String username;
  final String? email;
  final bool isVIP;
  final String avatarUrl;
  final String address;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.isVIP,
    required this.avatarUrl,
    required this.address,
  });
//----------------------------------------------------------------------------
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json["id"] as int,
      name: json['fullname'] as String?,
      username: json['username'] as String,
      email: json['email'] as String?,
      isVIP: json['is_vip'] as bool,
      avatarUrl: json['avatarUrl'] as String,
      address: json['address'] as String,
    );
  }
}

Future<User?> getUser(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final accessToken = prefs.getString('access_token');

  if (accessToken == null) {
    print('getCurrentUser: No access token found');
    Navigator.pushReplacementNamed(context, '/login');
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
    await _refreshToken(context);
  } else {
    print('getCurrentUser: Failed to load user: ${response.statusCode}');
    throw Exception('Failed to load user: ${response.statusCode}');
  }
  return null;
}

// Pass the context to the _refreshToken method to handle navigation
Future<void> _refreshToken(BuildContext context) async {
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
      await getUser(context); // Re-fetch user data
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




