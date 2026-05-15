import 'package:flutter/material.dart';
import '../services/tickets_service.dart';
import '../models/event_model.dart';
import '../widgets/event_card.dart';
import 'digital_ticket_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TicketsScreen extends StatelessWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ticketsService = TicketsService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Tickets', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ticketsService.getTickets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.confirmation_number_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'No tickets found',
                    style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
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
            padding: const EdgeInsets.all(16),
            itemCount: ticketDocs.length,
            itemBuilder: (context, index) {
              final data = ticketDocs[index].data() as Map<String, dynamic>;
              final event = Event.fromMap(data).copyWith(id: ticketDocs[index].id);
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DigitalTicketScreen(
                        event: event,
                        ticketId: 'TKT-${ticketDocs[index].id.substring(0, 5).toUpperCase()}',
                      ),
                    ),
                  );
                },
                child: AbsorbPointer(child: EventCard(event: event)),
              );
            },
          );
        },
      ),
    );
  }
}
