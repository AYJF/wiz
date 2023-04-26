// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:wiz/src/discovery.dart';
import 'package:wiz/src/rgbcw.dart';
import 'package:wiz/src/utils/utils.dart';

const RGB_ORDER = ["r", "g", "b"];

class WizLight {
  final String ip;
  final int port;
  final String mac;

  late PilotParser pilotParser;

  late RawDatagramSocket datagramSocket;

  WizLight({required this.ip, required this.port, required this.mac});

  void setBrightness(int brightness) async {
    await _send(PilotBuilder(brightness: brightness).setPilotMessage());
  }

  void setWarmWhite(int warmWhite) async {
    await _send(PilotBuilder(warmWhite: warmWhite).setPilotMessage());
  }

  void setColdWhite(int coldWhite) async {
    await _send(PilotBuilder(coldWhite: coldWhite).setPilotMessage());
  }

  void setRgb(List<int> rgb) async {
    await _send(PilotBuilder(rgb: rgb).setPilotMessage());
  }

  void setRgbw(List<int> rgbw) async {
    await _send(PilotBuilder(rgbw: rgbw).setPilotMessage());
  }

  // """Turn the light on with defined message.
  // :param pilot_builder: PilotBuilder object to set the turn on state, defaults to PilotBuilder()
  // """
  void turnOn(PilotBuilder pilotBuilder) async {
    await _send(pilotBuilder.setPilotMessage());
  }

  //"""Turn the light off."""
  void turnOff() async {
    await _send({
      "method": "setPilot",
      "params": {"state": false}
    });
  }

  Future<Map<String, dynamic>> get status async {
    try {
      final res =
          await _sendAdnWaitForResponse({"method": "getPilot", "params": {}});

      pilotParser = PilotParser(res["result"]);
      return res;
    } catch (e) {
      debugPrint(e.toString());
      return {};
    }
  }

  int get brightness => pilotParser.brightness;
  int get colortemp => pilotParser.colortemp;
  List<int> get rgb => pilotParser.rgb;

  // """Serialize a dict to json and send it to device over UDP."""
  Future<void> _send(Map<String, dynamic> msgDict) async {
    await _ensureConnection();

    datagramSocket.send(
        utf8.encode(json.encode(msgDict)), InternetAddress(ip), port);
    datagramSocket.close();
  }

  Future<Map<String, dynamic>> _sendAdnWaitForResponse(
      Map<String, dynamic> msgDict) async {
    await _ensureConnection();
    late Map<String, dynamic> resp;

    datagramSocket.send(
        utf8.encode(json.encode(msgDict)), InternetAddress(ip), port);

    datagramSocket.listen((RawSocketEvent evt) {
      if (evt == RawSocketEvent.read) {
        Datagram? packet = datagramSocket.receive();

        debugPrint('Received Wiz packet: ${packet != null}');

        resp = json.decode(utf8.decode(packet!.data));
      }
    }, onDone: () {
      debugPrint("Socket closed successfully!");
    });

    await sendMessage(json.encode(msgDict));
    datagramSocket.close();

    return resp;
  }

  Future<void> sendMessage(String message) async {
    int sendResult =
        datagramSocket.send(utf8.encode(message), InternetAddress(ip), PORT);
    debugPrint(
        'Wiz request sent, waiting for response... Did send data successfully: ${sendResult > 0}\n');
    await Future.delayed(const Duration(seconds: 1));
  }

  // """Ensure we are connected."""
  Future<void> _ensureConnection() async {
    datagramSocket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, PORT);
  }
}

// """Interpret the message from the bulb."""
class PilotParser {
  PilotParser(this.pilotResult);

  final Map<String, dynamic> pilotResult;

  int get brightness => percentToHex(pilotResult["dimming"]);
  int get colortemp =>
      pilotResult.containsKey('temp') ? pilotResult["temp"] : 0;

  List<int> get rgb {
    if (pilotResult.containsKey(RGB_ORDER[0]) &&
        pilotResult.containsKey(RGB_ORDER[1]) &&
        pilotResult.containsKey(RGB_ORDER[2])) {
      return [
        pilotResult[RGB_ORDER[0]],
        pilotResult[RGB_ORDER[1]],
        pilotResult[RGB_ORDER[2]],
      ];
    }

    return [0, 0, 0];
  }
}

class PilotBuilder {
  final bool state;
  final int? brightness;
  final int? warmWhite;
  final int? coldWhite;
  final int? colorTemp;
  final List<int>? rgb;
  final List<int>? rgbw;
  final Map<String, dynamic> pilotParams = {};

  PilotBuilder({
    this.state = true,
    this.brightness,
    this.warmWhite,
    this.coldWhite,
    this.colorTemp,
    this.rgb,
    this.rgbw,
  }) {
    pilotParams["state"] = state;
    if (brightness != null) _setBrightness(brightness!);
    if (warmWhite != null) _setWarmWhite(warmWhite!);
    if (coldWhite != null) _setColdWhite(coldWhite!);
    if (colorTemp != null) _setColorTemp(colorTemp!);
    if (rgb != null) _setRgb(rgb!);
    if (rgbw != null) _setRgbw(rgbw!);
  }

  //  """Return the pilot message."""
  Map<String, dynamic> setPilotMessage() {
    debugPrint('{"method": "setPilot", "params": pilotParams}');
    return {"method": "setPilot", "params": pilotParams};
  }

//   """Set the value of the brightness 0-255."""
  void _setBrightness(int hex) {
    int percent = hexToPercent(hex);
    assert(percent < 101);
    pilotParams['dimming'] = max(10, percent);
  }

  // """Set the value of the warm white led."""
  void _setWarmWhite(int value) {
    assert(0 <= value && value < 256);
    pilotParams["w"] = value;
  }

  //"""Set the value of the cold white led."""
  void _setColdWhite(int value) {
    assert(0 <= value && value < 256);
    pilotParams["c"] = value;
  }

  //"""Set the color temperature for the white led in the bulb."""
  void _setColorTemp(int kelvin) {
    // normalize the kelvin values - should be removed
    pilotParams["temp"] = min(10000, max(1000, kelvin));
  }

  //"""Set the RGB color state of the bulb."""
  void _setRgb(List<int> rgb) {
    _rgbInRangeOrRaise(rgb);

    //     # Get the RGB+CW values
    Map<String, dynamic> res = rgb2rgbcw(rgb);

    List rgbOut = res['rgb'];
    int? cw = res['cw']?.toInt();

    pilotParams.addAll(Map.fromIterables(RGB_ORDER, rgbOut));

    if (cw != null) _setWarmWhite(cw);
  }

  void _rgbInRangeOrRaise(List<int> rgb) {
    if (0 > rgb[0] && rgb[0] >= 256) {
      throw const FormatException("Red is not in range between 0-255.");
    }
    if (0 > rgb[1] && rgb[0] >= 256) {
      throw const FormatException("Green is not in range between 0-255.");
    }
    if (0 > rgb[2] && rgb[0] >= 256) {
      throw const FormatException("lue is not in range between 0-255.");
    }
  }

  //   """Set the RGBW color state of the bulb."""
  void _setRgbw(List<int> rgbw) {
    _rgbInRangeOrRaise(rgbw);

    List<int> rgb = rgbw.getRange(0, 3).toList();
    pilotParams.addAll(Map.fromIterables(RGB_ORDER, rgb));
    _setWarmWhite(rgbw[3]);
  }
}
