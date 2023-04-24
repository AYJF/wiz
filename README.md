<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->



💥 A Dart connector for WiZ devices.💥




TODO: Put a short description of the package here that helps potential users
know whether this package might be useful for them.

## Features

TODO: List what your package can do. Maybe include images, gifs, or videos.

## Getting started


The discovery works with a UDP Broadcast request and collects all bulbs in the network.

TODO: List prerequisites and provide or point to information on how to
start using the package.

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder.

```dart
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:wiz/wiz.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Wiz example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<WizLight> wizLight = [];

  bool isLoading = false;

  void _incrementCounter() async {
    setState(() {
      isLoading = true;
    });
    final info = NetworkInfo();

    final wifiBroadcast = await info.getWifiBroadcast();

    debugPrint(wifiBroadcast);

    wizLight =
        await findWizlights(broadcastSpace: wifiBroadcast ?? "255.255.255.255");
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
          child: isLoading
              ? const CircularProgressIndicator()
              : ListView.builder(
                  itemCount: wizLight.length,
                  itemBuilder: (context, index) {
                    return _Bulb(wizLight: wizLight[index]);
                  },
                )),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.sync),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class _Bulb extends StatefulWidget {
  const _Bulb({required this.wizLight});

  final WizLight wizLight;

  @override
  State<_Bulb> createState() => __BulbState();
}

class __BulbState extends State<_Bulb> {
  bool lightOn = false;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: widget.wizLight.status(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            lightOn = snapshot.data ?? false;
            return GestureDetector(
              onTap: () {},
              child: ListTile(
                  leading: const Icon(Icons.light),
                  title: Text(widget.wizLight.ip),
                  subtitle: Text(widget.wizLight.mac),
                  trailing:
                      _Switch(lightOn: lightOn, wizLight: widget.wizLight)),
            );
          } else {
            return Container();
          }
        });
  }
}

class _Switch extends StatefulWidget {
  const _Switch({
    required this.lightOn,
    required this.wizLight,
  });

  final bool lightOn;
  final WizLight wizLight;

  @override
  State<_Switch> createState() => _SwitchState();
}

class _SwitchState extends State<_Switch> {
  bool isLo = false;
  @override
  Widget build(BuildContext context) {
    return Switch(
      value: isLo,
      activeColor: Colors.red,
      onChanged: (bool value) {
        setState(() {
          isLo = value;
        });
        !isLo
            ? widget.wizLight.turnOff()
            : widget.wizLight.turnOn(PilotBuilder());
      },
    );
  }
}

```

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
