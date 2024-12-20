import 'dart:io';
import 'package:flutter/material.dart';

String toUrlNumber(String fromNumber){
  if(fromNumber[0]=='+'){
    fromNumber=fromNumber.substring(1);
  }
  return fromNumber;
}

// 전화번호에서 숫자 외의 모든 문자를 제거하는 함수
String formatPhoneNumber(String phoneNumber) {
  return phoneNumber.replaceAll(RegExp(r'\D'), ''); // 숫자가 아닌 모든 문자 제거
}

Future<bool> onWillPop(BuildContext context) async {
  bool shouldExit = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('앱 종료'),
      content: const Text('앱을 종료하시겠습니까?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false), // 다이얼로그 닫기
          child: const Text('아니요'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true), // 앱 종료
          child: const Text('예'),
        ),
      ],
    ),
  ) ?? false;

  if (shouldExit) {
    exit(0); // 앱 종료
  }
  return false; // 뒤로가기 이벤트 무시
}
