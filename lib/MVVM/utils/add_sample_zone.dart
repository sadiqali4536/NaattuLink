import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ZoneSeeder {
  static Future<void> addSampleZone() async {
    try {
      final existing = await FirebaseFirestore.instance
          .collection('zones')
          .where('name', isEqualTo: 'Kozhikode Central')
          .where('districtId', isEqualTo: 'kozhikode')
          .get();

      final data = {
        'name': 'Kozhikode Central',
        'active': true,
        'districtId': 'kozhikode',
        'polygon': [
          {'lat': 11.3101, 'lng': 75.7501}, // Top-Left
          {'lat': 11.3101, 'lng': 75.8302}, // Top-Right
          {'lat': 11.2103, 'lng': 75.8301}, // Bottom-Right
          {'lat': 11.2101, 'lng': 75.7502}, // Bottom-Left
        ]
      };

      if (existing.docs.isNotEmpty) {
        // Update the first one
        await existing.docs.first.reference.update(data);
        
        // Clean up any duplicates that were created previously
        if (existing.docs.length > 1) {
          for (int i = 1; i < existing.docs.length; i++) {
            await existing.docs[i].reference.delete();
          }
          debugPrint("Sample Zone Updated and ${existing.docs.length - 1} duplicates removed!");
        } else {
          debugPrint("Sample Zone Updated Successfully!");
        }
      } else {
        // Create new if it doesn't exist at all
        await FirebaseFirestore.instance.collection('zones').add(data);
        debugPrint("Sample Zone Added Successfully!");
      }
    } catch (e) {
      debugPrint("Error managing zone: $e");
    }
  }
}
