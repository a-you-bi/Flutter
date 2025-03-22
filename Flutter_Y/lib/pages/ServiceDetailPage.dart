import 'package:easelink/classes/providers.dart';
import 'package:easelink/pages/ProviderDetailPage.dart';
import 'package:easelink/pages/ServiceConfirmationPage.dart';
import 'package:flutter/material.dart';
import 'package:easelink/classes/service.dart';
import 'package:easelink/classes/categories.dart';

class ServiceDetailPage extends StatefulWidget {
  final Service service;
  final int Current_User;

  const ServiceDetailPage({super.key, required this.service, required this.Current_User});

  @override
  _ServiceDetailPageState createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage> {
  List<Cate>? cateList = [];
  String? categoryName; // Holds the category name
  late Future<List<Provider>> _futureProviders;
  int? selectedProviderId; // selected provider id

  @override
  void initState() {
    super.initState();
    _futureProviders = getUsers(context, widget.service.name);
    // Ensure fetching runs after the widget builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchCategory(widget.service.id - 1);
    });
  }

  void fetchCategory(int id) async {
    List<Cate>? category = await getCategories(context, id);
    if (category != null) {
      setState(() {
        categoryName = category[id].name; // Update category name
      });
    } else {
      print('Category not found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          widget.service.name,
          style: TextStyle(fontSize: 20),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border),
            onPressed: () {
              // Add to favorites
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image at the top
            Container(
              width: double.infinity,
              height: 250, // Adjust height as needed
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(widget.service.service_image), // Corrected
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryName ?? '...', // Show category name or a placeholder
                    style: TextStyle(fontSize: 16, color: const Color(0xFFF11414)),
                  ),
                  SizedBox(height: 10),
                  Text(
                    // widget.service.name,
                    widget.service.name,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    widget.service.description,
                    style: TextStyle(fontSize: 15),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
            // List of providers
            FutureBuilder<List<Provider>>(
              future: _futureProviders,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No providers found'));
                } else {
                  return ListView.builder(
                    shrinkWrap: true, // Ensure the list takes only required space
                    physics: NeverScrollableScrollPhysics(), // Disable scrolling for this list
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final provider = snapshot.data![index];
                      final isSelected = selectedProviderId == provider.id;

                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        leading: CircleAvatar(
                          backgroundImage: AssetImage("assets/images/provider_avatar.jpeg"),
                          radius: 30, // Adjust the size as needed
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              provider.fullname ?? 'Unknown',
                              style: TextStyle(
                                color: isSelected ? Colors.red : Colors.black, // Change text color to red if selected
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  provider.rating_avg.toStringAsFixed(1),
                                  style: TextStyle(fontWeight: FontWeight.w400),
                                ),
                                SizedBox(width: 4), // Space between text and icon
                                Icon(
                                  Icons.star, // Real star icon
                                  color: const Color.fromARGB(255, 255, 0, 0), // Star color
                                  size: 16, // Adjust size as needed
                                ),
                              ],
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Address: ${provider.address}'),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProviderDetailsPage(providerId: provider.id, service: widget.service),
                            ),
                          );
                        },
                      );
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 80,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 255, 255),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1), // Shadow color
              blurRadius: 10, // Softness of the shadow
              spreadRadius: 2, // Extent of the shadow
              offset: Offset(0, -2), // Shadow position, negative Y for shadow above
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between text and button
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Price: ${widget.service.price} DH",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceConfirmationPage( // Pass the selected provider ID
                      service: widget.service, Current_User : widget.Current_User, 
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 0, 0),
              ),
              child: Text("Request Now", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}