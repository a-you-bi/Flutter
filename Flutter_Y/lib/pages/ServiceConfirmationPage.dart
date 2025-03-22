import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easelink/classes/service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';  // Add this line

class ServiceConfirmationPage extends StatefulWidget {
  final Service service;
  final int Current_User;
  // final User user;

  const ServiceConfirmationPage({super.key, required this.service, required this.Current_User});

  @override
  _ServiceConfirmationPageState createState() => _ServiceConfirmationPageState();
}

class _ServiceConfirmationPageState extends State<ServiceConfirmationPage> {
  List<DateTime> selectedDates = [];
  late ValueNotifier<List<DateTime>> _selectedDays;
  String _locationMessage = "Getting location...";
  Map<DateTime, Map<String, TimeOfDay?>> selectedTimes = {};

  @override
  void initState() {
    super.initState();
    _selectedDays = ValueNotifier([]);
    _getCurrentLocation();
  }

  void showMessage(BuildContext context, String message, bool isError) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Allows the sheet to take up more space
    backgroundColor: Colors.transparent, // Makes the background transparent
    builder: (BuildContext context) {
      return Container(
        margin: EdgeInsets.only(bottom: 0), // No bottom margin
        decoration: BoxDecoration(
          color: Colors.white, // Background color of the sheet
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(16.0), // Rounded top corners
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Ensures the column takes minimal space
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle bar (iOS-style)
              Center(
                child: Container(
                  width: 40, // Width of the drag handle
                  height: 4, // Height of the drag handle
                  margin: EdgeInsets.only(top: 8, bottom: 16), // Spacing around the bar
                  decoration: BoxDecoration(
                    color: Colors.grey[300], // Light grey color for the bar
                    borderRadius: BorderRadius.circular(2), // Slightly rounded corners
                  ),
                ),
              ),
              // Title text
              Text(
                message,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: isError ? Colors.red : const Color.fromARGB(169, 13, 255, 0), // iOS typically uses black for text
                ),
              ),
              SizedBox(height: 24), // Spacing between text and button
              Divider(
                height: 16, // Divider height
              ),
              

              // Button row
              Row(
                mainAxisAlignment: MainAxisAlignment.end, // Align button to the end
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the bottom sheet
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue, // iOS typically uses blue for buttons
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    ),
                    child: Text(
                      'Finish',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 0, 0, 0), // iOS typically uses white for buttons
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
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
          _locationMessage = "${place.locality}, ${place.administrativeArea}, ${place.country}";
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

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    if (selectedTimes.containsKey(selectedDay)) {
      // If the day is already selected, remove it
      setState(() {
        selectedTimes.remove(selectedDay);
        _selectedDays.value = selectedTimes.keys.toList(); // Update selected days
      });
    } else {
      // If the day is not selected, show the bottom sheet to select time
      final result = await showModalBottomSheet(
        context: context,
        builder: (context) => TimeSelectionBottomSheet(),
      );

      if (result != null) {
        setState(() {
          selectedTimes[selectedDay] = {
            'startTime': result['startTime'],
            'endTime': result['endTime'],
          };
          _selectedDays.value = selectedTimes.keys.toList(); // Update selected days
        });
      }
    }
  }


Future<void> submitRequest(BuildContext context) async {
  // Retrieve the access token from local storage (SharedPreferences)
  final prefs = await SharedPreferences.getInstance();
  final accessToken = prefs.getString('access_token');

  if (accessToken == null || accessToken.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Please log in to submit a request.")),
    );
    return; // Token is not available, return early.
  }

  final selectedTimesJson = getSelectedTimesJson();
  final requestPayload = {
    'selected_dates': selectedTimesJson,
    'request_date': DateTime.now().toIso8601String(),
    'request_status': 'Pending', // Ensure the status is 'Pending' as per the model choices
    'user_id': widget.Current_User, // Assuming you are sending the user ID
    'service': widget.service.id, // Send the service ID as part of the 'service' dictionary
  };

  final url = Uri.parse('http://192.168.1.108:8000/user-requests/');

  try {
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken', // Send the token in the Authorization header
      },
      body: jsonEncode(requestPayload),
    );

