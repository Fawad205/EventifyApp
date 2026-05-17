import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'package:location/location.dart' as loc;
import '../models/event_model.dart';
import '../widgets/event_card.dart';
import '../services/theme_service.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final Color primaryPurple = const Color(0xFF6342E8);
  late TabController _tabController;
  final loc.Location _locationService = loc.Location();
  Future<List<Event>>? _nearbyFuture;
  List<Event> _currentEvents = [];

  Widget _buildEventList(List<Event> events) {
    if (events.isEmpty) {
      return Center(
        child: Text('No events found in this category.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return EventCard(event: events[index]);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.index == 1 && _nearbyFuture == null && _currentEvents.isNotEmpty) {
      setState(() {
        _nearbyFuture = _fetchNearby(context, _currentEvents);
      });
    }
  }

  double _deg2rad(double deg) => deg * (math.pi / 180);

  double _distanceInKm(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // Earth radius in km
    final double dLat = _deg2rad(lat2 - lat1);
    final double dLon = _deg2rad(lon2 - lon1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.asin(math.sqrt(a));
    return R * c;
  }

  Future<List<Event>> _fetchNearby(BuildContext context, List<Event> events) async {
    try {
      await _locationService.changeSettings(accuracy: loc.LocationAccuracy.high);
      
      bool serviceEnabled = await _locationService.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _locationService.requestService();
        if (!serviceEnabled) return [];
      }

      var permissionGranted = await _locationService.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await _locationService.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) return [];
      }

      if (!mounted) return [];
      final locationData = await _locationService.getLocation().timeout(const Duration(seconds: 5));
      if (!mounted) return [];
      if (locationData.latitude == null || locationData.longitude == null) return [];
      final double userLat = locationData.latitude!;
      final double userLon = locationData.longitude!;

      final List<Event> nearby = [];
      for (final e in events) {
        if (e.latitude != null && e.longitude != null) {
          final d = _distanceInKm(userLat, userLon, e.latitude!, e.longitude!);
          // 20km radius as requested
          if (d <= 20.0) nearby.add(e);
        }
      }

      return nearby;
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () {},
        ),
        title: const Text(
          'Eventify',
          style: TextStyle(
            color: Color(0xFF6342E8),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              ThemeService().isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () => setState(() => ThemeService().toggleTheme()),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: primaryPurple,
          ),
          dividerColor: Colors.transparent,
          tabAlignment: TabAlignment.start,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          labelPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          tabs: const [
            Text('All Events', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('Nearby', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('Tech Events', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('Islamic Events', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('Expo Events', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('Concert', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .where('date', isGreaterThanOrEqualTo: Timestamp.now())
            .orderBy('date')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryPurple));
          }

          final List<Event> events = snapshot.data!.docs
              .map((doc) => Event.fromFirestore(doc))
              .toList();

          // keep a copy for the tab-change listener
          _currentEvents = events;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_tabController.index == 1 && _nearbyFuture == null) {
              setState(() {
                _nearbyFuture = _fetchNearby(context, events);
              });
            }
          });

          Widget nearbyWidget;
          if (_nearbyFuture == null) {
            nearbyWidget = Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.my_location),
                label: const Text('Find nearby events'),
                style: ElevatedButton.styleFrom(backgroundColor: primaryPurple),
                onPressed: () {
                  setState(() {
                    _nearbyFuture = _fetchNearby(context, events);
                  });
                },
              ),
            );
          } else {
            nearbyWidget = FutureBuilder<List<Event>>(
              future: _nearbyFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: primaryPurple));
                } else if (snap.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Error: ${snap.error}', style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _nearbyFuture = _fetchNearby(context, events);
                            });
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                } else {
                  final nearby = snap.data ?? [];
                  if (nearby.isEmpty) {
                    return Center(
                      child: Text(
                        'No events found within 20 km.', 
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)
                      )
                    );
                  }
                  return _buildEventList(nearby);
                }
              },
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // All Events Tab
              _buildEventList(events),
              // Nearby Tab
              nearbyWidget,
              // Tech Events Tab
              _buildEventList(events.where((e) => e.category == 'Tech Events').toList()),
              // Islamic Events Tab
              _buildEventList(events.where((e) => e.category == 'Islamic Events').toList()),
              // Expo Events Tab
              _buildEventList(events.where((e) => e.category == 'Expo Events').toList()),
              // Concert Tab
              _buildEventList(events.where((e) => e.category == 'Concert').toList()),
            ],
          );
        },
      ),
    );
  }
}
