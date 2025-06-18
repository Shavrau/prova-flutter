import 'package:cloud_firestore/cloud_firestore.dart'; // Importação necessária

class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final String organizerId;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.organizerId,
  });

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      date: (map['date'] as Timestamp).toDate(), // Corrigido
      location: map['location'] as String,
      organizerId: map['organizerId'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date), // Corrigido
      'location': location,
      'organizerId': organizerId,
    };
  }
}