    if (response.statusCode == 201) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text("Service request sent successfully!")),
      // );
      showMessage(context, 'Your Request Sent\nSuccessfully', false);
    } else {
      print("Failed to send service request. Status code: ${response.statusCode}");
      print("Response body: ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send service request. Server response: ${response.body}")),
      );
    }
  } catch (e) {
    print("Error sending request: $e");
    showMessage(context, 'We faced an error while sending service request.', true);
  }
}



List<Map<String, dynamic>> getSelectedTimesJson() {
  return selectedTimes.entries.map((entry) {
    return {
      'date': DateFormat('yyyy-MM-dd').format(entry.key), // Format date as YYYY-MM-DD
      'startTime': '${entry.value['startTime']?.format(context)}:00', // Add seconds
      'endTime': '${entry.value['endTime']?.format(context)}:00',   // Add seconds
    };
  }).toList();
}
  //-------------------------------------------------------

  // Helper function to format the selected dates
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Service Confirmation'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.service.name,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  widget.service.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 24),

                // Calendar Section
                Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 01, 01),
                      lastDay: DateTime.utc(2025, 12, 31),
                      focusedDay: DateTime.now(),
                      selectedDayPredicate: (day) {
                        return selectedTimes.containsKey(day); // Check if the day is selected
                      },
                      onDaySelected: onDaySelected,
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle: TextStyle(color: Colors.white),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Selected Dates and Times Section
                if (selectedTimes.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),
                      ...selectedTimes.entries.map((entry) {
                        final date = entry.key;
                        final startTime = entry.value['startTime']?.format(context) ?? 'Not selected';
                        final endTime = entry.value['endTime']?.format(context) ?? 'Not selected';
                        return ListTile(
                          title: Text(_formatDate(date)),
                          subtitle: Text('Start: $startTime, End: $endTime'),
                        );
                      }),
                    ],
                  ),
                SizedBox(height: 24),

                // Location Section
                Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.redAccent,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Text(
                              //   'Your Location',
                              //   style: TextStyle(
                              //     fontSize: 18,
                              //     fontWeight: FontWeight.bold,
                              //     color: Colors.black87,
                              //   ),
                              // ),
                              SizedBox(height: 4),
                              Text(
                                _locationMessage,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 80,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${widget.service.price} DH",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                submitRequest(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Continue",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TimeSelectionBottomSheet extends StatefulWidget {
  const TimeSelectionBottomSheet({super.key});

  @override
  _TimeSelectionBottomSheetState createState() => _TimeSelectionBottomSheetState();
}

class _TimeSelectionBottomSheetState extends State<TimeSelectionBottomSheet> {
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != startTime) {
      setState(() {
        startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != endTime) {
      setState(() {
        endTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              'Start Time',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Text(
              startTime?.format(context) ?? 'Not selected',
              style: TextStyle(
                fontSize: 16,
                color: CupertinoColors.systemGrey,
              ),
            ),
            onTap: _selectStartTime,
          ),
          Divider(height: 1, color: CupertinoColors.systemGrey4),
          ListTile(
            title: Text(
              'End Time',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Text(
              endTime?.format(context) ?? 'Not selected',
              style: TextStyle(
                fontSize: 16,
                color: CupertinoColors.systemGrey,
              ),
            ),
            onTap: _selectEndTime,
          ),
          SizedBox(height: 16),
          CupertinoButton(
            onPressed: () {
              if (startTime != null && endTime != null) {
                Navigator.of(context).pop({
                  'startTime': startTime,
                  'endTime': endTime,
                });
              }
            },
            color: const Color.fromARGB(255, 255, 0, 0),
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}