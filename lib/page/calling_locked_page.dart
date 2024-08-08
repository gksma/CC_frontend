import 'package:flutter/material.dart';

class CallingLockedPage extends StatelessWidget {
  const CallingLockedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        toolbarHeight: 0, // Hide the AppBar
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double iconSize = constraints.maxWidth * 0.1; // Adjust icon size proportionally
          double fontSize = constraints.maxWidth * 0.05; // Adjust font size proportionally

          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(height: constraints.maxHeight * 0.05),
              Text(
                '00:01',
                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
              ),
              Text(
                '010-1234-5678',
                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Icon(Icons.volume_up, size: iconSize),
                      SizedBox(height: constraints.maxHeight * 0.01),
                      Text('스피커', style: TextStyle(fontSize: fontSize)),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(Icons.dialpad, size: iconSize),
                      SizedBox(height: constraints.maxHeight * 0.01),
                      Text('키패드', style: TextStyle(fontSize: fontSize)),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(Icons.mic_off, size: iconSize),
                      SizedBox(height: constraints.maxHeight * 0.01),
                      Text('마이크 ON', style: TextStyle(fontSize: fontSize)),
                    ],
                  ),
                ],
              ),
              SizedBox(height: constraints.maxHeight * 0.05),
              IconButton(
                icon: Icon(Icons.call_end, color: Colors.red, size: iconSize * 1.5),
                onPressed: () {
                  // End call logic
                },
              ),
              SizedBox(height: constraints.maxHeight * 0.05),
            ],
          );
        },
      ),
    );
  }
}
