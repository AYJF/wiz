// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:wiz/src/bulb.dart';
import 'package:wiz/src/models/models.dart';

const PORT = 38899;
const DEFAULT_WAIT_TIME = 5;
// Note: The IP and address we give the bulb does not matter because
// we have register set to false which is telling the bulb to remove
// the registration
const REGISTER_MESSAGE =
    '{"method":"registration","params":{"phoneMac":"AAAAAAAAAAAA","register":false,"phoneIp":"1.2.3.4","id":"1"}}';

class BroadcastProtocol {
  BroadcastProtocol(this.broadcastSpace, this.waitTime);

  final BulbRegistry _registry = BulbRegistry();
  late RawDatagramSocket datagramSocket;
  final String broadcastSpace;
  final int waitTime;

  Future<void> broadcastRegistration() async {
    try {
      datagramSocket =
          await RawDatagramSocket.bind(InternetAddress.anyIPv4, PORT);
      datagramSocket.broadcastEnabled = true;

      datagramReceived();

      await sendMessage(REGISTER_MESSAGE);

      datagramSocket.close();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  List<DiscoveredBulb> get discoveryBulbs => _registry.bulbs();

  Future<void> sendMessage(String message) async {
    int sendResult = datagramSocket.send(
        utf8.encode(message), InternetAddress(broadcastSpace), PORT);
    debugPrint(
        'Wiz request sent, waiting for response... Did send data successfully: ${sendResult > 0}\n');
    await Future.delayed(const Duration(seconds: 5));
  }

  void datagramReceived() {
    // Receive response

    datagramSocket.listen((RawSocketEvent evt) {
      if (evt == RawSocketEvent.read) {
        Datagram? packet = datagramSocket.receive();

        debugPrint('Received Wiz packet: ${packet != null}');

        final Map resp = json.decode(utf8.decode(packet!.data));

        if (resp.keys.contains('result')) {
          final String mac = resp['result']['mac'];

          debugPrint(
              "Found bulb with IP: ${packet.address.address} and MAC: $mac");
          _registry.register(DiscoveredBulb(packet.address.address, mac));
        }
      }
    }, onDone: () {
      debugPrint("Socket closed successfully!");
    });
  }
}

Future<List<DiscoveredBulb>> _discoverLights(
    {String broadcastSpace = "255.255.255.255",
    int waitTime = DEFAULT_WAIT_TIME}) async {
  final BroadcastProtocol broadcastProtocol =
      BroadcastProtocol(broadcastSpace, waitTime);

  await broadcastProtocol.broadcastRegistration();

  return broadcastProtocol.discoveryBulbs;
}

// """Start discovery and return list of IPs of the bulbs."""
Future<List<WizLight>> findWizlights(
    {String broadcastSpace = "255.255.255.255",
    int waitTime = DEFAULT_WAIT_TIME}) async {
  final List<DiscoveredBulb> discoveredIPs =
      await _discoverLights(broadcastSpace: broadcastSpace);

  return discoveredIPs
      .map((e) => WizLight(ip: e.ipAddress, port: PORT, mac: e.macAddress))
      .toList();
}
