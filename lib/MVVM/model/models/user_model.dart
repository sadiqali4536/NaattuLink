import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String? uid;
  final String? role;
  final String? username;
  final String? phone;
  final String? address;
  final FieldValue? createAt;
  final String? profileUrl;
  final String? email;
  final String? userPublicId;
  final String? authUid;

  UserModel( {
    this.role,
    this.uid,
    this.username,
    this.phone,
    this.address,
    this.createAt,
    this.profileUrl,
    this.email,
    this.userPublicId,
    this.authUid,
  });

  // Factory constructor to create a UserModel from Map
  factory UserModel.fromMap(Map<String, dynamic> Map) {
    return UserModel(
      uid: Map['uid'] as String?,
      role: Map['role'] as String?,
      username: Map['username'] as String?,
      phone: Map['phone'] as String?,
      address: Map['address'] as String?,
      createAt: Map['createAt'],
      profileUrl: Map['profileUrl'] as String?,
      email: Map['email'] as String?,
      userPublicId: Map['userPublicId'] as String?,
      authUid: Map['authUid'] as String?,
    );
  }

  // Convert UserModel to Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'role':role,
      'username': username,
      'phone': phone,
      'address': address,
      'createAt': createAt,
      'profileUrl': profileUrl,
      'email': email,
      'userPublicId': userPublicId,
      'authUid': authUid,
    };
  }
}
