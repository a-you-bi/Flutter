import 'package:easelink/classes/request.dart';
import 'package:easelink/classes/service.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RequestDetailPage extends StatefulWidget {
  final String title;

  const RequestDetailPage({super.key, required this.title});

  @override
  _RequestsPageState createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestDetailPage> {
  List<Request> requests = [];
  bool isLoading = true;
  Map<int, String> serviceNames = {}; // Map to store service names by ID

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void fetchServiceName(int serviceId) async {
    try {
      final serviceName = await getServiceNameById(serviceId, context);
      if (serviceName != null) {
        setState(() {
          serviceNames[serviceId] = serviceName; // Store the service name
        });
      } else {
        print('No service found with ID: $serviceId');
      }
    } catch (e) {
      print('Error fetching service name: $e');
    }
  }

  Future<void> _loadRequests() async {
    try {
      final fetchedRequests = await fetchRequests(context);
      setState(() {
        requests = fetchedRequests;
        isLoading = false;
      });

      // Fetch service names for all requests
      for (final request in requests) {
        if (request.serviceId != null) {
          fetchServiceName(request.serviceId!);
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load requests: $e')),
      );
      print('Failed to load requests: $e and data is $requests');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : requests.isEmpty
              ? Center(child: Text('No requests found.'))
              : ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    final serviceName = serviceNames[request.serviceId] ?? "Loading...";
                    return Card(
                      margin: EdgeInsets.all(8.0),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Request ID: ${request.requestId ?? "N/A"}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text('User ID: ${request.userId ?? "N/A"}'),
                            SizedBox(height: 8),
                            Text('Service: $serviceName'), // Display service name
                            SizedBox(height: 8),
                            Text('Request Date: ${request.requestDate ?? "N/A"}'),
                            SizedBox(height: 8),
                            Text('Status: ${request.requestStatus ?? "N/A"}'),
                            SizedBox(height: 8),
                            Text(
                              'Selected Dates:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ...(request.selectedDates ?? []).map((date) {
                              return Text(
                                '- Date: ${date['date']}, \nStart: ${date['startTime']}, \nEnd: ${date['endTime']}',
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}