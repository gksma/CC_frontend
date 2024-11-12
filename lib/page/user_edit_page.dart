import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

import 'token_util.dart';

class UserEditPage extends StatefulWidget {
  const UserEditPage({super.key});

  @override
  _UserEditPageState createState() => _UserEditPageState();
}

class _UserEditPageState extends State<UserEditPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();

  bool _isPhoneNumberEditable = false;
  bool _showVerificationCodeField = false;
  bool _isLoading = false;
  int _remainingTime = 0;
  Timer? _timer;
  String _userName = "";
  String _userPhone = "";

  @override
  void initState() {
    super.initState();
    _fetchUserProfileWithConnection();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Dispose에서 타이머 해제
    super.dispose();
  }

  Future<void> _fetchUserProfileWithConnection() async {
    String? bearerToken = await getBearerTokenFromFile();

    if (bearerToken == null || bearerToken.isEmpty) {
      print("Bearer 토큰이 없습니다.");
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/main/user'),
        headers: {
          'authorization': bearerToken,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _userName = data['nickName'];
            _userPhone = data['phoneNumber'];
            _nameController.text = _userName;
            _phoneController.text = _userPhone;
          });
        }
      } else {
        print('Failed to load user profile. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> _sendVerificationCode(String phoneNumber) async {
    final url = Uri.parse('http://10.0.2.2:8080/authorization/send-one');
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"phoneNumber": phoneNumber}),
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: '인증번호가 전송되었습니다.');
        setState(() {
          _showVerificationCodeField = true;
        });
        _startCountdown();
      } else {
        Fluttertoast.showToast(msg: '인증번호 전송 실패. 다시 시도해주세요.');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '네트워크 오류가 발생했습니다.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 전화번호 인증 후 설정 페이지로 이동하는 함수
  Future<void> _verifyCodeAndSave(String phoneNumber, String verificationCode) async {
    final url = Uri.parse('http://10.0.2.2:8080/authorization/configNumber?configNumber=$verificationCode');
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"phoneNumber": phoneNumber}),
      );

      if (response.statusCode == 200 && response.body == "true") {
        await _saveUserProfile();
        Fluttertoast.showToast(msg: '정상적으로 저장되었습니다.');
        Navigator.pushReplacementNamed(context, '/settings'); // 설정 페이지로 이동
      } else {
        Fluttertoast.showToast(msg: '인증번호가 일치하지 않습니다.');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '네트워크 오류가 발생했습니다.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startCountdown() {
    setState(() {
      _remainingTime = 180;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _saveUserProfile() async {
    final url = Uri.parse('http://10.0.2.2:8080/main/user');
    final String name = _nameController.text;
    final String phoneNumber = _phoneController.text;

    String? bearerToken = await getBearerTokenFromFile();

    final body = json.encode({
      "phoneNumber": phoneNumber,
      "nickName": name,
      "isCurtainCall": false,
    });

    try {
      final response = await http.put(
        url,
        headers: {
          'authorization': bearerToken ?? '',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode != 200) {
        print('Failed to update user profile. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      Fluttertoast.showToast(msg: '네트워크 오류가 발생했습니다.');
    }
  }

  Future<bool> _onWillPop() async {
    if (_isPhoneNumberEditable) {
      bool result = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('확인'),
            content: const Text('전화번호 편집을 취소하시겠습니까?'),
            actions: [
              TextButton(
                child: const Text('아니오'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text('예'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );
      return result ?? false;
    }
    return true;
  }

  void _enablePhoneNumberEditing() {
    setState(() {
      _isPhoneNumberEditable = true;
      _showVerificationCodeField = false;
    });
  }

  void _onPhoneChanged(String value) {
    String formattedNumber = _formatPhoneNumber(value.replaceAll('-', ''));
    _phoneController.value = TextEditingValue(
      text: formattedNumber,
      selection: TextSelection.collapsed(offset: formattedNumber.length),
    );
  }

  String _formatPhoneNumber(String number) {
    return number;
  }

  // 이름 저장 후 설정 페이지로 이동하는 함수
  Future<void> _saveNameOnly() async {
    final String name = _nameController.text;

    if (name.isNotEmpty) {
      await _saveUserProfile(); // 이름만 저장하는 함수 호출
      Fluttertoast.showToast(msg: '이름이 저장되었습니다.');
      Navigator.pushReplacementNamed(context, '/settings'); // 설정 페이지로 이동
    } else {
      Fluttertoast.showToast(msg: '이름을 입력하세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double padding = screenSize.width * 0.04;
    final double buttonHeight = screenSize.height * 0.07;

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 정보 편집'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_isPhoneNumberEditable) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('확인'),
                    content: const Text('전화번호 편집을 취소하시겠습니까?'),
                    actions: [
                      TextButton(
                        child: const Text('아니오'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      TextButton(
                        child: const Text('예'),
                        onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                      ),
                    ],
                  );
                },
              );
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: '이름', hintText: _userName),
              ),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: '전화번호',
                  hintText: _userPhone,
                  enabled: _isPhoneNumberEditable,
                  filled: !_isPhoneNumberEditable,
                  fillColor: Colors.grey[200],
                ),
                onChanged: _onPhoneChanged,
              ),
              if (!_isPhoneNumberEditable) ...[
                SizedBox(
                  width: double.infinity,
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: _enablePhoneNumberEditing,
                    child: const Text('전화번호 편집'),
                  ),
                ),
                const SizedBox(height: 5), // 간격 추가
                SizedBox(
                  width: double.infinity,
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: _saveNameOnly, // 이름만 저장하는 함수 호출
                    child: const Text('저장'),
                  ),
                ),
              ],
              if (_isPhoneNumberEditable)
                Column(
                  children: [
                    if (_showVerificationCodeField)
                      Column(
                        children: [
                          TextField(
                            controller: _verificationCodeController,
                            decoration: const InputDecoration(labelText: '인증번호'),
                          ),
                          if (_remainingTime > 0)
                            Text(
                              '남은 시간: ${(_remainingTime ~/ 60).toString().padLeft(2, '0')}:${(_remainingTime % 60).toString().padLeft(2, '0')}',
                            ),
                        ],
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: buttonHeight,
                      child: ElevatedButton(
                        onPressed: () => _sendVerificationCode(_phoneController.text),
                        child: Text(_showVerificationCodeField ? '재인증' : '인증번호 전송'),
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (_showVerificationCodeField)
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: () => _verifyCodeAndSave(_phoneController.text, _verificationCodeController.text),
                          child: const Text('인증'),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}