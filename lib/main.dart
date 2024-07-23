import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
// import 'settings_page.dart';
// import 'add_contact_page.dart';
// import 'contacts_page.dart';
// import 'recent_calls_page.dart';
// import 'calling_page.dart';
// import 'incoming_call_page.dart';
// import 'incoming_call_locked_page.dart';



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DialPadScreen(),
      // routes: {
      //   '/settings': (context) => SettingsPage(),
      //   '/add_contact': (context) => AddContactPage(),
      //   '/contacts': (context) => ContactsPage(),
      //   '/recent_calls': (context) => RecentCallsPage(),
      //   '/calling': (context) => CallingPage(),
      //   '/incoming_call': (context) => IncomingCallPage(),
      //   '/incoming_call_locked': (context) => IncomingCallLockedPage()
      // },
      theme: ThemeData(scaffoldBackgroundColor: Colors.white),
    );
  }
}

class PermissionCheckScreen extends StatefulWidget {
  const PermissionCheckScreen({super.key});

  @override
  _PermissionCheckScreenState createState() => _PermissionCheckScreenState();
}

class _PermissionCheckScreenState extends State<PermissionCheckScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPermissionDialog();
    });
  }

  Future<void> _showPermissionDialog() async {
    bool granted = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('필수 권한 요청'),
        content: const Text('앱 사용 전 필수 권한들을 동의해야합니다.'),
        actions: [
          TextButton(
            child: const Text('확인'),
            onPressed: () async {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );

    if (granted) {
      await _requestPermissions();
    }
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.phone,
      Permission.contacts,
      Permission.camera,
      Permission.microphone,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (allGranted) {
      Navigator.pushReplacementNamed(context, '/dialpad');
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('권한 거부됨'),
          content: const Text('필수 권한을 모두 동의해야 앱을 사용할 수 있습니다.'),
          actions: [
            TextButton(
              child: const Text('종료'),
              onPressed: () {
                SystemNavigator.pop();
              },
            ),
          ],
        ),
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

class DialPadScreen extends StatefulWidget {
  const DialPadScreen({super.key});

  @override
  _DialPadScreenState createState() => _DialPadScreenState();
}

class _DialPadScreenState extends State<DialPadScreen> {
  final TextEditingController _controller = TextEditingController();

  void _onKeyPress(String value) {
  setState(() {
    String currentText = _controller.text.replaceAll('-', '');

    if (value == 'back') {
      if (currentText.isNotEmpty) {
        currentText = currentText.substring(0, currentText.length - 1);
      }
    } else {
      if (currentText.length >= 15) {
        // 최대 자릿수를 초과했음을 알리는 메시지를 표시합니다.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('최대 자릿수를 초과했습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
        return; // 더 이상 입력을 받지 않습니다.
      }
      currentText += value;
    }
    _controller.text = _formatPhoneNumber(currentText);
  });
}

  String _formatPhoneNumber(String number) {
    if (number.startsWith('010')) {
      if (number.length > 3 && number.length <= 7) {
        return '${number.substring(0, 3)}-${number.substring(3)}';
      } else if (number.length > 7) {
        return '${number.substring(0, 3)}-${number.substring(3, 7)}-${number.substring(7)}';
      }
    } else if (number.startsWith('02')) {
      if (number.length == 9) {
        return '${number.substring(0, 2)}-${number.substring(2, 5)}-${number.substring(5)}';
      } else if (number.length == 10) {
        return '${number.substring(0, 2)}-${number.substring(2, 6)}-${number.substring(6)}';
      } else if (number.length > 2 && number.length < 9) {
        return '${number.substring(0, 2)}-${number.substring(2)}';
      }
    } else {
      if (number.length > 3 && number.length <= 6) {
        return '${number.substring(0, 3)}-${number.substring(3)}';
      } else if (number.length > 6) {
        return '${number.substring(0, 3)}-${number.substring(3, 6)}-${number.substring(6)}';
      }
    }
    return number;
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _makeVideoCall(String phoneNumber) {
    // Video call functionality would go here, but it's highly dependent on the specific video call SDK being used.
    // For example, you might use a package like 'flutter_webrtc' or another video call solution.
    print('Making video call to $phoneNumber');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double dialPadFontSize = constraints.maxWidth * 0.04;
          double subTextFontSize = constraints.maxWidth * 0.03;
          return Column(
            children: [
              Expanded(
                flex: 2,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    child: Align(
                      alignment: Alignment.center,
                      child: TextField(
                        controller: _controller,
                        readOnly: true,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: dialPadFontSize),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: GridView.builder(
                  itemCount: 12,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.5,
                  ),
                  itemBuilder: (context, index) {
                    if (index < 9) {
                      return DialButton(
                        text: '${index + 1}',
                        subText: getDialButtonText(index + 1),
                        dialPadFontSize: dialPadFontSize,
                        subTextFontSize: subTextFontSize,
                        onPressed: () => _onKeyPress('${index + 1}'),
                      );
                    } else if (index == 9) {
                      return DialButton(
                        text: '*',
                        subText: '',
                        dialPadFontSize: dialPadFontSize,
                        subTextFontSize: subTextFontSize,
                        onPressed: () => _onKeyPress('*'),
                      );
                    } else if (index == 10) {
                      return DialButton(
                        text: '0',
                        subText: '+',
                        dialPadFontSize: dialPadFontSize,
                        subTextFontSize: subTextFontSize,
                        onPressed: () => _onKeyPress('0'),
                      );
                    } else {
                      return DialButton(
                        text: '#',
                        subText: '',
                        dialPadFontSize: dialPadFontSize,
                        subTextFontSize: subTextFontSize,
                        onPressed: () => _onKeyPress('#'),
                      );
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.video_call, size: constraints.maxWidth * 0.1),
                      onPressed: () {
                        _makeVideoCall(_controller.text);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.call, size: constraints.maxWidth * 0.1, color: Colors.green),
                      onPressed: () {
                        _makePhoneCall(_controller.text);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_back, size: constraints.maxWidth * 0.1),
                      onPressed: () => _onKeyPress('back'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Spacer(),
                    BottomIconButton(
                      icon: Icons.add,
                      label: '연락처 추가',
                      onPressed: () {
                        Navigator.pushNamed(context, '/add_contact');
                      },
                    ),
                    const Spacer(),
                    BottomIconButton(
                      icon: Icons.person,
                      label: '연락처',
                      onPressed: () {
                        Navigator.pushNamed(context, '/contacts');
                      },
                    ),
                    const Spacer(),
                    BottomIconButton(
                      icon: Icons.dialpad,
                      label: '키패드',
                      onPressed: () {},
                    ),
                    const Spacer(),
                    BottomIconButton(
                      icon: Icons.history,
                      label: '최근 기록',
                      onPressed: () {
                        Navigator.pushNamed(context, '/recent_calls');
                      },
                    ),
                    const Spacer(),
                    BottomIconButton(
                      icon: Icons.settings,
                      label: '설정',
                      onPressed: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String getDialButtonText(int number) {
    switch (number) {
      case 1:
        return ' ';
      case 2:
        return 'ABC';
      case 3:
        return 'DEF';
      case 4:
        return 'GHI';
      case 5:
        return 'JKL';
      case 6:
        return 'MNO';
      case 7:
        return 'PQRS';
      case 8:
        return 'TUV';
      case 9:
        return 'WXYZ';
      default:
        return '';
    }
  }
}

class DialButton extends StatelessWidget {
  final String text;
  final String subText;
  final double dialPadFontSize;
  final double subTextFontSize;
  final VoidCallback onPressed;

  const DialButton({super.key, 
    required this.text,
    required this.subText,
    required this.dialPadFontSize,
    required this.subTextFontSize,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            style: TextStyle(fontSize: dialPadFontSize, fontWeight: FontWeight.bold),
          ),
          Text(
            subText,
            style: TextStyle(fontSize: subTextFontSize, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class BottomIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const BottomIconButton({super.key, 
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}