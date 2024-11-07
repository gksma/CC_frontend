import 'dart:io';
import 'package:path/path.dart' as path;

// Bearer 토큰을 파일에 저장하는 함수
Future<void> saveBearerTokenToFile(String token) async {
  try {
    final nativeDirectory = await getNativeFilePath();
    final file = File(path.join(nativeDirectory, 'bearer_token.txt'));
    await file.writeAsString(token);
    print("Bearer 토큰이 파일에 저장되었습니다. 경로: ${file.path}");
  } catch (e) {
    print("Bearer 토큰 저장 오류: $e");
  }
}

// 파일에서 Bearer 토큰을 불러오는 함수
Future<String?> getBearerTokenFromFile() async {
  try {
    final nativeDirectory = await getNativeFilePath();
    final file = File(path.join(nativeDirectory, 'bearer_token.txt'));
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

// Android의 기본 파일 경로 사용 함수
Future<String> getNativeFilePath() async {
  return '/data/data/com.example.curtaincall/files';
}
