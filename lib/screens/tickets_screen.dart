import 'package:flutter/material.dart';
import '../services/tickets_service.dart';
import '../models/event_model.dart';
import '../widgets/ticket_card.dart';
import 'digital_ticket_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final ticketsService = TicketsService();

  @override
  void initState() {
    super.initState();
    // Run background cleanup when screen loads
    _cleanupTickets();
  }

  Future<void> _cleanupTickets() async {
    await ticketsService.cleanupExpiredTickets();
    if (mounted) setState(() {}); // Refresh if needed
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF6342E8);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text(
          'My Tickets', 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          )
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ticketsService.getTickets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryPurple));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Icon(Icons.confirmation_number_outlined, size: 64, color: primaryPurple.withValues(alpha: 0.3)),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No tickets found',
                    style: TextStyle(fontSize: 20, color: Colors.black87, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Events you join will appear here.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final ticketDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: ticketDocs.length,
            itemBuilder: (context, index) {
              final ticketId = ticketDocs[index].id;
              final ticketData = ticketDocs[index].data() as Map<String, dynamic>;
              
              // We use StreamBuilder to get real-time updates for this specific event
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('events').doc(ticketId).snapshots(),
                builder: (context, eventSnapshot) {
                  // If the main event exists, use its latest data. 
                  // Otherwise, fall back to the cached data in the ticket.
                  Event displayEvent;
                  if (eventSnapshot.hasData && eventSnapshot.data!.exists) {
                    displayEvent = Event.fromFirestore(eventSnapshot.data!);
                  } else {
                    displayEvent = Event.fromMap(ticketData).copyWith(id: ticketId);
                  }

                  return TicketCard(
                    event: displayEvent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DigitalTicketScreen(
                            event: displayEvent,
                            ticketId: 'TKT-${ticketId.substring(0, 5).toUpperCase()}',
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
