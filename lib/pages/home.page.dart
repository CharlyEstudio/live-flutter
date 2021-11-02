import 'package:flutter/material.dart';
import 'package:live/pages/broadcast.page.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _channelName = TextEditingController();
  String check = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height * 0.2,
              child: TextFormField(
                controller: _channelName,
                decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.grey)),
                    hintText: 'Nombre del canal'),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                primary: Colors.pink,
              ),
              onPressed: () => onJoin(isBroadcaster: true),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const <Widget>[
                  Text(
                    'Broadcast    ',
                    style: TextStyle(fontSize: 20),
                  ),
                  Icon(Icons.live_tv)
                ],
              ),
            ),
            TextButton(
              onPressed: () => onJoin(isBroadcaster: false),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const <Widget>[
                  Text(
                    'Just Watch  ',
                    style: TextStyle(fontSize: 20),
                  ),
                  Icon(Icons.remove_red_eye)
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> onJoin({required bool isBroadcaster}) async {
    await [Permission.camera, Permission.microphone].request();

    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => BroadcastPage(
              channelName: _channelName.text,
              isBroadcaster: isBroadcaster,
            )));
  }
}
