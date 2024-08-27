import 'package:curtaincall/global/user_info.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'page/keypad_page.dart';
import 'page/settings_page.dart';
import 'page/add_contact_page.dart';
import 'page/contacts_page.dart';
import 'page/recent_calls_page.dart';
import 'page/user_edit_page.dart';
import 'page/intro_page.dart';

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
        // '/add_contact': (context) => const AddContactPage(),
        '/contacts': (context) => ContactsPage(),

        '/recent_calls': (context) => const RecentCallsPage(),
        '/user_edit': (context) =>  const UserEditPage(),
        '/intro': (context) => const IntroPage()
      },
      theme: ThemeData(scaffoldBackgroundColor: Colors.white),
    );
  }
}

class AppStart extends StatefulWidget {
  @override
  _AppStartState createState() => _AppStartState();
}

class _AppStartState extends State<AppStart> {
  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  // 앱 첫 실행 여부 체크
  Future<void> _checkFirstLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    if (isFirstLaunch) {
      // 첫 실행이면 false로 변경하고, IntroPage로 이동
      await prefs.setBool('isFirstLaunch', false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => IntroPage()),
      );
    } else {
      // 이후 실행시 바로 MainPage로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const KeypadPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}