class User {
  final String name;
  final String phoneNumber;
  final bool isCurtainCallOnAndOff;


  User({required this.name, required this.phoneNumber,
    required this.isCurtainCallOnAndOff});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'isCurtainCallOnAndOff': isCurtainCallOnAndOff
    };
  }
}