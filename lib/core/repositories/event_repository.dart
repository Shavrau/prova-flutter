// lib/core/repositories/event_repository.dart
import '../models/event_model.dart';

abstract class EventRepository {
  Stream<List<EventModel>> getEvents();
  Stream<List<EventModel>> getEventsByUser(String userId);
  Future<EventModel?> getEventById(String eventId);
  Future<String> addEvent(EventModel event);
  Future<void> updateEvent(EventModel event);
  Future<void> deleteEvent(String eventId);
  Future<void> joinEvent(String eventId, String userId);
  Future<void> leaveEvent(String eventId, String userId);
}
