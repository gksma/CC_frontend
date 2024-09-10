import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'common_navigation_bar.dart'; // 통일된 하단 네비게이션 import
import 'utill.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _filteredContacts = [];
  String _searchText = '';
  String userPhoneNumber = ""; // 사용자 전화번호 (초기값 비움)
  final Map<String, bool> _switchStates = {};
  final Map<String, bool> _isEditing = {}; // 연락처 편집 상태 저장
  final Map<String, TextEditingController> _nameControllers = {};
  final Map<String, TextEditingController> _phoneControllers = {};

  @override
  void initState() {
    super.initState();
    _loadUserPhoneNumber();
  }

  // 로컬에서 전화번호를 로드하고 백엔드로 연락처를 전송한 뒤, 백엔드에서 연락처 정보를 가져와서 표시
  Future<void> _loadUserPhoneNumber() async {
    String? storedPhoneNumber = await _getStoredPhoneNumber();

    if (storedPhoneNumber != null) {
      setState(() {
        userPhoneNumber = toUrlNumber(storedPhoneNumber); // + 제거
      });
      // 로컬 연락처를 가져와 백엔드로 전송
      await _fetchLocalContactsAndSendToBackend();
      // 백엔드에서 연락처 정보를 가져와 화면에 표시
      _fetchContactsFromBackend();
    } else {
      print('저장된 전화번호가 없습니다.');
    }
  }

  // 로컬에서 저장된 전화번호 가져오기
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

  // 로컬 파일 경로 반환 함수
  Future<String> _getNativeFilePath() async {
    return '/data/data/com.example.curtaincall/files';
  }

  // DB에서 이미 저장된 연락처 가져오기
  Future<List<Map<String, dynamic>>> _fetchContactsFromDB() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/main/user/phoneAddressBookInfo?phoneNumber=$userPhoneNumber'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data["response"] != null && data["response"][userPhoneNumber] != null) {
        final List<dynamic> contactList = data["response"][userPhoneNumber];
        return contactList.map((contact) {
          return {
            "name": contact["name"],
            "phone": contact["phoneNumber"],
            "isCurtainCallOnAndOff": contact["isCurtainCallOnAndOff"],
          };
        }).toList();
      }
    }
    return [];
  }

  // 로컬 연락처 가져오기 -> 중복된 연락처 제외 후 백엔드로 전송
  Future<void> _fetchLocalContactsAndSendToBackend() async {
    try {
      if (await Permission.contacts.request().isGranted) {
        final contacts = await FlutterContacts.getContacts(withProperties: true, withAccounts: true);

        if (contacts.isEmpty) {
          print("로컬 연락처가 비어 있습니다.");
        } else {
          print("로컬에서 ${contacts.length}개의 연락처를 불러왔습니다.");

          // 1. DB에서 이미 저장된 연락처 가져오기
          final dbContacts = await _fetchContactsFromDB();
          final dbPhoneNumbers = dbContacts.map((c) => c['phone']).toSet(); // DB에 있는 전화번호 목록

          // 2. 로컬 연락처 중 DB에 없는 연락처만 필터링
          final newContacts = contacts.where((contact) {
            final phoneNumber = contact.phones.isNotEmpty ? contact.phones.first.number : "";
            return !dbPhoneNumbers.contains(phoneNumber); // DB에 없는 번호만 필터링
          }).toList();

          // 3. 중복되지 않는 연락처만 서버로 전송
          if (newContacts.isNotEmpty) {
            await _sendContactsToBackend(newContacts);
          } else {
            print("새로운 연락처가 없습니다.");
          }
        }
      }
    } catch (e) {
      print("연락처를 불러오는 중 오류 발생: $e");
    }
  }

  // 서버로 로컬 연락처를 전송하는 함수 (중복 제거 후 새로운 연락처만 전송)
  Future<void> _sendContactsToBackend(List<Contact> contacts) async {
    final url = 'http://10.0.2.2:8080/main/user/phoneAddressBookInfo';
    final Map<String, List<Map<String, dynamic>>> dataToSend = {
      userPhoneNumber: contacts.map((contact) {
        return {
          'name': contact.displayName,
          'phoneNumber': contact.phones.isNotEmpty ? contact.phones.first.number : "",
          'isCurtainCallOnAndOff': false, // 기본값 설정
        };
      }).toList(),
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(dataToSend),
      );

      if (response.statusCode == 200) {
        print("로컬 연락처를 서버로 전송 완료");
      } else {
        print("연락처 전송 실패: ${response.statusCode}");
      }
    } catch (e) {
      print("서버로 연락처 전송 중 오류 발생: $e");
    }
  }

  // 서버에서 연락처 정보 가져오기 (백엔드에서 가져와 화면에 표시)
  Future<void> _fetchContactsFromBackend() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/main/user/phoneAddressBookInfo?phoneNumber=$userPhoneNumber'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data["response"] != null && data["response"][userPhoneNumber] != null) {
        final List<dynamic> contactList = data["response"][userPhoneNumber];

        setState(() {
          _contacts.clear();
          for (var contact in contactList) {
            _contacts.add({
              "name": contact["name"],
              "phone": contact["phoneNumber"],
              "isCurtainCallOnAndOff": contact["isCurtainCallOnAndOff"],
            });
            _switchStates[contact["phoneNumber"]] = contact["isCurtainCallOnAndOff"];
            _nameControllers[contact["phoneNumber"]] = TextEditingController(text: contact["name"]);
            _phoneControllers[contact["phoneNumber"]] = TextEditingController(text: contact["phoneNumber"]);
          }
          _filteredContacts = _contacts;
        });
      } else {
        print('해당 전화번호에 대한 연락처 데이터가 없습니다.');
      }
    } else {
      print('Failed to load contacts from backend');
    }
  }

  // 로컬 연락처에서 이름 삭제
  Future<void> _deleteLocalContactName(String phoneNumber) async {
    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true, 
        withPhoto: true, 
        withAccounts: true,
      );

      for (var contact in contacts) {
        if (contact.phones.isNotEmpty && contact.phones.first.number == phoneNumber) {
          contact.name.first = '';
          contact.name.last = '';
          await contact.update();
          print('로컬 연락처에서 이름이 삭제되었습니다.');
          break;
        }
      }
    } catch (e) {
      print("로컬 연락처 이름 삭제 중 오류 발생: $e");
    }
  }

  // 서버에서 이름 복원
  void _restoreContactNameFromBackend(String phoneNumber) async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/main/user/phoneAddressBookInfo?phoneNumber=$userPhoneNumber'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("백엔드로부터 가져온 데이터: $data");

        if (data != null && data["response"] != null) {
          final List<dynamic> contactList = data["response"][userPhoneNumber];
          for (var contact in contactList) {
            if (contact["phoneNumber"] == phoneNumber) {
              final restoredName = contact["name"];

              setState(() {
                _nameControllers[phoneNumber]?.text = restoredName;
              });

              final contacts = await FlutterContacts.getContacts(
                withProperties: true,
                withAccounts: true, 
                withPhoto: true,
              );
              for (var contact in contacts) {
                if (contact.phones.isNotEmpty && contact.phones.first.number == phoneNumber) {
                  contact.name.first = restoredName;
                  await contact.update();
                  print('로컬 연락처 이름 복원 완료');
                  break;
                }
              }
              return;
            }
          }
          print('백엔드에서 해당 전화번호에 대한 이름을 찾을 수 없습니다.');
        } else {
          print('백엔드에서 연락처 목록을 찾을 수 없습니다.');
        }
      } else {
        print('Failed to restore contact name from backend.');
      }
    } catch (e) {
      print('이름 복원 중 오류 발생: $e');
    }
  }

  // isCurtainCallOnAndOff가 true/false로 변경될 때 호출되는 함수
  void _toggleSwitch(String phoneNumber, bool value) {
    setState(() {
      _switchStates[phoneNumber] = value;

      if (value) {
        _deleteLocalContactName(phoneNumber);
      } else {
        _restoreContactNameFromBackend(phoneNumber);
      }

      _updateCurtainCallStatusInBackend(phoneNumber, value);
    });
  }

  // 연락처 편집 모드 활성화/비활성화
  void _toggleEditMode(String phoneNumber) {
    setState(() {
      if (!_isEditing.containsKey(phoneNumber)) {
        _isEditing[phoneNumber] = false;
      }
      _isEditing[phoneNumber] = !_isEditing[phoneNumber]!;
    });
  }

  // 편집된 연락처 저장 (DB로 업데이트)
  Future<void> _saveEditedContact(String phoneNumber) async {
    final nameController = _nameControllers[phoneNumber];
    final phoneController = _phoneControllers[phoneNumber];

    if (nameController == null || phoneController == null) {
      print('Error: nameController 또는 phoneController가 존재하지 않음.');
      return;
    }

    final updatedContact = {
      'name': nameController.text,
      'phoneNumber': phoneController.text,
      'isCurtainCallOnAndOff': _switchStates[phoneNumber] ?? false,
    };

    final url = 'http://10.0.2.2:8080/main/user/phoneAddressBookInfo';

    try {
      final response = await http.put(
        Uri.parse('$url?prePhoneNumber=$phoneNumber'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          userPhoneNumber: updatedContact,
        }),
      );

      if (response.statusCode == 200) {
        print('연락처 정보 업데이트 성공');
      } else {
        print('연락처 정보 업데이트 실패: ${response.statusCode}');
      }

      setState(() {
        for (var contact in _contacts) {
          if (contact['phone'] == phoneNumber) {
            contact['name'] = nameController.text;
            contact['phone'] = phoneController.text;
            break;
          }
        }
        _filteredContacts = _contacts;
        _toggleEditMode(phoneNumber); 
      });
    } catch (e) {
      print('연락처 정보 업데이트 중 오류 발생: $e');
    }
  }

  // 서버로 isCurtainCallOnAndOff 상태만 업데이트
  Future<void> _updateCurtainCallStatusInBackend(String phoneNumber, bool isOn) async {
    final userPhoneBookNumber = phoneNumber;
    final url = 'http://10.0.2.2:8080/main/user/setOff?userPhoneNumber=$userPhoneNumber&userPhoneBookNumber=$userPhoneBookNumber';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        print("isCurtainCallOnAndOff 상태 업데이트 성공");
      } else {
        print("isCurtainCallOnAndOff 상태 업데이트 실패");
      }
    } catch (e) {
      print("서버로 상태 업데이트 중 오류 발생: $e");
    }
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
                setState(() {
                  _filteredContacts = _contacts.where((contact) {
                    final name = contact['name']!.toLowerCase();
                    final phone = contact['phone']!.replaceAll('-', '').toLowerCase();
                    return name.contains(value.toLowerCase()) || phone.contains(value);
                  }).toList();
                });
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

                    return ListTile(
                      title: _isEditing[phoneNumber] == true
                          ? TextField(
                              controller: _nameControllers[phoneNumber],
                              decoration: const InputDecoration(
                                hintText: '이름을 입력하세요',
                              ),
                            )
                          : Text(contact['name']!, style: TextStyle(fontSize: fontSize)),
                      subtitle: _isEditing[phoneNumber] == true
                          ? TextField(
                              controller: _phoneControllers[phoneNumber],
                              decoration: const InputDecoration(
                                hintText: '전화번호를 입력하세요',
                              ),
                            )
                          : Text(
                              phoneNumber,
                              style: TextStyle(fontSize: fontSize),
                            ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(_isEditing[phoneNumber] == true ? Icons.save : Icons.edit),
                            onPressed: () {
                              if (_isEditing[phoneNumber] == true) {
                                _saveEditedContact(phoneNumber);
                              } else {
                                _toggleEditMode(phoneNumber);
                              }
                            },
                          ),
                          Switch(
                            value: _switchStates[phoneNumber] ?? false,
                            onChanged: (value) {
                              _toggleSwitch(phoneNumber, value);
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
