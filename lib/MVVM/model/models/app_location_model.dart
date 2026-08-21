class AppLocationModel {
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String district;
  final String? city;
  final String? state;
  final String? pincode;

  AppLocationModel({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    required this.district,
    this.city,
    this.state,
    this.pincode,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'formattedAddress': formattedAddress,
      'district': district,
      'city': city,
      'state': state,
      'pincode': pincode,
    };
  }

  factory AppLocationModel.fromJson(Map<String, dynamic> json) {
    return AppLocationModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      formattedAddress: json['formattedAddress'] ?? '',
      district: json['district'] ?? '',
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
    );
  }
}
