import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart'; // 추가된 import
import 'package:http/http.dart' as http;
import 'package:flutter_contacts/flutter_contacts.dart';
import 'token_util.dart';

import 'keypad_page.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  _IntroPageState createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();

  bool _showVerificationField = false;
  bool _isLoading = false;
  bool _isUser = false;
  int _remainingTime = 0; // 남은 시간(초)
  bool _isDisposed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _checkIfUser();
    });
  }

  // 카운트다운 시작 함수
  void _startCountdown() {
    setState(() {
      _remainingTime = 180; // 3분 = 180초
    });

    _timer?.cancel(); // 기존 타이머가 있으면 취소
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed) {
        _timer?.cancel(); // 언마운트된 상태면 타이머 취소
        return;
      }
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  // 사용자인지 확인하는 API 호출
  Future<void> _checkIfUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? bearerToken = await getBearerTokenFromFile();

      if (bearerToken == null || bearerToken.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('저장된 토큰이 없습니다. 로그인하세요.'),
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final url = Uri.parse('http://10.0.2.2:8080/authorization/configUser');
      final response = await http.get(
        url,
        headers: {
          'authorization': bearerToken,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody == true) {
          setState(() {
            _isUser = true;
          });

          // Navigator 호출 전에 mounted 확인
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const KeypadPage()),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('사용자 인증을 해주세요!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() {
          _isUser = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('네트워크 오류가 발생했습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 사용자 이름을 내부 저장소에 저장
  Future<void> _saveUserNameToFile(String userName) async {
    try {
      final directory = await getApplicationDocumentsDirectory(); // 경로 수정
      final file = File(path.join(directory.path, 'user_name.txt'));
      await file.writeAsString(userName);
      print("사용자 이름이 파일에 저장되었습니다. 경로: ${file.path}");
    } catch (e) {
      print("파일 저장 오류: $e");
    }
  }

  // 저장된 사용자 이름 가져오기
  Future<String?> _getStoredUserName() async {
    try {
      final directory = await getApplicationDocumentsDirectory(); // 경로 수정
      final file = File(path.join(directory.path, 'user_name.txt'));
      // 파일이 존재하는지 확인하고, 파일이 있으면 내용을 읽음
      if (await file.exists()) {
        final userName = await file.readAsString();
        print('저장된 사용자 이름: $userName');
        return userName;
      } else {
        print("사용자 이름이 저장된 파일이 없습니다. 경로: ${file.path}");
        return null;
      }
    } catch (e) {
      print("파일 읽기 오류: $e");
      return null;
    }
  }

  // 인증번호 발송 함수
  Future<void> _sendVerificationCode(String phoneNumber) async {
    final url = Uri.parse('http://10.0.2.2:8080/authorization/send-one');

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "phoneNumber": phoneNumber,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('인증번호가 전송되었습니다.')),
        );
        setState(() {
          _showVerificationField = true;
        });
        _startCountdown();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('인증번호 전송에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 인증번호 확인 함수
  Future<void> _verifyCode(String phoneNumber, String verificationCode) async {
    final url = Uri.parse('http://10.0.2.2:8080/authorization/configNumber?configNumber=$verificationCode');

    if (_isDisposed) return; // dispose 상태면 실행 중단

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "phoneNumber": phoneNumber,
        }),
      );

      if (response.statusCode == 200 && response.body == "true") {
        await _saveUserInfo();
        await _savePhoneBookInfo();

        if (_isDisposed) return; // dispose 상태면 실행 중단
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('인증이 완료되었습니다.')),
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const KeypadPage()),
          );
        }
      } else {
        if (_isDisposed) return; // dispose 상태면 실행 중단
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('인증번호가 일치하지 않습니다.')),
        );
      }
    } catch (e) {
      if (_isDisposed) return; // dispose 상태면 실행 중단
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
      );
    } finally {
      if (_isDisposed) return; // dispose 상태면 실행 중단
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _saveUserInfo() async {
    final url = Uri.parse('http://10.0.2.2:8080/main/user');

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "phoneNumber": _phoneController.text,
          "nickName": _nameController.text,
          "isCurtainCall": false,
        }),
      );

      if (response.statusCode == 200) {
        final token = response.headers['authorization'];
        if (token != null) {
          await saveBearerTokenToFile(token); // Bearer 토큰을 파일에 저장
          await _saveUserNameToFile(_nameController.text);
          await savePhoneNumberToFile(_phoneController.text); // 전화번호 저장 추가

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('사용자 정보가 성공적으로 저장되었습니다.')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const KeypadPage()),
          );
        } else {
          print('authorization 헤더에 토큰이 없습니다.');
        }
      } else {
        print('Failed to save user information. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 인증번호 재발급 함수
  void _resendVerificationCode() {
    _sendVerificationCode(_phoneController.text);
  }

  // 카운트다운을 시간 형식으로 변환
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel(); // 타이머 정리
    _isDisposed = true; // 언마운트 상태로 설정
    super.dispose();
  }


  // 전화번호부 정보를 저장하는 API 호출 (로컬 연락처 가져오기)
  Future<void> _savePhoneBookInfo() async {
    final url = Uri.parse('http://10.0.2.2:8080/main/user/phoneAddressBookInfo');

    // 연락처 권한 요청
    if (await FlutterContacts.requestPermission()) {
      // 로컬 연락처 가져오기
      List<Contact> contacts = await FlutterContacts.getContacts(withProperties: true);

      // API 프로토콜에 맞게 전화번호부 데이터를 구성
      final Map<String, List<Map<String, dynamic>>> phoneBookData = {
        _phoneController.text: contacts.map((contact) {
          return {
            "name": contact.displayName, // 이름
            "phoneNumber": contact.phones.isNotEmpty ? contact.phones.first.number : '', // 전화번호
            "isCurtainCallOnAndOff": false // 기본값 설정
          };
        }).toList()
      };

      // POST 요청을 통해 데이터를 서버로 전송
      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode(phoneBookData),
        );

        if (response.statusCode == 200) {
          print('Phone book information saved successfully');
        } else {
          print('Failed to save phone book information: ${response.statusCode}');
        }
      } catch (e) {
        print('Error saving phone book information: $e');
      }
    } else {
      print('Contacts permission denied');
    }
  }

  void _saveContact() {
    final String name = _nameController.text;
    final String phoneNumber = _phoneController.text;

    if (name.isNotEmpty && phoneNumber.isNotEmpty) {
      _sendVerificationCode(phoneNumber);
    } else {
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
            '내 정보 인증',
            style: TextStyle(color: Colors.black, fontSize: fontSize * 1.2),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                            const Divider(height: 16.0, thickness: 1),
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
                            if (_showVerificationField)
                              Column(
                                children: [
                                  const Divider(height: 16.0, thickness: 1),
                                  Row(
                                    children: [
                                      Text(
                                        '인증번호 >',
                                        style: TextStyle(
                                          fontSize: fontSize,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: _verificationCodeController,
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(vertical: 5),
                                          ),
                                          style: TextStyle(fontSize: fontSize),
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // 인증번호 입력칸 오른쪽에 카운트다운 표시
                                      if (_remainingTime > 0)
                                        Text(
                                          _formatTime(_remainingTime),
                                          style: TextStyle(fontSize: fontSize, color: Colors.red),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8.0),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: padding), // 아래쪽 여백 추가
                    // 재인증 버튼
                    if (_showVerificationField)
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: _resendVerificationCode,
                          child: Text('재인증', style: TextStyle(fontSize: fontSize)),
                        ),
                      ),
                    SizedBox(height: padding), // 여백 추가
                    SizedBox(
                      width: double.infinity,
                      height: buttonHeight,
                      child: ElevatedButton(
                        onPressed: _showVerificationField
                            ? () => _verifyCode(
                                  _phoneController.text,
                                  _verificationCodeController.text,
                                )
                            : _saveContact,
                        child: Text(_showVerificationField ? '확인' : '인증', style: TextStyle(fontSize: fontSize)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}