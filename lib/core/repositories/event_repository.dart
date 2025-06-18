// lib/core/repositories/event_repository.dart
import '../models/event_model.dart';

abstract class EventRepository {
  Stream<List<EventModel>> getEvents();
  Future<void> addEvent(EventModel event);
  Future<void> updateEvent(EventModel event);
  Future<void> deleteEvent(String eventId);
}
