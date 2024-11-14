import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'common_navigation_bar.dart';
import 'token_util.dart';
import 'utill.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _filteredContacts = [];
  String userPhoneNumber = "";
  final Map<String, bool> _switchStates = {};
  final Map<String, bool> _isEditing = {};
  final Map<String, TextEditingController> _nameControllers = {};
  final Map<String, TextEditingController> _phoneControllers = {};

  @override
  void initState() {
    super.initState();
    _loadUserPhoneNumberAndToken();
    _loadCurtainCallStatus(); // 초기 상태 불러오기
  }

  // SharedPreferences에서 전체 상태 로드하여 모든 토글을 업데이트
  Future<void> _loadCurtainCallStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isCurtainCallOn = prefs.getBool('isCurtainCallOn') ?? false;
    setState(() {
      _switchStates.updateAll((key, value) => isCurtainCallOn); // 모든 토글 상태 일괄 업데이트
    });
  }

  Future<void> _loadUserPhoneNumberAndToken() async {
    // 로컬에서 Bearer 토큰과 전화번호 가져오기
    String? bearerToken = await getBearerTokenFromFile();
    String? storedPhoneNumber = await getStoredPhoneNumber();  // token_util.dart 파일의 함수 호출

    if (bearerToken != null && storedPhoneNumber != null) {
      userPhoneNumber = storedPhoneNumber;
      userPhoneNumber = toUrlNumber(userPhoneNumber);
      await _fetchLocalContactsAndSendToBackend();
      _fetchContactsFromBackend();
    } else {
      print('저장된 전화번호 또는 토큰이 없습니다.');
    }
  }

  // DB에서 연락처 삭제 함수
  Future<void> _removeContactsFromBackend(List<String> removedPhoneNumbers) async {
    final url = Uri.parse('http://10.0.2.2:8080/main/user/phoneAddressBookInfo/remove');

    try {
      final bearerToken = await getBearerTokenFromFile();
      if (bearerToken == null || bearerToken.isEmpty) {
        print("Bearer 토큰을 찾을 수 없습니다.");
        return;
      }

      final response = await http.post(
        url,
        headers: {
          'Authorization': bearerToken,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "removedPhoneNumber": removedPhoneNumbers,
        }),
      );

      if (response.statusCode == 200) {
        print("연락처 삭제 성공: $removedPhoneNumbers");
      } else {
        print("연락처 삭제 실패: ${response.statusCode}");
      }
    } catch (e) {
      print("연락처 삭제 중 오류 발생: $e");
    }
  }

  // 로컬 연락처 가져오기 및 DB와 동기화
  Future<void> _fetchLocalContactsAndSendToBackend() async {
    try {
      if (await Permission.contacts.request().isGranted) {
        final contacts = await FlutterContacts.getContacts(withProperties: true, withAccounts: true);

        if (contacts.isEmpty) {
          print("로컬 연락처가 비어 있습니다.");
        } else {
          print("로컬에서 ${contacts.length}개의 연락처를 불러왔습니다.");

          final localPhoneNumbers = contacts
              .map((contact) => contact.phones.isNotEmpty ? formatPhoneNumber(contact.phones.first.number) : "")
              .where((number) => number.isNotEmpty)
              .toSet();

          final dbContacts = await _fetchContactsFromBackend();
          final dbPhoneNumbers = dbContacts.map((contact) => contact['phone']).toSet();

          // DB에 없는 연락처만 필터링하여 List<Contact>으로 생성
          final contactsToAdd = contacts.where((contact) {
            final phoneNumber = contact.phones.isNotEmpty ? formatPhoneNumber(contact.phones.first.number) : "";
            return !dbPhoneNumbers.contains(phoneNumber);
          }).toList();

          if (contactsToAdd.isNotEmpty) {
            await _sendContactsToBackend(contactsToAdd); // List<Contact> 전달
          }

          final contactsToRemove = dbPhoneNumbers.difference(localPhoneNumbers).toList();
          if (contactsToRemove.isNotEmpty) {
            await _removeContactsFromBackend(contactsToRemove.cast<String>());
          }

          print("연락처 추가 및 삭제 작업이 완료되었습니다.");
        }
      }
    } catch (e) {
      print("연락처를 불러오는 중 오류 발생: $e");
    }
  }


  // 서버로 로컬 연락처를 전송하는 함수
  Future<void> _sendContactsToBackend(List<Contact> contacts) async {
    final url = 'http://10.0.2.2:8080/main/user/phoneAddressBookInfo';

    // API 프로토콜에 맞게 JSON 데이터를 변환
    final Map<String, List<Map<String, dynamic>>> dataToSend = {
      userPhoneNumber: contacts.map((contact) {
        return {
          'name': contact.displayName,
          'phoneNumber': contact.phones.isNotEmpty ? formatPhoneNumber(contact.phones.first.number) : "",
          'isCurtainCallOnAndOff': false,
        };
      }).toList(),
    };

    try {
      // HTTP POST 요청
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(dataToSend),
      );

      // 응답 상태 코드 및 결과 처리
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody["response"]["resultcode"] == "ERR_CREATED_OK") {
          print("연락처 정보가 성공적으로 서버에 저장되었습니다.");
        } else {
          print("서버에서 반환된 메시지: ${responseBody["response"]["message"]}");
        }
      } else {
        print("연락처 전송 실패: ${response.statusCode}");
      }
    } catch (e) {
      print("서버로 연락처 전송 중 오류 발생: $e");
    }
  }


  // 서버에서 연락처 정보 가져오기
  Future<List<Map<String, dynamic>>> _fetchContactsFromBackend() async {
    final url = Uri.parse('http://10.0.2.2:8080/main/user/phoneAddressBookInfo');
    final List<Map<String, dynamic>> contactsFromBackend = [];

    try {
      final bearerToken = await getBearerTokenFromFile();
      if (bearerToken == null || bearerToken.isEmpty) {
        print("Bearer 토큰을 찾을 수 없습니다.");
        return [];
      }

      final response = await http.get(
        url,
        headers: {
          'authorization': bearerToken,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["response"] != null && data["response"][userPhoneNumber] != null) {
          final List<dynamic> contactList = data["response"][userPhoneNumber];

          setState(() {
            _contacts.clear();
            for (var contact in contactList) {
              final contactData = {
                "name": contact["name"],
                "phone": contact["phoneNumber"],
                "isCurtainCallOnAndOff": contact["isCurtainCallOnAndOff"],
              };
              _contacts.add(contactData);
              _switchStates[contact["phoneNumber"]] = contact["isCurtainCallOnAndOff"]; // 개새끼 false로 돼있었음
              _nameControllers[contact["phoneNumber"]] = TextEditingController(text: contact["name"]);
              _phoneControllers[contact["phoneNumber"]] = TextEditingController(text: contact["phoneNumber"]);
            }
            _filteredContacts = _contacts;
          });
          contactsFromBackend.addAll(_contacts);
        } else {
          print('해당 전화번호에 대한 연락처 데이터가 없습니다.');
        }
      } else {
        print('Failed to load contacts from backend. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('연락처를 불러오는 중 오류 발생: $e');
    }
    return contactsFromBackend;
  }

  // 로컬 연락처에서 이름 삭제
  Future<void> _deleteLocalContactName(String phoneNumber) async {
    try {
      final contacts = await FlutterContacts.getContacts(withProperties: true, withPhoto: true, withAccounts: true);

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
  Future<void> _restoreContactNameFromBackend(String phoneNumber) async {
    try {
      final url = Uri.parse('http://10.0.2.2:8080/main/user/setOff');
      final bearerToken = await getBearerTokenFromFile();

      if (bearerToken == null || bearerToken.isEmpty) {
        print("Bearer 토큰을 찾을 수 없습니다.");
        return;
      }

      final response = await http.post(
        url,
        headers: {
          'authorization': bearerToken,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "userPhoneBookNumber": phoneNumber,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("백엔드로부터 가져온 데이터: $data");

        if (data != null && data is List && data.isNotEmpty) {
          final restoredName = data[0]["nickName"];

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
        } else {
          print('백엔드에서 해당 전화번호에 대한 정보를 찾을 수 없습니다.');
        }
      } else {
        print('Failed to restore contact name from backend. Status code: ${response.statusCode}');
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
        phoneNumber: {
          'name': nameController.text,
          'phoneNumber': phoneController.text,
          'isCurtainCallOnAndOff': _switchStates[phoneNumber] ?? false,
        },
      };
    print(updatedContact);

    final url = 'http://10.0.2.2:8080/main/user/phoneAddressBookInfo';
    String? bearerToken = await getBearerTokenFromFile();

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'authorization': bearerToken ?? '', // 이미 "Bearer " 접두사가 포함된 상태
          'Content-Type': 'application/json',
        },
        body: json.encode(updatedContact),
      );

      if (response.statusCode == 200) {
        final responseData = utf8.decode(response.bodyBytes);
        if (responseData == "Successfull update AddressBook!") {
          print('연락처 정보 업데이트 성공');
        } else {
          print('연락처 업데이트 오류: ${responseData}');
        }
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
