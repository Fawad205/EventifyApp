import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TicketsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _ticketsRef {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    return _firestore.collection('users').doc(user.uid).collection('tickets');
  }

  // Add an event to the user's tickets
  Future<void> addTicket(String eventId, Map<String, dynamic> eventData) async {
    final doc = _ticketsRef.doc(eventId);
    await doc.set({
      ...eventData,
      'purchasedAt': FieldValue.serverTimestamp(),
    });
  }

  // Check if user already has a ticket for this event
  Stream<bool> hasTicketStream(String eventId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tickets')
        .doc(eventId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  // Get all tickets for the current user
  Stream<QuerySnapshot> getTickets() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tickets')
        .orderBy('purchasedAt', descending: true)
        .snapshots();
  }

  // Delete a specific ticket
  Future<void> deleteTicket(String ticketId) async {
    await _ticketsRef.doc(ticketId).delete();
  }

  // Remove tickets that are older than 5 hours after the event time
  Future<void> cleanupExpiredTickets() async {
    try {
      final snapshot = await _ticketsRef.get();
      final now = DateTime.now();
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['date'] != null) {
          final eventDate = (data['date'] as Timestamp).toDate();
          final expiryDate = eventDate.add(const Duration(hours: 5));
          
          if (now.isAfter(expiryDate)) {
            await doc.reference.delete();
          }
        }
      }
    } catch (e) {
      // Log error in a production-safe way
    }
  }
}
