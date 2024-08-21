import 'package:flutter/material.dart';
import 'page/keypad_page.dart';
import 'page/settings_page.dart';
import 'page/add_contact_page.dart';
import 'page/contacts_page.dart';
import 'page/recent_calls_page.dart';
import 'page/user_edit_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => const KeypadPage(),
        '/settings': (context) => const SettingsPage(),
        '/add_contact': (context) => const AddContactPage(),
        '/contacts': (context) => ContactsPage(),
        '/recent_calls': (context) => const RecentCallsPage(),
        '/user_edit': (context) => const UserEditPage(),
      },
      theme: ThemeData(scaffoldBackgroundColor: Colors.white),
    );
  }
}
