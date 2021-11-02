// ignore_for_file: avoid_print

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:flutter/material.dart';
import 'package:live/utils/appId.dart';
import 'package:permission_handler/permission_handler.dart';

class BroadcastPage extends StatefulWidget {
  final String channelName;
  final bool isBroadcaster;

  const BroadcastPage(
      {Key? key, required this.channelName, required this.isBroadcaster})
      : super(key: key);

  @override
  _BroadcastPageState createState() => _BroadcastPageState();
}

class _BroadcastPageState extends State<BroadcastPage> {
  late RtcEngine engine;
  final _users = <int>[];
  bool muted = false;
  int streamId = 0;
  int _remoteUid = 0;
  bool _joined = false;

  @override
  void dispose() {
    print('saliendo');
    _users.clear();
    engine.destroy();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Init the app
  Future<void> initPlatformState() async {
    await [Permission.camera, Permission.microphone].request();

    // Create RTC client instance
    RtcEngineContext context = RtcEngineContext(appId);
    engine = await RtcEngine.createWithContext(context);

    // Define event handling logic
    engine.setEventHandler(RtcEngineEventHandler(
        joinChannelSuccess: (String channel, int uid, int elapsed) {
      print('joinChannelSuccess $channel $uid');
      setState(() {
        _joined = true;
      });
    }, leaveChannel: (stats) {
      setState(() {
        print('onLeaveChannel');
        _users.clear();
      });
    }, userJoined: (int uid, int elapsed) {
      print('userJoined $uid');
      setState(() {
        _users.add(uid);
        _remoteUid = uid;
      });
    }, userOffline: (int uid, UserOfflineReason reason) {
      print('userOffline $uid');
      setState(() {
        _users.remove(uid);
        _remoteUid = 0;
      });
    }, streamMessage: (_, __, message) {
      final String info = "Here is the message: $message";
      print(info);
    }, streamMessageError: (_, __, error, ___, ____) {
      final String info = "Here is the error: $error";
      print(info);
    }));

    // Enable video
    await engine.enableVideo();

    // Set channel profile as livestreaming
    await engine.setChannelProfile(ChannelProfile.LiveBroadcasting);

    // Set user role
    if (widget.isBroadcaster) {
      await engine.setClientRole(ClientRole.Broadcaster);
    } else {
      await engine.setClientRole(ClientRole.Audience);
    }

    // Join channel with channel
    await engine.joinChannel(token, widget.channelName, null, 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          children: <Widget>[
            // _broadcastView(),
            widget.isBroadcaster ? _renderLocalPreview() : _renderRemoteVideo(),
            _toolbar(),
          ],
        ),
      ),
    );
  }

  // Local preview
  Widget _renderLocalPreview() {
    if (_joined) {
      return RtcLocalView.SurfaceView();
    } else {
      return const Text(
        'Please join channel first',
        textAlign: TextAlign.center,
      );
    }
  }

  // Remote preview
  Widget _renderRemoteVideo() {
    print(_remoteUid);
    if (_remoteUid != 0) {
      return RtcRemoteView.SurfaceView(
        uid: _remoteUid,
        channelId: widget.channelName,
      );
    } else {
      return const Text(
        'Please wait remote user join',
        textAlign: TextAlign.center,
      );
    }
  }

  Widget _toolbar() {
    return widget.isBroadcaster ? _broadcaster() : _audience();
  }

  Widget _broadcaster() {
    return Container(
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.symmetric(vertical: 48.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            RawMaterialButton(
              onPressed: _onToggleMute,
              child: Icon(
                muted ? Icons.mic_off : Icons.mic,
                color: muted ? Colors.white : Colors.blueAccent,
                size: 20.0,
              ),
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: muted ? Colors.blueAccent : Colors.white,
              padding: const EdgeInsets.all(12.0),
            ),
            RawMaterialButton(
              onPressed: () => _onCallEnd(context),
              child: const Icon(
                Icons.call_end,
                color: Colors.white,
                size: 35.0,
              ),
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.redAccent,
              padding: const EdgeInsets.all(15.0),
            ),
            RawMaterialButton(
              onPressed: _onSwitchCamera,
              child: const Icon(
                Icons.switch_camera,
                color: Colors.blueAccent,
                size: 20.0,
              ),
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.white,
              padding: const EdgeInsets.all(12.0),
            )
          ],
        ));
  }

  Widget _audience() {
    return Container(
      child: const Text('Audiencia'),
    );
  }

  Widget _broadcastView() {
    final views = _getRenderView();

    switch (views.length) {
      case 1:
        return Container(
          child: Column(
            children: <Widget>[
              _expandedVideoView([views[0]]),
            ],
          ),
        );
      case 2:
        return Container(
          child: Column(
            children: <Widget>[
              _expandedVideoView([views[0]]),
              _expandedVideoView([views[1]]),
            ],
          ),
        );
      case 3:
        return Container(
          child: Column(
            children: <Widget>[
              _expandedVideoView(views.sublist(0, 2)),
              _expandedVideoView(views.sublist(2, 3)),
            ],
          ),
        );
      case 4:
        return Container(
          child: Column(
            children: <Widget>[
              _expandedVideoView(views.sublist(0, 2)),
              _expandedVideoView(views.sublist(2, 4)),
            ],
          ),
        );
      default:
        return Container();
    }
  }

  List<Widget> _getRenderView() {
    final List<StatefulWidget> list = [];
    if (widget.isBroadcaster) {
      list.add(RtcLocalView.SurfaceView());
    }

    for (var uid in _users) {
      list.add(RtcRemoteView.SurfaceView(uid: uid));
    }
    return list;
  }

  Widget _expandedVideoView(List<Widget> views) {
    final wrappedViews =
        views.map((view) => Expanded(child: Container(child: view))).toList();

    return Expanded(
        child: Row(
      children: wrappedViews,
    ));
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
  }

  void _onCallEnd(BuildContext context) {
    Navigator.pop(context);
  }

  void _onSwitchCamera() {
    if (streamId != 0) {
      engine.sendStreamMessage(streamId, "mute user blet");
    }
  }
}
