// lib/core/controllers/event_controller.dart
import 'package:flutter/foundation.dart';
import '../repositories/event_repository.dart';
import '../models/event_model.dart';
import 'package:provider/provider.dart';
import '../providers/user_model_provider.dart';

class EventController extends ChangeNotifier {
  final EventRepository _eventRepository;

  EventController(this._eventRepository);

  // Streams
  Stream<List<EventModel>> getEvents() => _eventRepository.getEvents();
  
  Stream<List<EventModel>> getEventsByUser(String userId) => 
      _eventRepository.getEventsByUser(userId);

  // Novo método: usa o id do usuário logado do Provider global
  Stream<List<EventModel>> getEventsByCurrentUser(context) {
    final userProvider = Provider.of<UserModelProvider>(context, listen: false);
    final userId = userProvider.user?.uid ?? '';
    return _eventRepository.getEventsByUser(userId);
  }

  // CRUD Operations
  Future<EventModel?> getEventById(String eventId) => 
      _eventRepository.getEventById(eventId);

  Future<String> addEvent(EventModel event) async {
    try {
      final eventId = await _eventRepository.addEvent(event);
      notifyListeners();
      return eventId;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateEvent(EventModel event) async {
    try {
      await _eventRepository.updateEvent(event);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _eventRepository.deleteEvent(eventId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Participation Operations
  Future<void> joinEvent(String eventId, String userId) async {
    try {
      await _eventRepository.joinEvent(eventId, userId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> leaveEvent(String eventId, String userId) async {
    try {
      await _eventRepository.leaveEvent(eventId, userId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Utility Methods
  bool isUserParticipating(EventModel event, String userId) {
    return event.participants.contains(userId);
  }

  bool isUserOrganizer(EventModel event, String userId) {
    return event.createdBy == userId;
  }
}
