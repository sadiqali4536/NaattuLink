class AppLocationModel {
  final String? id;
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String district;
  final String? city;
  final String? state;
  final String? pincode;

  // New fields for robust address flow
  final String? receiverName;
  final String? receiverPhone;
  final String? alternatePhone;
  final String? landmark;
  final String? addressType; // 'Home', 'Work', 'Other'
  final bool? isPrimary;
  final String? zoneId;
  final String? zoneName;

  AppLocationModel({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    required this.district,
    this.city,
    this.state,
    this.pincode,
    this.receiverName,
    this.receiverPhone,
    this.alternatePhone,
    this.landmark,
    this.addressType,
    this.isPrimary,
    this.zoneId,
    this.zoneName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'formattedAddress': formattedAddress,
      'district': district,
      'city': city,
      'state': state,
      'pincode': pincode,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'alternatePhone': alternatePhone,
      'landmark': landmark,
      'addressType': addressType,
      'isPrimary': isPrimary,
      'zoneId': zoneId,
      'zoneName': zoneName,
    };
  }

  factory AppLocationModel.fromJson(Map<String, dynamic> json) {
    return AppLocationModel(
      id: json['id'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      formattedAddress: json['formattedAddress'] ?? '',
      district: json['district'] ?? '',
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      receiverName: json['receiverName'],
      receiverPhone: json['receiverPhone'],
      alternatePhone: json['alternatePhone'],
      landmark: json['landmark'],
      addressType: json['addressType'],
      isPrimary: json['isPrimary'],
      zoneId: json['zoneId'],
      zoneName: json['zoneName'],
    );
  }

  AppLocationModel copyWith({
    String? id,
    double? latitude,
    double? longitude,
    String? formattedAddress,
    String? district,
    String? city,
    String? state,
    String? pincode,
    String? receiverName,
    String? receiverPhone,
    String? alternatePhone,
    String? landmark,
    String? addressType,
    bool? isPrimary,
    String? zoneId,
    String? zoneName,
  }) {
    return AppLocationModel(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      district: district ?? this.district,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      landmark: landmark ?? this.landmark,
      addressType: addressType ?? this.addressType,
      isPrimary: isPrimary ?? this.isPrimary,
      zoneId: zoneId ?? this.zoneId,
      zoneName: zoneName ?? this.zoneName,
    );
  }
}
