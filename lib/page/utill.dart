

String toUrlNumber(String fromNumber){
  if(fromNumber[0]=='+'){
    fromNumber=fromNumber.substring(1);
  }
  return fromNumber;
}