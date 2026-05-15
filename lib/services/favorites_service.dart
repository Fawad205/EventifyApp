import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference for user-specific favorites
  CollectionReference get _favoritesRef {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    return _firestore.collection('users').doc(user.uid).collection('favorites');
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String eventId, Map<String, dynamic> eventData) async {
    final doc = _favoritesRef.doc(eventId);
    final snapshot = await doc.get();

    if (snapshot.exists) {
      await doc.delete();
    } else {
      await doc.set({
        ...eventData,
        'favoritedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Check if an event is favorited
  Stream<bool> isFavorited(String eventId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(eventId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  // Get all favorites for the current user
  Stream<QuerySnapshot> getFavorites() {
    return _favoritesRef.orderBy('favoritedAt', descending: true).snapshots();
  }
}
