import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:naattulink/MVVM/model/models/queue_model.dart';

import 'package:naattulink/MVVM/utils/service_functions/auth_lookup_service.dart';

class QueueRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _getTodayDateString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// Attempts to assign a new token atomically.
  Future<Map<String, dynamic>> assignTokenAtomically({
    required String businessPublicId,
    required String businessDocId,
    required ParticipantIdentity participant,
    String? serviceId,
    String? serviceName,
    String collectionName = 'businesses',
  }) async {
    final businessRef =
        _firestore.collection(collectionName).doc(businessDocId);
    final String todayDate = _getTodayDateString();
    final queueStateRef = businessRef.collection('queue_state').doc(todayDate);
    final activeQueueRef = _firestore
        .collection(participant.collection)
        .doc(participant.documentId)
        .collection('active_queue')
        .doc(businessPublicId);

    try {
      final result = await _firestore.runTransaction((transaction) async {
        // 1. Read business config
        final businessDoc = await transaction.get(businessRef);
        if (!businessDoc.exists) {
          return {'success': false, 'error': 'business_not_found'};
        }

        final data = businessDoc.data()!;
        final bool queueEnabled = data['queueEnabled'] ?? false;
        final int maxQueueCapacity = data['maxQueueCapacity'] ?? 30;
        final int averageServiceTime = data['averageServiceTime'] ?? 20;

        if (!queueEnabled) {
          return {'success': false, 'error': 'queue_disabled'};
        }

        final status = (data['status'] ?? '').toString().toLowerCase();
        final isVerified = data['isVerified'];
        final bool isApproved = (status == 'approved' ||
            status == 'active' ||
            status == 'verified' ||
            status == 'pending' ||
            isVerified == 1);

        if (!isApproved) {
          return {'success': false, 'error': 'business_not_approved'};
        }

        // 2. Check for duplicate active tokens via user's active_queue document
        final activeQueueDoc = await transaction.get(activeQueueRef);
        if (activeQueueDoc.exists) {
          final aqData = activeQueueDoc.data()!;
          final aqStatus = aqData['status'] ?? '';
          if (['waiting', 'called', 'in_service'].contains(aqStatus) &&
              aqData['queueDate'] == todayDate) {
            return {
              'success': true,
              'existing': true,
              'token': QueueTokenModel.fromJson(aqData['queueId'], aqData)
            };
          }
        }

        // 3. Read queue state
        final queueStateDoc = await transaction.get(queueStateRef);
        QueueStateModel queueState;

        if (queueStateDoc.exists) {
          queueState = QueueStateModel.fromJson(queueStateDoc.data()!);
          if (queueState.queueDate != todayDate) {
            queueState = QueueStateModel(
              queueDate: todayDate,
              currentToken: 0,
              nextToken: 1,
              waitingCount: 0,
              isOpen: true,
            );
          }
        } else {
          queueState = QueueStateModel(
            queueDate: todayDate,
            currentToken: 0,
            nextToken: 1,
            waitingCount: 0,
            isOpen: true,
          );
        }

        if (!queueState.isOpen) {
          return {'success': false, 'error': 'queue_closed'};
        }

        if (queueState.waitingCount >= maxQueueCapacity) {
          return {'success': false, 'error': 'queue_full'};
        }

        // 4. Determine next token and wait time
        final int assignedToken = queueState.nextToken;
        final int peopleAhead =
            (assignedToken - queueState.currentToken - 1).clamp(0, 9999);
        final int estimatedWait = peopleAhead * averageServiceTime;

        // 5. Update state
        queueState.nextToken += 1;
        queueState.waitingCount += 1;

        final newTokenRef = businessRef.collection('queue').doc(); // Auto ID
        final newToken = QueueTokenModel(
          tokenNumber: assignedToken,
          userId: participant.documentId,
          userPublicId: participant.publicId,
          customerName: participant.name,
          participantType: participant.type,
          participantCollection: participant.collection,
          participantDocumentId: participant.documentId,
          participantPhone: participant.phone,
          participantImage: participant.image,
          businessId: businessDocId,
          businessPublicId: businessPublicId,
          serviceId: serviceId,
          serviceName: serviceName,
          status: 'waiting',
          estimatedWaitMinutes: estimatedWait,
          queueDate: todayDate,
        );

        // 6. Commit
        transaction.set(queueStateRef, queueState.toJson());
        transaction.set(newTokenRef, newToken.toJson());

        final businessName =
            data['facility_name'] ?? data['username'] ?? 'Unknown Business';

        // 7. Store user active queue ref
        transaction.set(activeQueueRef, {
          'businessPublicId': businessPublicId,
          'businessId': businessDocId,
          'queueId': newTokenRef.id,
          'businessName': businessName,
          'tokenNumber': assignedToken,
          'status': 'waiting',
          'queueDate': todayDate,
          'updatedAt': FieldValue.serverTimestamp(),
          'estimatedWaitMinutes': estimatedWait,
        });

        newToken.id = newTokenRef.id;
        return {'success': true, 'existing': false, 'token': newToken};
      });

      return result;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> cancelTokenAtomically({
    required String businessDocId,
    required String businessPublicId,
    required String tokenId,
    required ParticipantIdentity participant,
    String collectionName = 'businesses',
  }) async {
    final businessRef =
        _firestore.collection(collectionName).doc(businessDocId);
    final String todayDate = _getTodayDateString();
    final queueStateRef = businessRef.collection('queue_state').doc(todayDate);
    final tokenRef = businessRef.collection('queue').doc(tokenId);
    final activeQueueRef = _firestore
        .collection(participant.collection)
        .doc(participant.documentId)
        .collection('active_queue')
        .doc(businessPublicId);

    try {
      final result = await _firestore.runTransaction((transaction) async {
        final businessDoc = await transaction.get(businessRef);
        if (!businessDoc.exists) {
          return {'success': false, 'error': 'business_not_found'};
        }

        final bool allowCancel =
            businessDoc.data()!['allowCancelToken'] ?? true;
        if (!allowCancel) {
          return {'success': false, 'error': 'cancellation_disabled'};
        }

        final tokenDoc = await transaction.get(tokenRef);
        if (!tokenDoc.exists) {
          return {'success': false, 'error': 'token_not_found'};
        }

        final tokenData = tokenDoc.data()!;
        if (tokenData['userId'] != participant.documentId && tokenData['userPublicId'] != participant.publicId && tokenData['participantDocumentId'] != participant.documentId) {
          return {'success': false, 'error': 'unauthorized'};
        }

        if (tokenData['status'] != 'waiting') {
          return {'success': false, 'error': 'cannot_cancel_current_status'};
        }

        final queueStateDoc = await transaction.get(queueStateRef);
        if (queueStateDoc.exists) {
          final queueState = QueueStateModel.fromJson(queueStateDoc.data()!);
          if (queueState.waitingCount > 0) {
            transaction.update(queueStateRef, {
              'waitingCount': FieldValue.increment(-1),
            });
          }
        }

        transaction.update(tokenRef, {
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
        });

        // Update active queue ref status
        transaction.update(activeQueueRef, {
          'status': 'cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return {'success': true};
      });

      return result;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
