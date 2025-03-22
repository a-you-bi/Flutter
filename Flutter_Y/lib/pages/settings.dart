import 'package:easelink/pages/home.dart';
import 'package:easelink/pages/profile.dart';
import 'package:flutter/material.dart';


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(color: Colors.white),),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_outlined, color: const Color.fromARGB(255, 255, 255, 255)),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MyHomePage()),
            );
          },
        ),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: ListView(
        children: [
          buildSettingsItem(Icons.account_circle, 'Account',ProfilePage(), context, Colors.purple),
          // buildSettingsItem(Icons.notifications, 'Notifications',, context, Colors.red),
          // buildSettingsItem(Icons.lock, 'Privacy',, context, Colors.blue),
          // buildSettingsItem(Icons.chat, 'Chat Settings', context, Colors.green),
          // buildSettingsItem(Icons.menu_book, 'Learning Settings', context, Colors.orange),
          // buildSettingsItem(Icons.dark_mode, 'Dark Mode',, context, const Color.fromARGB(255, 71, 66, 66)),
          // buildSettingsItem(Icons.star, 'Rate ServiceLink',, context, Colors.yellow),
          // buildSettingsItem(Icons.info, 'About',, context, Colors.cyan),
          // buildSettingsItem(Icons.help, 'Help',, context, Colors.teal),
          // buildSettingsItem(Icons.cleaning_services, 'Clear cache',, context, Colors.brown, trailing: Text('5MB', style: TextStyle(color: Colors.white54))),
        ],
      ),
    );
  }

  Widget buildSettingsItem(IconData icon, String title,Widget page, BuildContext context, Color bgColor, {Widget? trailing}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: TextStyle(color: Colors.white)),
        trailing: trailing ?? Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
        onTap: () {
          // Navigate to the respective page based on the settings item clicked
          // Example:
          
            Navigator.push(context, MaterialPageRoute(builder: (context) => page));
          // Navigator.pushNamed(context, page); // Uncomment this line if you want to navigate to a named route instead of a page
        },
      ),
    );
  }
}
