import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

// Bearer 토큰을 파일에 저장하는 함수
Future<void> saveBearerTokenToFile(String token) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(path.join(directory.path, 'bearer_token.txt'));
    await file.writeAsString(token);
    print("Bearer 토큰이 파일에 저장되었습니다. 경로: ${file.path}");
  } catch (e) {
    print("Bearer 토큰 저장 오류: $e");
  }
}

// 파일에서 Bearer 토큰을 불러오는 함수
Future<String?> getBearerTokenFromFile() async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(path.join(directory.path, 'bearer_token.txt'));
    if (await file.exists()) {
      final token = await file.readAsString();
      print("불러온 Bearer 토큰: $token");
      return token;
    } else {
      print("Bearer 토큰이 저장된 파일이 없습니다.");
      return null;
    }
  } catch (e) {
    print("Bearer 토큰 불러오기 오류: $e");
    return null;
  }
}

// 전화번호를 파일에 저장하는 함수
Future<void> savePhoneNumberToFile(String phoneNumber) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(path.join(directory.path, 'phone_number.txt'));
    await file.writeAsString(phoneNumber);
    print("전화번호가 파일에 저장되었습니다. 경로: ${file.path}");
  } catch (e) {
    print("전화번호 저장 오류: $e");
  }
}

// 파일에서 전화번호를 불러오는 함수
Future<String?> getStoredPhoneNumber() async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(path.join(directory.path, 'phone_number.txt'));
    print(directory);
    print(file);
    if (await file.exists()) {
      final phoneNumber = await file.readAsString();
      print("불러온 전화번호: $phoneNumber");
      return phoneNumber;
    } else {
      print("전화번호가 저장된 파일이 없습니다.");
      return null;
    }
  } catch (e) {
    print("전화번호 불러오기 오류: $e");
    return null;
  }
}
