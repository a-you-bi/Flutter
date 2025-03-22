import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Service {
  final String name;
  final String description;
  final double price;
  final int id;
  final String service_image;

  Service({
    required this.name,
    required this.description,
    required this.price,
    required this.id,	
    required this.service_image,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['category'],
      name: json['service_name'],
      description: json['service_description'],
      price: json['service_price'].toDouble(),
      service_image: json['service_image'],
    );
  }
}

Future<List<Service>?> searchServices(String query, BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final accessToken = prefs.getString('access_token');

  if (accessToken == null) {
    print('getCurrentUser: No access token found');
    Navigator.pushReplacementNamed(context, '/login');
    return null;
  }
  final url = Uri.parse('http://192.168.1.108:8000/user-services/?query=$query');
  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    },
  );

  if (response.statusCode == 200) {
    List<dynamic> data = json.decode(response.body);
    print('get Service: Data fetched successfully: $data');
    return data.map((service) => Service.fromJson(service)).toList();
    // return data.map((json) => Service.fromJson(json)).toList();
  } else if (response.statusCode == 401) {
    print('getCurrentUser: Access token expired, refreshing...');
    await _refreshToken(query, context);
  } else {
    print('getCurrentUser: Failed to load services: ${response.statusCode}');
    throw Exception('Failed to load services: ${response.statusCode}');
  }
  return null;
}

// Wrapper function to convert List<Service> to List<dynamic>
Future<List<dynamic>?> searchServicesAsDynamic(String query, BuildContext context) async {
  final services = await searchServices(query, context);
  return services?.map((service) => service as dynamic).toList();
}

// Pass the context to the _refreshToken method to handle navigation
Future<void> _refreshToken(String query, BuildContext context) async {
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
      await searchServices(query, context); // Re-fetch services
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




// Future<String?> getServiceNameById(int serviceId, BuildContext context) async {
//   final prefs = await SharedPreferences.getInstance();
//   final accessToken = prefs.getString('access_token');

//   if (accessToken == null) {
//     print('getServiceNameById: No access token found');
//     Navigator.pushReplacementNamed(context, '/login');
//     return null;
//   }

//   // Replace with your API endpoint for fetching a single service by ID
//   final url = Uri.parse('http://192.168.1.108:8000/user-services/$serviceId/');
//   final response = await http.get(
//     url,
//     headers: {
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer $accessToken',
//     },
//   );

//   print('API Response Status Code: ${response.statusCode}');
//   print('API Response Body: ${response.body}');

//   if (response.statusCode == 200) {
//     try {
//       // Parse the JSON response into a Map
//       final Map<String, dynamic> data = json.decode(response.body);
//       print('Service Data: $data');

//       // Convert the JSON into a Service object
//       final service = Service.fromJson(data);
//       return service.name; // Return the service name
//     } catch (e) {
//       print('Error parsing JSON: $e');
//       throw Exception('Failed to parse service: $e');
//     }
//   } else if (response.statusCode == 401) {
//     print('getServiceNameById: Access token expired, refreshing...');
//     await _refreshToken2(context);
//   } else {
//     print('getServiceNameById: Failed to load service: ${response.statusCode}');
//     throw Exception('Failed to load service: ${response.statusCode}');
//   }

//   return null;
// }
Future<String?> getServiceNameById(int serviceId, BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final accessToken = prefs.getString('access_token');

  if (accessToken == null) {
    print('getServiceNameById: No access token found');
    Navigator.pushReplacementNamed(context, '/login');
    return null;
  }

  final url = Uri.parse('http://192.168.1.108:8000/user-services/$serviceId/');
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
    try {
      final Map<String, dynamic> data = json.decode(response.body);
      print('Service Data: $data');

      final service = Service.fromJson(data);
      return service.name; // Return the service name
    } catch (e) {
      print('Error parsing JSON: $e');
      return "Unknown Service"; // Fallback value
    }
  } else if (response.statusCode == 404) {
    print('Service not found for ID: $serviceId');
    return "Unknown Service"; // Fallback value
  } else if (response.statusCode == 401) {
    print('getServiceNameById: Access token expired, refreshing...');
    await _refreshToken2(context);
  } else {
    print('getServiceNameById: Failed to load service: ${response.statusCode}');
    return "Unknown Service"; // Fallback value
  }

  return null;
}
Future<void> _refreshToken2(BuildContext context) async {
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
      // You can retry the original request here if needed
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