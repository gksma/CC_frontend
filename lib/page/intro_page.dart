import 'package:flutter/material.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  _IntroPageState createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  void _saveContact() {
    final String name = _nameController.text;
    final String phoneNumber = _phoneController.text;

    if (name.isNotEmpty && phoneNumber.isNotEmpty) {
      // 저장 로직 추가
      print('Contact saved: $name, $phoneNumber');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('저장이 완료되었습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    } else {
      // 입력 값이 비어있는 경우 에러 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이름과 전화번호를 입력하세요.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _onPhoneChanged(String value) {
    String formattedNumber = _formatPhoneNumber(value.replaceAll('-', ''));
    _phoneController.value = TextEditingValue(
      text: formattedNumber,
      selection: TextSelection.collapsed(offset: formattedNumber.length),
    );
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double padding = screenSize.width * 0.04;
    final double margin = screenSize.width * 0.02;
    final double iconSize = screenSize.width * 0.15;
    final double fontSize = screenSize.width * 0.045; // 글꼴 크기 조정
    final double buttonHeight = screenSize.height * 0.07;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '내 정보 편집',
            style: TextStyle(color: Colors.black, fontSize: fontSize * 1.2),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            children: [
              SizedBox(height: padding),
              Icon(Icons.person_add, size: iconSize),
              SizedBox(height: padding),
              Container(
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: padding, horizontal: margin),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            '이름 >',
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 5),
                              ),
                              style: TextStyle(fontSize: fontSize),
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 16.0, thickness: 1), // Divider 크기 조정
                      Row(
                        children: [
                          Text(
                            '전화번호 >',
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 5),
                              ),
                              style: TextStyle(fontSize: fontSize),
                              keyboardType: TextInputType.phone,
                              onChanged: _onPhoneChanged,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                    ],
                  ),
                ),
              ),
              SizedBox(height: padding), // 아래쪽 여백 추가
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: _saveContact,
                  child: Text('저장', style: TextStyle(fontSize: fontSize)),
                ),
              ),
            ],
          ),
        ),
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
    final double iconSize = MediaQuery.of(context).size.width * 0.06;
    final double fontSize = MediaQuery.of(context).size.width * 0.03;

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
