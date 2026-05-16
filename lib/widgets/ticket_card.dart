import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';

class TicketCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const TicketCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF6342E8);
    final double ticketHeight = 140;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: ticketHeight,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipPath(
          clipper: TicketClipper(cutoutX: 0.72),
          child: Container(
            color: Colors.white,
            child: Row(
              children: [
                // Main Section (Info)
                Expanded(
                  flex: 72,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Event Image Thumbnail
                        Hero(
                          tag: 'ticket_image_${event.id}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[200],
                              child: event.imageUrl.isEmpty
                                  ? const Icon(Icons.image, color: Colors.grey)
                                  : Image.network(event.imageUrl, fit: BoxFit.cover),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Text Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      event.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  _buildStatusBadge(event.date),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 12, color: primaryPurple),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(event.date),
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 12, color: primaryPurple),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('hh:mm a').format(event.date),
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 12, color: primaryPurple),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      event.venueName.isEmpty ? event.location : "${event.venueName}\n${event.location}",
                                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Dashed Divider
                CustomPaint(
                  size: Size(1, ticketHeight),
                  painter: VerticalDashedLinePainter(),
                ),

                // Stub Section (Action)
                Expanded(
                  flex: 28,
                  child: Container(
                    decoration: BoxDecoration(
                      color: primaryPurple.withValues(alpha: 0.03),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryPurple.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.qr_code_2, color: primaryPurple, size: 24),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'VIEW',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: primaryPurple,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Text(
                          'TICKET',
                          style: TextStyle(
                            fontSize: 8,
                            color: primaryPurple,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(DateTime eventDate) {
    final now = DateTime.now();
    final bool isFinished = now.isAfter(eventDate);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isFinished ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isFinished ? 'FINISHED' : 'UPCOMING',
        style: TextStyle(
          color: isFinished ? Colors.red[700] : Colors.green[700],
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class TicketClipper extends CustomClipper<Path> {
  final double cutoutX;
  final double cutoutRadius;

  TicketClipper({required this.cutoutX, this.cutoutRadius = 10.0});

  @override
  Path getClip(Size size) {
    Path path = Path();
    double x = size.width * cutoutX;

    path.moveTo(0, 0);
    // Top line with cutout
    path.lineTo(x - cutoutRadius, 0);
    path.arcToPoint(
      Offset(x + cutoutRadius, 0),
      radius: Radius.circular(cutoutRadius),
      clockwise: false,
    );
    path.lineTo(size.width, 0);
    
    // Right side
    path.lineTo(size.width, size.height);
    
    // Bottom line with cutout
    path.lineTo(x + cutoutRadius, size.height);
    path.arcToPoint(
      Offset(x - cutoutRadius, size.height),
      radius: Radius.circular(cutoutRadius),
      clockwise: false,
    );
    path.lineTo(0, size.height);
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class VerticalDashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 5, dashSpace = 3, startY = 0;
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
