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

  String _userName = "";
  String _userPhone = "";

  @override
  void initState() {
    super.initState();
    _fetchUserProfileWithConnection();
  }

  @override
  void dispose() {
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
            Navigator.of(context).pop();
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
                  enabled: false, // 전화번호 수정 비활성화
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              const SizedBox(height: 20), // 버튼과 입력 필드 간격 추가
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: _saveNameOnly, // 이름만 저장하는 함수 호출
                  child: const Text('저장'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}