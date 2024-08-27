import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

import 'common_navigation_bar.dart';

class RecentCallsPage extends StatelessWidget {
  const RecentCallsPage({super.key});

  Future<List<CallRecordData>> fetchCallRecords() async {
    // 사용자의 전화번호
    String phoneNumber = "01023326094";

    // API 호출
    final response = await http.get(Uri.parse('http://10.0.2.2:8080/main/recentCallHistory?phoneNumber=$phoneNumber'));

    if (response.statusCode == 200) {
      // JSON 데이터를 파싱하여 List<Map<String, dynamic>>로 변환
      List<dynamic> jsonData = jsonDecode(utf8.decode(response.bodyBytes)); // UTF-8로 디코딩

      // JSON 데이터를 CallRecordData 객체 리스트로 변환
      List<CallRecordData> callRecords = jsonData.map((data) {
        return CallRecordData(
          name: data['nickName'],
          phoneNumber: data['phoneNumber'] ?? 'Unknown',
          dateTime: DateTime.parse(data['recentCallDate']).toLocal().toString(),
          isMissed: data['isMissedCall'],
        );
      }).toList();

      return callRecords;
    } else {
      // 실패 시 처리 (예: 빈 리스트 반환)
      throw Exception('Failed to load call records');
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
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Failed to load call records'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No call records found'));
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
      bottomNavigationBar: CommonBottomNavigationBar(currentIndex: 2),
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
