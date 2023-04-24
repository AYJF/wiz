import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:wiz/src/discovery.dart';

class WizLight {
  final String ip;
  final int port;
  final String mac;

  late RawDatagramSocket datagramSocket;

  WizLight({required this.ip, required this.port, required this.mac});

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

  Future<bool> status() async {
    try {
      final Map resp =
          await _sendAdnWaitForResponse({"method": "getPilot", "params": {}});

      return resp.keys.contains('result') ? resp['result']['state'] : false;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

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

  //     """Ensure we are connected."""
  Future<void> _ensureConnection() async {
    datagramSocket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, PORT);
  }
}

class PilotBuilder {
  final bool state;
  Map<String, dynamic> pilotParams = {};

  PilotBuilder({this.state = true}) {
    pilotParams["state"] = state;
  }

  //  """Return the pilot message."""
  Map<String, dynamic> setPilotMessage() {
    return {"method": "setPilot", "params": pilotParams};
  }
}
