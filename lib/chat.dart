import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

String randomString() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(255));
  return base64UrlEncode(values);
}

class XenoChat extends StatefulWidget {
  const XenoChat({super.key});

  @override
  State<XenoChat> createState() => _XenoChatState();
}

class _XenoChatState extends State<XenoChat> {
  final List<types.Message> _messages = [];
  final _user = const types.User(id: '82091008-a484-4a89-ae75-a22bf8d6f3ac');

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Chat(
      messages: _messages,
      onSendPressed: _handleSendPressed,
      user: _user,
    ),
  );

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: randomString(),
      text: message.text,
    );

    _addMessage(textMessage);
  }
}






class XenoChat001 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Image.network('logo/Xenodate-logo.png'), // Replace with your logo URL
        title: Align(
          alignment: Alignment.centerRight,
          child: Icon(Icons.menu),
        ),
      ),
      body: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Image.network('Foto/xenid_0000_01.png', width: 50, height: 50), // Replace with your image URL
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text('Nella "Nel"'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('37/F/Keplia 22'),
                            Text('Merball Coach'),
                            Text('Earth movies (1980s era)'),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('dolphins'),
                            Text('humans'),
                            Text('Keplian folk music'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(10),
                color: Colors.blue[100],
                child: Row(
                  children: <Widget>[
                    Text('Hello earthling!'),
                    SizedBox(width: 10),
                    Image.network('Foto/xenid_0000_01.png', width: 30, height: 30),
                  ],
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(10),
                color: Colors.green[100],
                child: Row(
                  children: <Widget>[
                    Image.network('Foto/Rthur.jpg', width: 30, height: 30),
                    SizedBox(width: 10),
                    Text('Hey there, sister!'),
                  ],
                ),
              ),
            ],
          ),
          Spacer(),
          Row(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Enter your message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
