class Event {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime date;
  final String location;
  final String imageUrl;
  final double price;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.date,
    required this.location,
    required this.imageUrl,
    required this.price,
  });
}
