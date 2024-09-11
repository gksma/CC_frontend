import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:call_log/call_log.dart';
import 'utill.dart';

import 'common_navigation_bar.dart';

class RecentCallsPage extends StatelessWidget {
  const RecentCallsPage({super.key});

  // 사용자 전화번호 로드 (연락처 페이지 방식과 동일)
  Future<String?> _getStoredPhoneNumber() async {
    try {
      final directory = '/data/data/com.example.curtaincall/files';
      final file = File(path.join(directory, 'phone_number.txt'));

      if (await file.exists()) {
        final phoneNumber = await file.readAsString();
        return phoneNumber;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
  // 로컬 통화 기록에서 전화번호만 추출하고, 사용자 전화번호와 함께 서버로 요청하여 이름과 번호를 가져오는 함수
  Future<List<CallRecordData>> fetchCallRecords() async {
    try {
      // 로컬 전화번호 로드
      String? userPhoneNumber = await _getStoredPhoneNumber();
      if (userPhoneNumber == null) {
        throw Exception('User phone number not found');
      }
      userPhoneNumber = toUrlNumber(userPhoneNumber);

      // 권한 요청
      var status = await Permission.phone.status;
      if (!status.isGranted) {
        await Permission.phone.request();
      }

      // 로컬 통화 기록 가져오기
      Iterable<CallLogEntry> localCallLogs = await CallLog.get();
      List<CallRecordData> callRecords = localCallLogs.map((log) {
        // 날짜를 밀리초에서 DateTime 형식으로 변환
        String callDate = DateTime.fromMillisecondsSinceEpoch(log.timestamp ?? 0).toString();
        bool isMissedCall = log.callType == CallType.missed;

        return CallRecordData(
          name: 'Unknown',  // 서버에서 가져오는 이름
          phoneNumber: log.number ?? 'Unknown',
          dateTime: callDate, // 날짜 추가
          isMissed: isMissedCall, // 부재중 여부 추가
        );
      }).toList();

      // 서버로 전화번호 리스트 전송
      List<String> phoneNumbers = localCallLogs.map((log) => log.number ?? 'Unknown').toList();
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8080/main/recentCallHistory?phoneNumber=${userPhoneNumber}'),
        headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'phoneNumbers': phoneNumbers}),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));

        if (jsonData['callLogInfos'] != null && jsonData['callLogInfos'] is List) {
          // 서버에서 반환된 데이터를 로컬 통화 기록과 매칭
          for (var i = 0; i < callRecords.length; i++) {
            var serverData = jsonData['callLogInfos'].firstWhere(
                (data) => data['phoneNumber'] == callRecords[i].phoneNumber,
                orElse: () => null);

            if (serverData != null) {
              callRecords[i] = CallRecordData(
                name: serverData['nickname'] ?? 'Unknown',
                phoneNumber: callRecords[i].phoneNumber,
                dateTime: callRecords[i].dateTime, // 로컬에서 추출된 날짜 유지
                isMissed: callRecords[i].isMissed, // 로컬에서 추출된 부재중 여부 유지
              );
            }
          }
        }
      } else {
        throw Exception('Failed to load call records from server');
      }

      return callRecords;
    } catch (e) {
      throw Exception('Failed to load call logs: ${e.toString()}');
    }
  }




  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double padding = screenSize.width * 0.04;
    final double fontSize = screenSize.width * 0.045;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '최근 기록',
            style: TextStyle(color: Colors.black, fontSize: fontSize * 1.5),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: FutureBuilder<List<CallRecordData>>(
          future: fetchCallRecords(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              print(snapshot.error);
              return const Center(child: Text('Failed to load call records'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No call records found'));
            } else {
              final callRecords = snapshot.data!;
              return ListView.builder(
                itemCount: callRecords.length,
                itemBuilder: (context, index) {
                  final callRecord = callRecords[index];
                  return CallRecord(
                    name: callRecord.name,
                    phoneNumber: callRecord.phoneNumber,
                    dateTime: callRecord.dateTime,
                    isMissed: callRecord.isMissed,
                  );
                },
              );
            }
          },
        ),
      ),
      bottomNavigationBar: const CommonBottomNavigationBar(currentIndex: 2),
    );
  }
}

class CallRecord extends StatelessWidget {
  final String name;
  final String phoneNumber;
  final String dateTime;
  final bool isMissed;

  const CallRecord({
    super.key,
    required this.name,
    required this.phoneNumber,
    required this.dateTime,
    required this.isMissed,
  });

  Future<void> requestPhonePermission() async {
    var status = await Permission.phone.status;
    if (!status.isGranted) {
      await Permission.phone.request();
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    await requestPhonePermission();  // 권한 요청
    bool? res = await FlutterPhoneDirectCaller.callNumber(phoneNumber);
    if (res == null || !res) {
      throw 'Could not make the call to $phoneNumber';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double fontSize = screenSize.width * 0.045;

    return Card(
      color: isMissed ? Colors.red[50] : Colors.grey[100], // 부재중 여부에 따른 색상
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.03),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: isMissed ? Colors.red : Colors.black, // 부재중이면 빨간색
                  ),
                ),
                SizedBox(height: screenSize.height * 0.005),
                Text(
                  phoneNumber,
                  style: TextStyle(
                    fontSize: fontSize * 0.85,
                    color: isMissed ? Colors.red : Colors.black,
                  ),
                ),
                SizedBox(height: screenSize.height * 0.005),
                Text(
                  dateTime, // 통화 날짜 표시
                  style: TextStyle(
                    fontSize: fontSize * 0.85,
                    color: isMissed ? Colors.red : Colors.black,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Icon(
                Icons.phone,
                color: isMissed ? Colors.red : Colors.black,
                size: screenSize.width * 0.07,
              ),
              onPressed: () => _makePhoneCall(phoneNumber),
            ),
          ],
        ),
      ),
    );
  }
}

class CallRecordData {
  final String name;
  final String phoneNumber;
  final String dateTime;
  final bool isMissed;

  CallRecordData({
    required this.name,
    required this.phoneNumber,
    required this.dateTime,
    required this.isMissed,
  });
}
