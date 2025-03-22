import 'package:easelink/classes/providers.dart';
import 'package:flutter/material.dart';
import 'package:easelink/classes/service.dart';

class ProviderDetailsPage extends StatefulWidget {
  final int providerId;
  final Service service;

  const ProviderDetailsPage({super.key, required this.providerId, required this.service});

  @override
  _ProviderDetailsPageState createState() => _ProviderDetailsPageState();
}

class _ProviderDetailsPageState extends State<ProviderDetailsPage> {
  Provider? _provider;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProviderDetails();
  }

  Future<void> _fetchProviderDetails() async {
    try {
      final provider = await getProviderById(context, widget.providerId);
      setState(() {
        _provider = provider;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load provider details: $e')),
      );
      print('Failed to load provider details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Service Provider'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              // Navigate to edit provider page
            },
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _provider == null
              ? Center(child: Text('Provider not found'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Container(
                      padding: EdgeInsets.all(16.0),
                      color: const Color.fromARGB(255, 255, 255, 255),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: AssetImage("assets/images/provider_avatar.jpeg"),
                            radius: 50,
                          ),
                          SizedBox(width: 30),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _provider!.fullname ?? "N/A",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w300,
                                  color: const Color.fromARGB(255, 0, 0, 0),
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                widget.service.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: const Color.fromARGB(255, 92, 86, 86),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                _provider!.address,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: const Color.fromARGB(255, 92, 86, 86),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Stats Section
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('7,500+', 'Customer', Icons.people),
                          _buildStatItem('10+', 'Years Exp.', Icons.work),
                          _buildStatItem('${_provider!.rating_avg}', 'Rating', Icons.star),
                          _buildStatItem('4,956', 'Review', Icons.comment),
                        ],
                      ),
                    ),

                    // Tabs Section (Takes the rest of the screen)
                    Expanded(
                      child: DefaultTabController(
                        length: 4,
                        child: Column(
                          children: [
                            TabBar(
                              labelColor: const Color.fromARGB(255, 0, 0, 0),
                              unselectedLabelColor: Colors.grey,
                              tabs: [
                                Tab(text: 'Services'),
                                Tab(text: 'About'),
                                Tab(text: 'Gallery'),
                                Tab(text: 'Review'),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  // Services Tab
                                  _buildServicesTab(),

                                  // About Tab
                                  _buildAboutTab(),

                                  // Gallery Tab
                                  Center(child: Text("Nothing"),),

                                  // Review Tab
                                  _buildReviewTab(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 30,
          color: const Color.fromARGB(187, 255, 0, 0),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildServicesTab() {
    return ListView(
      padding: EdgeInsets.all(16.0),
      children: [
        Text(
          'Available Services',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        _buildServiceItem('Cleaning Service', Icons.cleaning_services),
        _buildServiceItem('Plumbing', Icons.plumbing),
        _buildServiceItem('Electrical', Icons.electrical_services),
        _buildServiceItem('Carpentry', Icons.carpenter),
      ],
    );
  }

  Widget _buildServiceItem(String serviceName, IconData icon) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          serviceName,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
        onTap: () {
          // Navigate to service details
        },
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About ${_provider!.fullname ?? "N/A"}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Experience: 10+ years',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Specialization: Cleaning Services',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildGalleryTab() {
  //   return GridView.count(
  //     padding: EdgeInsets.all(16.0),
  //     crossAxisCount: 2,
  //     crossAxisSpacing: 10,
  //     mainAxisSpacing: 10,
  //     children: [
  //       _buildGalleryItem('assets/images/gallery1.jpg'),
  //       _buildGalleryItem('assets/images/gallery2.jpg'),
  //       _buildGalleryItem('assets/images/gallery3.jpg'),
  //       _buildGalleryItem('assets/images/gallery4.jpg'),
  //     ],
  //   );
  // }

  // Widget _buildGalleryItem(String imagePath) {
  //   return ClipRRect(
  //     borderRadius: BorderRadius.circular(8.0),
  //     child: Image.asset(
  //       imagePath,
  //       fit: BoxFit.cover,
  //     ),
  //   );
  // }

  Widget _buildReviewTab() {
    return ListView(
      padding: EdgeInsets.all(16.0),
      children: [
        _buildReviewItem('John Doe', 'Great service! Highly recommended.', 5),
        _buildReviewItem('Jane Smith', 'Very professional and efficient.', 4),
        _buildReviewItem('Alice Johnson', 'Good work, but a bit expensive.', 3),
      ],
    );
  }

  Widget _buildReviewItem(String reviewerName, String review, int rating) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reviewerName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              review,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: const Color.fromARGB(255, 255, 0, 0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}