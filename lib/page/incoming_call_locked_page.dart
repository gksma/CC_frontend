  import 'package:flutter/material.dart';

class IncomingCallLockedPage extends StatelessWidget {
  const IncomingCallLockedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(height: 20),
            Text(
              '수신 중...',
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.05,
                color: Colors.black,
              ),
            ),
            Text(
              '010-1234-5678',
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.1,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            Divider(thickness: 1, color: Colors.grey[300]),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Icon(
                      Icons.person_off,
                      size: MediaQuery.of(context).size.width * 0.1,
                      color: Colors.black,
                    ),
                    Text(
                      '발신자 차단',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.035,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Icon(
                      Icons.message,
                      size: MediaQuery.of(context).size.width * 0.1,
                      color: Colors.black,
                    ),
                    Text(
                      '메세지 거절',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.035,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      // 수신 거절 로직
                    },
                    child: Column(
                      children: [
                        Icon(
                          Icons.call_end,
                          size: MediaQuery.of(context).size.width * 0.15,
                          color: Colors.red,
                        ),
                        Text(
                          '거절',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.04,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // 수신 수락 로직
                    },
                    child: Column(
                      children: [
                        Icon(
                          Icons.call,
                          size: MediaQuery.of(context).size.width * 0.15,
                          color: Colors.green,
                        ),
                        Text(
                          '수락',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.04,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
