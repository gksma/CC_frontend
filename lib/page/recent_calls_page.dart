import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

import 'common_navigation_bar.dart';

class RecentCallsPage extends StatelessWidget {
  const RecentCallsPage({super.key});

  static const platform = MethodChannel('com.example.curtaincall/callLogs');

  // 로컬 통화 기록에서 전화번호만 추출하고, 서버로 요청하여 이름과 번호를 가져오는 함수
  Future<List<CallRecordData>> fetchCallRecords() async {
    try {
      // 네이티브 코드에서 로컬 통화 기록 가져오기
      final List<dynamic> localCallLogs = await platform.invokeMethod('getCallLogs');

      // 전화번호 리스트 추출
      List<String> phoneNumbers = localCallLogs.map((record) {
        return record['phoneNumber'] ?? 'Unknown';
      }).cast<String>().toList();

      // 전화번호를 서버에 전달하기 위해 JSON 형식으로 변환
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/main/recentCallHistory?phoneNumber=${phoneNumbers.join(",")}'),
      );

      if (response.statusCode == 200) {
        // 서버에서 반환된 JSON 데이터를 파싱하여 CallRecordData 객체 리스트로 변환
        Map<String, dynamic> jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        List<CallRecordData> callRecords = (jsonData['callLogInfos'] as List).map((data) {
          return CallRecordData(
            name: data['nickname'],
            phoneNumber: data['phoneNumber'] ?? 'Unknown',
            dateTime: '', // 날짜는 로컬에서 제공되지 않으므로 빈 값으로 설정
            isMissed: false, // 미수신 여부도 로컬에서 제공되지 않으므로 기본값 설정
          );
        }).toList();

        return callRecords;
      } else {
        throw Exception('Failed to load call records from server');
      }
    } on PlatformException catch (e) {
      throw Exception('Failed to load call logs: ${e.message}');
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
      color: isMissed ? Colors.red[50] : Colors.grey[100], // 색상 설정
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
                    color: isMissed ? Colors.red : Colors.black,
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
                  dateTime,
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
