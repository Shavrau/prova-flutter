// lib/core/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';
import '../repositories/event_repository.dart';

class FirestoreService implements EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const String _collectionName = 'Events';

  @override
  Stream<List<EventModel>> getEvents() {
    return _firestore
        .collection(_collectionName)
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => doc.data().isNotEmpty && doc.data().containsKey('title') && doc.data().containsKey('dateTime'))
            .map((doc) {
              try {
                return EventModel.fromMap(doc.data(), doc.id);
              } catch (e) {
                // Se houver erro de conversão, ignora o evento
                return null;
              }
            })
            .whereType<EventModel>()
            .toList());
  }

  @override
  Stream<List<EventModel>> getEventsByUser(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('createdBy', isEqualTo: userId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<EventModel?> getEventById(String eventId) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(eventId).get();
      if (doc.exists) {
        return EventModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar evento: $e');
    }
  }

  @override
  Future<String> addEvent(EventModel event) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      final eventData = event.copyWith(
        createdBy: user.uid,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection(_collectionName)
          .add(eventData.toMap());
      
      return docRef.id;
    } catch (e) {
      throw Exception('Erro ao criar evento: $e');
    }
  }

  @override
  Future<void> updateEvent(EventModel event) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(event.id)
          .update(event.toMap());
    } catch (e) {
      throw Exception('Erro ao atualizar evento: $e');
    }
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection(_collectionName).doc(eventId).delete();
    } catch (e) {
      throw Exception('Erro ao excluir evento: $e');
    }
  }

  @override
  Future<void> joinEvent(String eventId, String userId) async {
    try {
      await _firestore.collection(_collectionName).doc(eventId).update({
        'participants': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception('Erro ao participar do evento: $e');
    }
  }

  @override
  Future<void> leaveEvent(String eventId, String userId) async {
    try {
      await _firestore.collection(_collectionName).doc(eventId).update({
        'participants': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw Exception('Erro ao sair do evento: $e');
    }
  }
}
