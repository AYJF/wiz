class DiscoveredBulb {
  final String ipAddress;
  final String macAddress;

  DiscoveredBulb(this.ipAddress, this.macAddress);
}

//  """Representation of the bulb registry."""
class BulbRegistry {
  Map<String, DiscoveredBulb> bulbsByMac = {};

//  """Register a new bulb."""
  void register(DiscoveredBulb bulb) {
    bulbsByMac[bulb.macAddress] = bulb;
  }

// """Get all present bulbs."""
  List<DiscoveredBulb> bulbs() {
    return bulbsByMac.values.toList();
  }
}
// List<Site> siteFromJson(List list) {
//   return list.map((e) => Site.fromJson(e)).toList();
// }

// class Site extends Equatable {
//   const Site({
//     required this.mspSystemID,
//     required this.backyardName,
//     required this.address,
//     required this.status,
//   });

//   final String? mspSystemID;
//   final String? backyardName;
//   final String? address;
//   final String? status;

//   factory Site.fromJson(Map<String, dynamic> json) => Site(
//         mspSystemID: json["MspSystemID"],
//         backyardName: json["BackyardName"],
//         address: json["Address"],
//         status: json['Status'],
//       );

//   Map<String, dynamic> toJson() => {};

//   @override
//   List<Object?> get props => [mspSystemID];
// }
