import 'package:cloud_firestore/cloud_firestore.dart';

class PublicIdGenerator {
  static Future<String> generateUserId() async {
    return await _generateId('user_counter', 'NL-USR-');
  }

  static Future<String> generateSellerId() async {
    return await _generateId('seller_counter', 'NL-SLR-');
  }

  static Future<String> generateProductId() async {
    return await _generateId('product_counter', 'NL-PRD-');
  }

  static Future<String> generateWorkerId() async {
    return await _generateId('worker_counter', 'NL-WKR-');
  }

  static Future<String> generateTransportId() async {
    return await _generateId('transport_counter', 'NL-TRN-');
  }

  static Future<String> generateHealthcareId() async {
    return await _generateId('healthcare_counter', 'NL-HLT-');
  }

  static Future<String> generateBusinessId() async {
    return await _generateId('business_counter', 'NL-BISN-');
  }

  static Future<String> _generateId(String counterDoc, String prefix) async {
    final counterRef = FirebaseFirestore.instance.collection('system_counters').doc(counterDoc);
    
    return await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);
      
      int nextId = 1;
      if (snapshot.exists) {
        nextId = (snapshot.data()?['currentId'] as int? ?? 0) + 1;
        transaction.update(counterRef, {'currentId': nextId});
      } else {
        transaction.set(counterRef, {'currentId': nextId});
      }
      
      final paddedId = nextId.toString().padLeft(6, '0');
      return '$prefix$paddedId';
    });
  }
}
