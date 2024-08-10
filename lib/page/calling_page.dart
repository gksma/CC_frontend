import 'package:flutter/material.dart';

class CallingPage extends StatelessWidget {
  final String contactName;
  final String contactNumber;

  CallingPage({required this.contactName, required this.contactNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '통화 중',
            style: TextStyle(color: Colors.black),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double iconSize = constraints.maxWidth * 0.1;
          double buttonFontSize = constraints.maxWidth * 0.04;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: constraints.maxHeight * 0.02),
              Text(
                '00:01',
                style: TextStyle(fontSize: constraints.maxWidth * 0.05),
              ),
              SizedBox(height: constraints.maxHeight * 0.02),
              Text(
                contactName,
                style: TextStyle(
                  fontSize: constraints.maxWidth * 0.08,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: constraints.maxHeight * 0.01),
              Text(
                contactNumber,
                style: TextStyle(
                  fontSize: constraints.maxWidth * 0.06,
                ),
              ),
              SizedBox(height: constraints.maxHeight * 0.05),
              Icon(
                Icons.account_circle,
                size: constraints.maxHeight * 0.2,
                color: Colors.grey,
              ),
              SizedBox(height: constraints.maxHeight * 0.05),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Icon(Icons.volume_up, size: iconSize),
                      SizedBox(height: constraints.maxHeight * 0.01),
                      Text('스피커', style: TextStyle(fontSize: buttonFontSize)),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(Icons.dialpad, size: iconSize),
                      SizedBox(height: constraints.maxHeight * 0.01),
                      Text('키패드', style: TextStyle(fontSize: buttonFontSize)),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(Icons.mic, size: iconSize),
                      SizedBox(height: constraints.maxHeight * 0.01),
                      Text('마이크 ON', style: TextStyle(fontSize: buttonFontSize)),
                    ],
                  ),
                ],
              ),
              SizedBox(height: constraints.maxHeight * 0.05),
              IconButton(
                icon: Icon(Icons.call_end, color: Colors.red, size: iconSize * 1.5),
                onPressed: () {
                  // 통화 종료 로직 추가
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
