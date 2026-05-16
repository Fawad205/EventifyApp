import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:location/location.dart' as loc;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final MapController _mapController = MapController();
  final loc.Location _locationService = loc.Location();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  String _selectedCategory = 'Tech Events';
  LatLng? _selectedLocation;
  bool _isSaving = false;

  final List<String> _categories = [
    'Tech Events',
    'Islamic Events',
    'Expo Events',
    'Concert'
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _imageUrlController.text = pickedFile.name;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) return;
    }

    final locationData = await _locationService.getLocation();
    if (locationData.latitude != null && locationData.longitude != null) {
      final point = LatLng(locationData.latitude!, locationData.longitude!);
      _mapController.move(point, 15.0);
      _updateLocation(point);
    }
  }

  Future<void> _updateLocation(LatLng point) async {
    setState(() {
      _selectedLocation = point;
      _locationController.text = "Loading address...";
    });

    try {
      final response = await http.get(Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['display_name'] ?? "${point.latitude}, ${point.longitude}";
        setState(() {
          _locationController.text = address;
        });
      } else {
        setState(() {
          _locationController.text = "${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}";
        });
      }
    } catch (e) {
      setState(() {
        _locationController.text = "${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}";
      });
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _createEvent() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      
      final DateTime eventDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final double price = double.tryParse(_priceController.text) ?? 0.0;

      try {
        String finalImageUrl = _imageUrlController.text.trim();
        
        // Try to upload if an image was picked from gallery
        if (_selectedImage != null) {
          final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
          
          // Try default bucket first
          try {
            final Reference storageRef = FirebaseStorage.instance.ref().child('events_images/$fileName');
            final UploadTask uploadTask = storageRef.putFile(_selectedImage!);
            final TaskSnapshot snapshot = await uploadTask;
            finalImageUrl = await snapshot.ref.getDownloadURL();
          } catch (storageError) {
            // If default fails, try the explicit .appspot.com bucket which is usually free
            final Reference altRef = FirebaseStorage.instanceFor(bucket: "event-app-928aa.appspot.com")
                .ref().child('events_images/$fileName');
            final UploadTask altTask = altRef.putFile(_selectedImage!);
            final TaskSnapshot altSnapshot = await altTask;
            finalImageUrl = await altSnapshot.ref.getDownloadURL();
          }
        } else if (finalImageUrl.isEmpty) {
          // Fallback if no gallery image AND no URL provided
          finalImageUrl = 'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=800&q=80';
        }

        final newEvent = Event(
          id: '', 
          title: _nameController.text.isEmpty ? 'Untitled Event' : _nameController.text,
          description: _descriptionController.text,
          category: _selectedCategory,
          date: eventDateTime,
          location: _locationController.text.isEmpty ? 'TBD' : _locationController.text,
          imageUrl: finalImageUrl, 
          price: price,
          latitude: _selectedLocation?.latitude,
          longitude: _selectedLocation?.longitude,
          createdBy: _auth.currentUser?.uid ?? '',
        );

        await FirebaseFirestore.instance.collection('events').add(newEvent.toMap());
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event created successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create event: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF6342E8);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: primaryPurple,
          elevation: 0,
          centerTitle: true,
          bottom: const TabBar(
            labelColor: primaryPurple,
            unselectedLabelColor: Colors.black54,
            indicatorColor: primaryPurple,
            tabs: [
              Tab(text: 'Create Event'),
              Tab(text: 'Manage Events'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Create Event
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Create New Event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    
                    // Combined Image Picker & URL Field
                    _buildTextField(
                      label: 'Image URL or Gallery',
                      hint: 'Paste a link or tap the icon below to upload',
                      controller: _imageUrlController,
                      onChanged: (value) {
                        setState(() {
                          _selectedImage = null; // Clear gallery selection if user types a URL
                        }); 
                      },
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: (MediaQuery.of(context).size.width - 60) / 2, // Approximate half width with padding
                          child: ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery', style: TextStyle(fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              foregroundColor: Colors.black87,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: (MediaQuery.of(context).size.width - 60) / 2,
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedImage = null;
                                _imageUrlController.text = 'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=800&q=80';
                              });
                            },
                            icon: const Icon(Icons.image_search, size: 18),
                            label: const Text('Sample', style: TextStyle(fontSize: 13)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (_selectedImage != null || _imageUrlController.text.isNotEmpty)
                      Container(
                        height: 150,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _selectedImage != null 
                            ? Image.file(_selectedImage!, fit: BoxFit.cover)
                            : Image.network(
                                _imageUrlController.text.trim(),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.broken_image, color: Colors.red, size: 40),
                                        Text('Invalid image link', style: TextStyle(color: Colors.red, fontSize: 12)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                        ),
                      ),
                    
                    // Event Name
                    _buildTextField(
                      label: 'Event Name',
                      hint: 'e.g., Annual Tech Summit 2026',
                      controller: _nameController,
                      validator: (value) => value == null || value.isEmpty ? 'Please enter event name' : null,
                    ),
                    const SizedBox(height: 16),

                    // Date & Time Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickDate,
                            child: InputDecorator(
                              decoration: _inputDecoration('Date'),
                              child: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _pickTime,
                            child: InputDecorator(
                              decoration: _inputDecoration('Start Time'),
                              child: Text(_selectedTime.format(context)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration('Category'),
                      initialValue: _selectedCategory,
                      items: _categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedCategory = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Location Map
                    const Text('Pin Location on Map', style: TextStyle(fontSize: 14, color: Colors.black87)),
                    const SizedBox(height: 8),
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: const LatLng(31.4187, 73.0791),
                                initialZoom: 13.0,
                                onTap: (tapPosition, point) => _updateLocation(point),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.eventify',
                                ),
                                if (_selectedLocation != null)
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: _selectedLocation!,
                                        width: 40,
                                        height: 40,
                                        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            Positioned(
                              right: 16,
                              bottom: 16,
                              child: FloatingActionButton.small(
                                onPressed: _getCurrentLocation,
                                backgroundColor: primaryPurple,
                                child: const Icon(Icons.my_location, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Location Name / Coords
                    _buildTextField(
                      label: 'Location Details',
                      hint: 'Tap on map or type address...',
                      controller: _locationController,
                      maxLines: 3,
                      minLines: 1,
                      validator: (value) => value == null || value.isEmpty ? 'Please enter location' : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    _buildTextField(
                      label: 'Description',
                      hint: 'Tell people what this event is about...',
                      controller: _descriptionController,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),

                    // Price
                    _buildTextField(
                      label: 'Ticket Price (PKR)',
                      hint: 'e.g. 2500',
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _createEvent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSaving 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Create Event', style: TextStyle(fontSize: 16, color: Colors.white)),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward, color: Colors.white),
                                ],
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
            
            // Tab 2: Manage Events
            _buildManageEventsTab(primaryPurple),
          ],
        ),
      ),
    );
  }

  Widget _buildManageEventsTab(Color primaryPurple) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('createdBy', isEqualTo: _auth.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No events to manage.'));
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final event = Event.fromFirestore(doc);
            final bool isPast = event.date.isBefore(DateTime.now());

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    event.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], width: 60, height: 60, child: const Icon(Icons.image)),
                  ),
                ),
                title: Text(
                  event.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(DateFormat('MMM dd, yyyy | hh:mm a').format(event.date)),
                    if (isPast)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'FINISHED',
                          style: TextStyle(color: Colors.red[700], fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDelete(context, doc.id, event.title),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String docId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event?'),
        content: Text('Are you sure you want to delete "$title"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance.collection('events').doc(docId).delete();
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Event deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int? maxLines = 1,
    int? minLines,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          minLines: minLines,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          decoration: _inputDecoration(hint),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6342E8)),
      ),
    );
  }
}
