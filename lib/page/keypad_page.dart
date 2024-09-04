import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'common_navigation_bar.dart';  // 통일된 하단 네비게이션 import
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

class KeypadPage extends StatefulWidget {
  const KeypadPage({super.key});

  @override
  _KeypadPageState createState() => _KeypadPageState();
}

class _KeypadPageState extends State<KeypadPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.phone,
      Permission.contacts,
      Permission.camera,
      Permission.microphone,
    ].request();
  }

  void _onKeyPress(String value) {
    setState(() {
      String currentText = _controller.text.replaceAll('-', '');

      if (value == 'back') {
        if (currentText.isNotEmpty) {
          currentText = currentText.substring(0, currentText.length - 1);
        }
      } else {
        if (currentText.length >= 15) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('최대 자릿수를 초과했습니다.'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
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
    // await requestPhonePermission();  // 권한 요청
    bool? res = await FlutterPhoneDirectCaller.callNumber(phoneNumber);
    if (res == null || !res) {
      throw 'Could not make the call to $phoneNumber';
    }
  }

  void _makeVideoCall(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);  // 혹은 video call URI 스킴
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }



  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double dialPadFontSize = screenSize.width * 0.07;
    final double subTextFontSize = screenSize.width * 0.03;
    final double iconButtonSize = screenSize.width * 0.12;
    final double gridSpacing = screenSize.width * 0.13;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        toolbarHeight: 0,
      ),

      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: screenSize.width * 0.05, horizontal: screenSize.width * 0.05),
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
              padding: EdgeInsets.symmetric(horizontal: gridSpacing, vertical: screenSize.height * 0.02),
              itemCount: 12,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: gridSpacing,
                mainAxisSpacing: screenSize.height * 0.04,
                childAspectRatio: 1,
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
            padding: EdgeInsets.all(screenSize.width * 0.04),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.video_call, size: iconButtonSize),
                  onPressed: () {
                    _makeVideoCall(_controller.text);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.call, size: iconButtonSize, color: Colors.green),
                  onPressed: () {
                    _makePhoneCall(_controller.text);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.arrow_back, size: iconButtonSize),
                  onPressed: () => _onKeyPress('back'),
                ),
              ],
            ),
          ),
          const CommonBottomNavigationBar(currentIndex: 1), // 키패드 페이지가 선택된 상태로 설정
        ],
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

  const DialButton({
    super.key,
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