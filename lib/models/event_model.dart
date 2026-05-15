import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime date;
  final String location;
  final String imageUrl;
  final double price;
  final double? latitude;
  final double? longitude;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.date,
    required this.location,
    required this.imageUrl,
    required this.price,
    this.latitude,
    this.longitude,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Event.fromMap(data).copyWith(id: doc.id);
  }

  factory Event.fromMap(Map<String, dynamic> data) {
    return Event(
      id: '', // Temporary or passed via copyWith
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: data['location'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
    );
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    DateTime? date,
    String? location,
    String? imageUrl,
    double? price,
    double? latitude,
    double? longitude,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      date: date ?? this.date,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'date': Timestamp.fromDate(date),
      'location': location,
      'imageUrl': imageUrl,
      'price': price,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
