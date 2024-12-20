import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:call_log/call_log.dart';
import 'token_util.dart';
import 'common_navigation_bar.dart';
import '../config.dart';
import 'utill.dart';

class RecentCallsPage extends StatelessWidget {
  const RecentCallsPage({super.key});

  // 최근 기록을 가져오는 함수
  // 로컬 통화 기록에서 전화번호만 추출하고, 사용자 전화번호와 함께 서버로 요청하여 이름과 번호를 가져오는 함수
  Future<List<CallRecordData>> fetchCallRecords() async {
    try {
      // 로컬에서 JWT Bearer 토큰 로드
      String? bearerToken = await getBearerTokenFromFile();
      if (bearerToken == null || bearerToken.isEmpty) {
        throw Exception('Bearer token not found');
      }

      // 권한 요청
      var status = await Permission.phone.status;
      if (!status.isGranted) {
        await Permission.phone.request();
      }

      // 로컬 통화 기록 가져오기
      Iterable<CallLogEntry> localCallLogs = await CallLog.get();
      List<String> phoneNumbers = localCallLogs.map((log) => log.number ?? 'Unknown').toList();

      // 서버로 전화번호 리스트 전송
      final response = await http.post(
        Uri.parse(Config.apiBaseUrl + '/main/recentCallHistory'),
        headers: {
          'authorization': bearerToken,
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'phoneNumbers': phoneNumbers.map((number) => number.toString()).toList(),
        }),
      );

      // 로컬 통화 기록을 CallRecordData 객체로 변환
      List<CallRecordData> callRecords = localCallLogs.map((log) {
        String callDate = DateTime.fromMillisecondsSinceEpoch(log.timestamp ?? 0).toString().split('.').first;
        bool isMissedCall = log.callType == CallType.missed;

        return CallRecordData(
          isMissed: isMissedCall,
          name: 'Unknown', // 서버에서 받아올 이름
          phoneNumber: log.number ?? 'Unknown',
          dateTime: callDate,
        );
      }).toList();

      print('Sending phoneNumbers: $phoneNumbers');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        print('Server Response Data: $jsonData');

        if (jsonData['callLogInfos'] != null && jsonData['callLogInfos'] is List) {
          // 서버에서 받은 전화번호와 이름을 매핑하여 callRecords의 이름을 업데이트
          Map<String, String> phoneNameMap = {
            for (var info in jsonData['callLogInfos'])
              info['phoneNumber']: (info['nickname'] == 'Unknown!!') ? '' : info['nickname'] // Set blank if "Unknown!!"
          };

          for (var record in callRecords) {
            if (phoneNameMap.containsKey(record.phoneNumber)) {
              record.name = phoneNameMap[record.phoneNumber]!;
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

    return WillPopScope(
      onWillPop: () => onWillPop(context), // util.dart의 onWillPop 메소드 호출
      child: Scaffold(
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
      ),
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
    await requestPhonePermission();
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
      color: isMissed ? Colors.red[50] : Colors.grey[100],
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
  String name;
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
