import 'dart:convert';
import 'dart:io';
import 'package:curtaincall/page/utill.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'common_navigation_bar.dart'; // 통일된 하단 네비게이션 import
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _filteredContacts = [];
  String _searchText = '';
  String userPhoneNumber = "";  // 사용자 전화번호 (초기값 비움)
  final Map<String, bool> _switchStates = {};
  final Map<String, bool> _isEditing = {};
  final Map<String, TextEditingController> _nameControllers = {};
  final Map<String, TextEditingController> _phoneControllers = {};

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _loadUserPhoneNumber();
  }

  // SharedPreferences에서 저장된 전화번호 가져오기
  Future<void> _loadUserPhoneNumber() async {
    String? storedPhoneNumber = await _getStoredPhoneNumber();
    // storedPhoneNumber=toUrlNumber(storedPhoneNumber!);

    if (storedPhoneNumber != null) {
      setState(() {
        userPhoneNumber = storedPhoneNumber!;
      });
      // 번호를 가져온 후, 연락처 데이터를 가져오는 함수 호출
      _fetchPhoneBookProfileWithConnection();
    } else {
      print('저장된 전화번호가 없습니다.');
    }
  }
  Future<String> _getNativeFilePath() async {
    return '/data/data/com.example.curtaincall/files';
  }
  Future<String?> _getStoredPhoneNumber() async {
    try {
      final nativeDirectory = await _getNativeFilePath();
      final file = File(path.join(nativeDirectory, 'phone_number.txt'));
      // 파일이 존재하는지 확인하고, 파일이 있으면 내용을 읽음
      if (await file.exists()) {
        final phoneNumber = await file.readAsString();
        print('저장된 전화번호: $phoneNumber');
        return phoneNumber;
      } else {
        print("전화번호가 저장된 파일이 없습니다. 경로: ${file.path}");
        return null;
      }
    } catch (e) {
      print("파일 읽기 오류: $e");
      return null;
    }
  }

  Future<void> _requestPermissions() async {
    if (await Permission.contacts.request().isGranted) {
      // 권한이 허용된 경우 연락처 접근 가능
    } else {
      // 권한이 거부된 경우 사용자에게 알림
      print("Contacts permission denied");
    }
  }

  Future<void> _fetchPhoneBookProfileWithConnection() async {
    if (userPhoneNumber.isEmpty) return;  // 전화번호가 없으면 함수 종료

    userPhoneNumber=toUrlNumber(userPhoneNumber);
    final response = await http.get(Uri.parse('http://10.0.2.2:8080/main/user/phoneAddressBookInfo?phoneNumber=$userPhoneNumber'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> contactList = data["response"][userPhoneNumber];

      setState(() {
        for (var contact in contactList) {
          _contacts.add({
            "name": contact["name"],
            "phone": contact["phoneNumber"],
            "isCurtainCallOnAndOff": contact["isCurtainCallOnAndOff"],
          });
          _switchStates[contact["phoneNumber"]] = contact["isCurtainCallOnAndOff"];
          _isEditing[contact["phoneNumber"]] = false;
          _nameControllers[contact["phoneNumber"]] = TextEditingController(text: contact["name"]);
          _phoneControllers[contact["phoneNumber"]] = TextEditingController(text: contact["phoneNumber"]);

          // isCurtainCallOnAndOff가 true인 경우 이름 삭제
          if (contact["isCurtainCallOnAndOff"]) {
            _deleteContactName(contact["phoneNumber"]);
          }
        }
        _filteredContacts = _contacts;
      });

      // 서버로 연락처 데이터를 전송, 어셈블할때 주석 해제
      // await _sendContactsToBackend();

    } else {
      print('Failed to load user profile');
    }
  }

  Future<void> _sendContactsToBackend() async {
    final url = 'http://10.0.2.2:8080/main/user/phoneAddressBookInfo?';
    final Map<String, List<Map<String, dynamic>>> dataToSend = {
      userPhoneNumber: _contacts.map((contact) {
        return {
          'name': contact['name'],
          'phoneNumber': contact['phone'],
          'isCurtainCallOnAndOff': contact['isCurtainCallOnAndOff'] ?? false,
        };
      }).toList()
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(dataToSend),
      );

      // if (response.statusCode == 200) {
      //   print("연락처 데이터 전송 성공");
      // } else {
      //   print("연락처 데이터 전송 실패: ${response.statusCode}");
      // }
    } catch (e) {
      print("서버로 데이터 전송 중 오류 발생: $e");
    }
  }

  Future<void> _deleteContactName(String phoneNumber) async {
    try {
      if (await Permission.contacts.request().isGranted) {
        // 연락처를 가져옵니다.
        final contacts = await FlutterContacts.getContacts(withProperties: true);
        for (var contact in contacts) {
          if (contact.phones.isNotEmpty && contact.phones.first.number.replaceAll('-', '') == phoneNumber) {
            // 연락처 이름을 삭제합니다.
            contact.name.first = '';
            contact.name.last = '';
            await contact.update();
            print('연락처의 이름이 삭제되었습니다.');
            break;
          }
        }
      }
    } on PlatformException catch (e) {
      print('Failed to delete contact: ${e.message}');
    }
  }

  Future<void> _savePhoneBookProfileWithConnection(String prePhoneNumber, String newPhoneNumber) async {
    // 수정할 연락처 데이터를 JSON 형식으로 구성합니다.
    Map<String, dynamic> updatedContact = {
      "name": _nameControllers[prePhoneNumber]!.text,
      "phoneNumber": newPhoneNumber,
      "isCurtainCallOnAndOff": _switchStates[prePhoneNumber]
    };

    // 서버로 데이터를 PUT 요청으로 전송합니다.
    final response = await http.put(
      Uri.parse('http://10.0.2.2:8080/main/user/phoneAddressBookInfo?prePhoneNumber=$prePhoneNumber'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        userPhoneNumber: updatedContact,
      }),
    );

    if (response.statusCode == 200) {
      print('User profile updated successfully');
    } else {
      print('Failed to update user profile');
    }

    // 기존 정보를 새 정보로 업데이트
    setState(() {
      if (prePhoneNumber != newPhoneNumber) {
        _switchStates[newPhoneNumber] = _switchStates.remove(prePhoneNumber)!;
        _isEditing[newPhoneNumber] = _isEditing.remove(prePhoneNumber)!;
        _nameControllers[newPhoneNumber] = _nameControllers.remove(prePhoneNumber)!;
        _phoneControllers[newPhoneNumber] = _phoneControllers.remove(prePhoneNumber)!;

        for (var contact in _contacts) {
          if (contact["phone"] == prePhoneNumber) {
            contact["phone"] = newPhoneNumber;
            break;
          }
        }
      }
    });
  }

  void _filterContacts(String searchText) {
    setState(() {
      _searchText = searchText;
      _filteredContacts = _contacts.where((contact) {
        final name = contact['name']!.toLowerCase();
        final phone = contact['phone']!.replaceAll('-', '').toLowerCase();
        return name.contains(searchText.toLowerCase()) || phone.contains(searchText);
      }).toList();
    });
  }

  void _toggleSwitch(String phoneNumber, bool value) {
    setState(() {
      _switchStates[phoneNumber] = value;
      _savePhoneBookProfileWithConnection(phoneNumber, phoneNumber); // 스위치 상태 변경 시 API 호출
    });
  }

  void _toggleEditMode(String phoneNumber) {
    setState(() {
      _isEditing[phoneNumber] = !_isEditing[phoneNumber]!;
    });
  }

  void _saveEditedContact(String phoneNumber) {
    setState(() {
      final name = _nameControllers[phoneNumber]!.text;
      final newPhoneNumber = _phoneControllers[phoneNumber]!.text;

      for (var contact in _contacts) {
        if (contact['phone'] == phoneNumber) {
          contact['name'] = name;
          contact['phone'] = newPhoneNumber;
          break;
        }
      }

      if (newPhoneNumber != phoneNumber) {
        // 기존 전화번호를 새 전화번호로 업데이트
        _savePhoneBookProfileWithConnection(phoneNumber, newPhoneNumber);
      } else {
        _savePhoneBookProfileWithConnection(phoneNumber, phoneNumber);
      }

      _toggleEditMode(phoneNumber);
      _filteredContacts = _contacts;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double iconSize = screenSize.width * 0.15;
    final double listIconSize = screenSize.width * 0.07;
    final double padding = screenSize.width * 0.04;
    final double fontSize = screenSize.width * 0.04;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '연락처',
            style: TextStyle(color: Colors.black, fontSize: fontSize * 1.5),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          SizedBox(height: padding),
          Icon(Icons.contacts, size: iconSize),
          SizedBox(height: padding),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: TextField(
              decoration: InputDecoration(
                hintText: '이름 또는 전화번호 검색',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onChanged: (value) {
                _filterContacts(value);
              },
            ),
          ),
          SizedBox(height: padding),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32 * (screenSize.width / 375)),
                  topRight: Radius.circular(32 * (screenSize.width / 375)),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(0.0),
                padding: EdgeInsets.symmetric(vertical: padding, horizontal: padding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16 * (screenSize.width / 375)),
                ),
                child: ListView.separated(
                  itemCount: _filteredContacts.length,
                  separatorBuilder: (context, index) => Divider(
                    color: Colors.grey[300],
                    thickness: 1,
                  ),
                  itemBuilder: (context, index) {
                    final contact = _filteredContacts[index];
                    final phoneNumber = contact['phone']!;
                    final isSwitched = _switchStates[phoneNumber] ?? false;
                    final isEditing = _isEditing[phoneNumber] ?? false;

                    return ListTile(
                      title: isEditing
                          ? ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: screenSize.width * 0.5,
                        ),
                        child: TextField(
                          controller: _nameControllers[phoneNumber],
                          decoration: const InputDecoration(
                            hintText: '이름을 입력하세요',
                          ),
                          maxLines: 1,
                          style: const TextStyle(overflow: TextOverflow.ellipsis),
                        ),
                      )
                          : Text(contact['name']!, style: TextStyle(fontSize: fontSize)),
                      subtitle: isEditing
                          ? ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: screenSize.width * 0.5,
                        ),
                        child: TextField(
                          controller: _phoneControllers[phoneNumber],
                          decoration: const InputDecoration(
                            hintText: '전화번호를 입력하세요',
                          ),
                          maxLines: 1,
                          style: const TextStyle(overflow: TextOverflow.ellipsis),
                          keyboardType: TextInputType.phone,
                        ),
                      )
                          : Text(
                        phoneNumber,
                        style: TextStyle(
                          fontSize: fontSize,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                      ),
                      leading: Icon(Icons.person, size: listIconSize),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.scale(
                            scale: 0.75,
                            child: Switch(
                              value: isSwitched,
                              onChanged: (value) {
                                _toggleSwitch(phoneNumber, value);
                              },
                            ),
                          ),
                          IconButton(
                            icon: Icon(isEditing ? Icons.save : Icons.edit),
                            onPressed: () {
                              if (isEditing) {
                                _saveEditedContact(phoneNumber);
                              } else {
                                _toggleEditMode(phoneNumber);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CommonBottomNavigationBar(currentIndex: 0),
    );
  }
}
