class Contact {
  final String name;
  final String phoneNumber;
  final bool isCurtainCallOnAndOff;


  Contact({required this.name, required this.phoneNumber,
    required this.isCurtainCallOnAndOff});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'isCurtainCallOnAndOff': isCurtainCallOnAndOff
    };
  }
}