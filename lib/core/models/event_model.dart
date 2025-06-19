import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final String location;
  final String createdBy;
  final DateTime createdAt;
  final String status;
  final List<String> participants;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.location,
    required this.createdBy,
    required this.createdAt,
    this.status = 'active',
    this.participants = const [],
  });

  factory EventModel.fromMap(Map<String, dynamic> map, String documentId) {
    // Validação defensiva dos campos essenciais
    if (map['title'] == null || map['dateTime'] == null || map['location'] == null || map['createdBy'] == null || map['createdAt'] == null) {
      throw Exception('Documento inválido para EventModel: campos essenciais ausentes.');
    }
    if (map['title'] is! String || map['location'] is! String || map['createdBy'] is! String) {
      throw Exception('Documento inválido para EventModel: tipos incorretos.');
    }
    // dateTime e createdAt podem ser Timestamp ou DateTime
    final dateTime = (map['dateTime'] is Timestamp)
        ? (map['dateTime'] as Timestamp).toDate()
        : (map['dateTime'] is DateTime)
            ? map['dateTime'] as DateTime
            : null;
    final createdAt = (map['createdAt'] is Timestamp)
        ? (map['createdAt'] as Timestamp).toDate()
        : (map['createdAt'] is DateTime)
            ? map['createdAt'] as DateTime
            : null;
    if (dateTime == null || createdAt == null) {
      throw Exception('Documento inválido para EventModel: datas inválidas.');
    }
    return EventModel(
      id: documentId,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      dateTime: dateTime,
      location: map['location'] as String,
      createdBy: map['createdBy'] as String,
      createdAt: createdAt,
      status: map['status'] as String? ?? 'active',
      participants: (map['participants'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'dateTime': Timestamp.fromDate(dateTime),
      'location': location,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'participants': participants,
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    String? location,
    String? createdBy,
    DateTime? createdAt,
    String? status,
    List<String>? participants,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      participants: participants ?? this.participants,
    );
  }

  @override
  String toString() {
    return 'EventModel(id: $id, title: $title, dateTime: $dateTime, location: $location)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
