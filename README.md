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

## Features

- wiz discovery devices
- turn On/Off
- set/get rgb
- get temp
- set cold white
- set warm white
- set/get brightness
- set scene

## Getting started

The discovery works with a UDP Broadcast request and collects all bulbs in the network.

WizLight(): Creates an instance of a WiZ Light Bulb. Constructed with the IP of the bulb.

# Bulb paramters (UDP RAW)

- sceneId - calls one of the predefined scenes (int from 1 to 32) List of names in code
- speed - sets the color changing speed in percent
- dimming - sets the dimmer of the bulb in percent
- temp - sets the color temperature in kelvins
- r - red color range 0-255
- g - green color range 0-255
- b - blue color range 0-255
- c - cold white range 0-255
- w - warm white range 0-255
- id - the bulb id
- state - whether it's on or off
- schdPsetId - rhythm id of the room

## Usage

Discover all bulbs in the network via broadcast datagram (UDP).
function takes the discovery object and returns a list of wizlight objects.

NOTE: please use wifiBroadcast value return by the function

```dart
    final info = NetworkInfo();
    final wifiBroadcast = await info.getWifiBroadcast();
 ```

as broadcast space, for avoiding issues when you running the project in your physical device.

```dart
    await findWizlights(broadcastSpace: wifiBroadcast ?? "255.255.255.255");
 ```

# Example UDP request

Send message to the bulb: {"method":"setPilot","params":{"r":255,"g":255,"b":255,"dimming":50}} Response: {"method":"setPilot","env":"pro","result":{"success":true}}

Get state of the bulb: {"method":"getPilot","params":{}} Responses:

```dart
import 'package:example/light_control.dart';
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
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
        future: widget.wizLight.status,
        builder: (_, snapshot) {
          if (snapshot.hasData) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => LightControl(
                            wizLight: widget.wizLight,
                          )),
                );
              },
              child: ListTile(
                  leading: Icon(
                    Icons.light,
                    color: Color.fromRGBO(widget.wizLight.rgb[0],
                        widget.wizLight.rgb[1], widget.wizLight.rgb[2], 1),
                  ),
                  title: Text(widget.wizLight.ip),
                  subtitle: Text(widget.wizLight.mac),
                  trailing: _Switch(
                      lightOn: snapshot.data?.keys.contains('result') ?? false
                          ? snapshot.data?['result']?['state'] ?? false
                          : false,
                      wizLight: widget.wizLight)),
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
  late bool isLo;

  @override
  void initState() {
    isLo = widget.lightOn;
    super.initState();
  }

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
            : widget.wizLight.turnOn(PilotBuilder(brightness: 255));
      },
    );
  }
}



```

## Additional information

This package was only tested under iOS Operative System.
This package is still under development, but I will do everything in my power to finish it as soon as possible. For now feel free to try it.
