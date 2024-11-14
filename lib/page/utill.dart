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

