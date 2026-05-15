import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/event_model.dart';
import '../services/auth_service.dart';
import '../services/map_service.dart';

class DigitalTicketScreen extends StatelessWidget {
  final Event event;
  final String ticketId;

  const DigitalTicketScreen({
    super.key, 
    required this.event, 
    this.ticketId = 'TKT-8829-XJ-2024', // Default for demo
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF6342E8);
    const Color secondaryPurple = Color(0xFFF3F0FF);
    final user = AuthService().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.menu, color: Colors.black54),
                  const Text(
                    'Eventify',
                    style: TextStyle(
                      color: primaryPurple,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: user?.photoURL != null 
                      ? NetworkImage(user!.photoURL!) 
                      : const AssetImage('assets/images/google.png') as ImageProvider,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Page Title
              const Text(
                'Your Ticket',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Text(
                'Present this QR code at the entrance',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),

              // Ticket Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Event Image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: event.imageUrl.isEmpty 
                          ? const Icon(Icons.image, size: 50, color: Colors.grey)
                          : Image.network(event.imageUrl, fit: BoxFit.cover),
                      ),
                    ),
                    
                    // Event Details
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildDetailItem('Date & Time', DateFormat('MMM dd, h:mm a').format(event.date)),
                              const Spacer(),
                              _buildDetailItem('Seat / Zone', 'VIP - Row A'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Location',
                            style: TextStyle(fontSize: 12, color: Colors.black45),
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () {
                              if (event.latitude != null && event.longitude != null) {
                                MapService.openMap(event.latitude!, event.longitude!);
                              }
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: primaryPurple),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    event.location,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Dashed Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: CustomPaint(
                        size: const Size(double.infinity, 1),
                        painter: DashedLinePainter(),
                      ),
                    ),

                    // QR Code Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                      ),
                      child: Column(
                        children: [
                          QrImageView(
                            data: ticketId,
                            version: QrVersions.auto,
                            size: 140.0,
                            gapless: false,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            ticketId,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            event.price == 0 ? 'Free' : 'Rs. ${event.price.toStringAsFixed(0)} Paid',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: primaryPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download Ticket'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share with Friend'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryPurple,
                  foregroundColor: primaryPurple,
                  minimumSize: const Size(double.infinity, 56),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black45),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 5, dashSpace = 5, startX = 0;
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
