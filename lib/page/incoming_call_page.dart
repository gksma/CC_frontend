import 'package:flutter/material.dart';

class IncomingCallPage extends StatelessWidget {
  const IncomingCallPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 화면 크기를 가져옵니다.
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              SizedBox(height: size.height * 0.05),
              Text(
                '수신 중...',
                style: TextStyle(fontSize: size.height * 0.03),
              ),
              SizedBox(height: size.height * 0.02),
              Text(
                '김XX',
                style: TextStyle(fontSize: size.height * 0.04, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: size.height * 0.01),
              Text(
                '010-1234-5678',
                style: TextStyle(fontSize: size.height * 0.05, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: size.height * 0.02),
              Icon(
                Icons.person,
                size: size.height * 0.15,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      IconButton(
                        iconSize: size.height * 0.08,
                        icon: const Icon(Icons.block),
                        onPressed: () {
                          // 발신자 차단 로직
                        },
                      ),
                      Text('발신자 차단', style: TextStyle(fontSize: size.height * 0.02)),
                    ],
                  ),
                  Column(
                    children: [
                      IconButton(
                        iconSize: size.height * 0.08,
                        icon: const Icon(Icons.message),
                        onPressed: () {
                          // 메시지 거절 로직
                        },
                      ),
                      Text('메시지 거절', style: TextStyle(fontSize: size.height * 0.02)),
                    ],
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    iconSize: size.height * 0.08,
                    icon: const Icon(Icons.call_end, color: Colors.red),
                    onPressed: () {
                      // 전화 거절 로직
                    },
                  ),
                  IconButton(
                    iconSize: size.height * 0.08,
                    icon: const Icon(Icons.call, color: Colors.green),
                    onPressed: () {
                      // 전화 수락 로직
                    },
                  ),
                ],
              ),
              SizedBox(height: size.height * 0.05),
            ],
          ),
        ),
      ),
    );
  }
}
