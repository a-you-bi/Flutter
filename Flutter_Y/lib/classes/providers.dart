import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class Provider {
  final int id;
  final String? fullname;
  final String? email;
  final bool isdisponible;
  final String address;
  final double rating_avg;

  Provider({
    required this.id,
    required this.fullname,
    required this.email,
    required this.isdisponible,
    required this.address,
    required this.rating_avg,
  });
//----------------------------------------------------------------------------
  factory Provider.fromJson(Map<String, dynamic> json) {
    return Provider(
      fullname: json['fullname'] as String?,
      email: json['email'] as String?,
      isdisponible: json['is_disponible'] as bool,
      address: json['address'] as String,
      rating_avg: json['rating_avg'] as double,
      id: json['id'] as int,
    );
  }
}

Future<List<Provider>> getUsers(BuildContext context, String serviceName) async {
  final prefs = await SharedPreferences.getInstance();
  final accessToken = prefs.getString('access_token');

  if (accessToken == null) {
    print('getUsers: No access token found');
    Navigator.pushReplacementNamed(context, '/login');
    return [];
  }

  final url = Uri.parse('http://192.168.1.108:8000/user-providers/?query=$serviceName');
  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    },
  );

  if (response.statusCode == 200) {
    List<dynamic> data = json.decode(response.body);
    print('getUsers: Data fetched successfully: $data');
    return data.map((json) => Provider.fromJson(json)).toList();
  } else if (response.statusCode == 401) {
    print('getUsers: Access token expired, refreshing...');
    await _refreshToken(context, serviceName);
  } else {
    print('getUsers: Failed to load users: ${response.statusCode}');
    throw Exception('Failed to load users: ${response.statusCode}');
  }
  return [];
}

// Pass the context to the _refreshToken method to handle navigation
Future<void> _refreshToken(BuildContext context, String serviceName) async {
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
      await getUsers(context, serviceName); // Re-fetch user data
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



//provider by id

// Future<Provider?> getProviderById(BuildContext context, int providerId) async {
//   final prefs = await SharedPreferences.getInstance();
//   final accessToken = prefs.getString('access_token');

//   if (accessToken == null) {
//     print('getProviderById: No access token found');
//     Navigator.pushReplacementNamed(context, '/login');
//     return null;
//   }

//   final url = Uri.parse('http://192.168.1.108:8000/user-providers/?id=$providerId');
//   final response = await http.get(
//     url,
//     headers: {
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer $accessToken',
//     },
//   );

//   if (response.statusCode == 200) {
//     Map<String, dynamic> data = json.decode(response.body);
//     print('getProviderById: Provider fetched successfully: $data');
//     return Provider.fromJson(data);
//   } else if (response.statusCode == 401) {
//     print('getProviderById: Access token expired, refreshing...');
//     await _refreshTokenForProvider(context, providerId);
//   } else {
//     print('getProviderById: Failed to load provider: ${response.statusCode}');
//     throw Exception('Failed to load provider: ${response.statusCode}');
//   }
//   return null;
// }
Future<Provider?> getProviderById(BuildContext context, int providerId) async {
  final prefs = await SharedPreferences.getInstance();
  final accessToken = prefs.getString('access_token');

  if (accessToken == null) {
    print('getProviderById: No access token found');
    Navigator.pushReplacementNamed(context, '/login');
    return null;
  }

  final url = Uri.parse('http://192.168.1.108:8000/user-providers/?id=$providerId/');
  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    },
  );

  if (response.statusCode == 200) {
    // Parse the response as a List<dynamic>
    List<dynamic> data = json.decode(response.body);

    // Check if the list is not empty and find the provider with the matching ID
    if (data.isNotEmpty) {
      // Assuming the API returns a list of providers, find the one with the matching ID
      final providerData = data.firstWhere(
        (provider) => provider['id'] == providerId,
        orElse: () => null,
      );

      if (providerData != null) {
        print('getProviderById: Provider fetched successfully: $providerData');
        return Provider.fromJson(providerData);
      } else {
        print('getProviderById: Provider with ID $providerId not found');
        return null;
      }
    } else {
      print('getProviderById: No providers found in the response');
      return null;
    }
  } else if (response.statusCode == 401) {
    print('getProviderById: Access token expired, refreshing...');
    await _refreshTokenForProvider(context, providerId);
  } else {
    print('getProviderById: Failed to load provider: ${response.statusCode}');
    throw Exception('Failed to load provider: ${response.statusCode}');
  }
  return null;
}

// Helper function to refresh token specifically for getProviderById
Future<void> _refreshTokenForProvider(BuildContext context, int providerId) async {
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
      await getProviderById(context, providerId); // Re-fetch provider data
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
