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
}
