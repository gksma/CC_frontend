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
          double dialPadFontSize = constraints.maxWidth * 0.06;
          double subTextFontSize = constraints.maxWidth * 0.03;
          double iconButtonSize = constraints.maxWidth * 0.1;
          double gridSpacing = constraints.maxWidth * 0.17;

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
                  padding: EdgeInsets.symmetric(horizontal: gridSpacing),
                  itemCount: 12,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: gridSpacing,
                    mainAxisSpacing: gridSpacing,
                    childAspectRatio: (constraints.maxWidth / constraints.maxHeight) * 1.5,
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
