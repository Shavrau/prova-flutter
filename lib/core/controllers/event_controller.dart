// lib/core/controllers/event_controller.dart
import '../repositories/event_repository.dart';
import '../models/event_model.dart';

class EventController {
  final EventRepository _eventRepository;

  EventController(this._eventRepository);

  Stream<List<EventModel>> getEvents() => _eventRepository.getEvents();

  Future<void> addEvent(EventModel event) => _eventRepository.addEvent(event);

  Future<void> updateEvent(EventModel event) =>
      _eventRepository.updateEvent(event);

  Future<void> deleteEvent(String eventId) =>
      _eventRepository.deleteEvent(eventId);
}
