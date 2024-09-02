import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'common_navigation_bar.dart'; // 통일된 하단 네비게이션 import
import 'package:http/http.dart' as http;

class ContactsPage extends StatefulWidget {
  ContactsPage({super.key});

  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _filteredContacts = [];
  String _searchText = '';
  String userPhoneNumber = "01023326094";  // 사용자 전화번호
  Map<String, bool> _switchStates = {};
  Map<String, bool> _isEditing = {};
  Map<String, TextEditingController> _nameControllers = {};
  Map<String, TextEditingController> _phoneControllers = {};

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _fetchPhoneBookProfileWithConnection();
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
    } else {
      print('Failed to load user profile');
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
            print('Contact name deleted');
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
                prefixIcon: Icon(Icons.search),
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
                margin: EdgeInsets.all(0.0),
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
                          decoration: InputDecoration(
                            hintText: '이름을 입력하세요',
                          ),
                          maxLines: 1,
                          style: TextStyle(overflow: TextOverflow.ellipsis),
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
                          decoration: InputDecoration(
                            hintText: '전화번호를 입력하세요',
                          ),
                          maxLines: 1,
                          style: TextStyle(overflow: TextOverflow.ellipsis),
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
      bottomNavigationBar: CommonBottomNavigationBar(currentIndex: 0),
    );
  }
}