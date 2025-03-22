import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Request {
  final int? requestId;
  final int? userId;
  final int? serviceId;
  final List<dynamic>? selectedDates;
  final String? requestDate;
  final String? requestStatus;

  Request({
    required this.requestId,
    required this.userId,
    required this.serviceId,
    required this.selectedDates,
    required this.requestDate,
    required this.requestStatus,
  });

  // Factory method to parse JSON into a Request object
  factory Request.fromJson(Map<String, dynamic> json) {
    return Request(
      requestId: json['request_id'] as int?,
      userId: json['user'] as int?, // Updated key
      serviceId: json['service'] as int?, // Updated key
      selectedDates: json['selected_dates'] as List<dynamic>?,
      requestDate: json['request_date'] as String?,
      requestStatus: json['request_status'] as String?,
    );
  }
}

// Future<List<Request>> fetchRequests(BuildContext context) async {
//   final prefs = await SharedPreferences.getInstance();
//   final accessToken = prefs.getString('access_token');

//   if (accessToken == null) {
//     print('fetchRequests: No access token found');
//     Navigator.pushReplacementNamed(context, '/login');
//     return [];
//   }

//   final url = Uri.parse('http://192.168.1.108:8000/user-requests/');
//   final response = await http.get(
//     url,
//     headers: {
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer $accessToken',
//     },
//   );

//   if (response.statusCode == 200) {
//     List<dynamic> data = json.decode(response.body);
//     print('fetchRequests: Data fetched successfully: $data');
//     return data.map((json) => Request.fromJson(json)).toList();
//   } else if (response.statusCode == 401) {
//     print('fetchRequests: Access token expired, refreshing...');
//     await _refreshToken(context);
//   } else {
//     print('fetchRequests: Failed to load requests: ${response.statusCode}');
//     throw Exception('Failed to load requests: ${response.statusCode}');
//   }
//   return [];
// }
Future<List<Request>> fetchRequests(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final accessToken = prefs.getString('access_token');

  if (accessToken == null) {
    print('fetchRequests: No access token found');
    Navigator.pushReplacementNamed(context, '/login');
    return [];
  }

  final url = Uri.parse('http://192.168.1.108:8000/user-requests/');
  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    },
  );

  print('API Response Status Code: ${response.statusCode}');
  print('API Response Body: ${response.body}');

  if (response.statusCode == 200) {
    List<dynamic> data = json.decode(response.body);
    print('Parsed Data: $data');

    // Log each parsed request
    List<Request> requests = data.map((json) {
      print('Parsing JSON: $json');
      return Request.fromJson(json);
    }).toList();

    return requests;
  } else if (response.statusCode == 401) {
    print('fetchRequests: Access token expired, refreshing...');
    await _refreshToken(context);
  } else {
    print('fetchRequests: Failed to load requests: ${response.statusCode}');
    throw Exception('Failed to load requests: ${response.statusCode}');
  }
  return [];
}
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
      await fetchRequests(context); // Re-fetch requests after refreshing token
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