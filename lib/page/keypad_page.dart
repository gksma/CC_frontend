import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }
  void _makeVideoCall(String phoneNumber) {
    print('Making video call to $phoneNumber');
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double dialPadFontSize = screenSize.width * 0.07; // 약간 키워서 빈 공간을 줄임
    final double subTextFontSize = screenSize.width * 0.03;
    final double iconButtonSize = screenSize.width * 0.12; // 아이콘 버튼 크기 조정
    final double gridSpacing = screenSize.width * 0.13; // 간격을 적당히 유지

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
                mainAxisSpacing: screenSize.height * 0.04, // 세로 간격을 적당히 넓게
                childAspectRatio: 1, // 정사각형 모양 유지
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
          Padding(
            padding: EdgeInsets.all(screenSize.width * 0.02),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Spacer(),
                BottomIconButton(
                  icon: Icons.add,
                  label: '연락처 추가',
                  onPressed: () {
                    Navigator.pushNamed(context, '/add_contact');
                  },
                ),
                Spacer(),
                BottomIconButton(
                  icon: Icons.person,
                  label: '연락처',
                  onPressed: () {
                    Navigator.pushNamed(context, '/contacts');
                  },
                ),
                Spacer(),
                BottomIconButton(
                  icon: Icons.dialpad,
                  label: '키패드',
                  onPressed: () {},
                ),
                Spacer(),
                BottomIconButton(
                  icon: Icons.history,
                  label: '최근 기록',
                  onPressed: () {
                    Navigator.pushNamed(context, '/recent_calls');
                  },
                ),
                Spacer(),
                BottomIconButton(
                  icon: Icons.settings,
                  label: '설정',
                  onPressed: () {
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
                Spacer(),
              ],
            ),
          ),
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

class BottomIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const BottomIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final double fontSize = MediaQuery.of(context).size.width * 0.025;
    final double iconSize = MediaQuery.of(context).size.width * 0.06;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, size: iconSize),
          onPressed: onPressed,
        ),
        Text(
          label,
          style: TextStyle(fontSize: fontSize),
        ),
      ],
    );
  }
}
