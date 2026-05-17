import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event_model.dart';
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _venueNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  String _selectedCategory = 'Tech Events';
  bool _isSaving = false;
  String? _editingEventId;
  late TabController _tabController;

  final List<String> _categories = [
    'Tech Events',
    'Islamic Events',
    'Expo Events',
    'Concert'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    _venueNameController.dispose();
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

  Future<void> _openGoogleMaps() async {
    final Uri url = Uri.parse('https://maps.google.com');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
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

  Future<void> _saveEvent() async {
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

        double? lat;
        double? lng;
        
        try {
          final urlStr = _locationController.text.trim();
          if (urlStr.isNotEmpty) {
            final urlRegExp = RegExp(r'(https?:\/\/[^\s]+)');
            final match = urlRegExp.firstMatch(urlStr);
            
            if (match != null) {
              String url = match.group(0)!;
              String finalUrl = url;
              String responseBody = "";
              
              // If it's a short link, expand it
              if (url.contains('goo.gl') || url.contains('maps.app.goo.gl')) {
                final response = await http.get(
                  Uri.parse(url),
                  headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
                );
                finalUrl = response.request?.url.toString() ?? url;
                responseBody = response.body;
              }
              
              void extractCoords(String content) {
                var regExp = RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)');
                var m = regExp.firstMatch(content);
                if (m != null) { lat = double.tryParse(m.group(1)!); lng = double.tryParse(m.group(2)!); return; }
                
                regExp = RegExp(r'3d(-?\d+\.\d+)!4d(-?\d+\.\d+)');
                m = regExp.firstMatch(content);
                if (m != null) { lat = double.tryParse(m.group(1)!); lng = double.tryParse(m.group(2)!); return; }

                regExp = RegExp(r'[ql]l?=(-?\d+\.\d+),(-?\d+\.\d+)');
                m = regExp.firstMatch(content);
                if (m != null) { lat = double.tryParse(m.group(1)!); lng = double.tryParse(m.group(2)!); return; }

                regExp = RegExp(r'center=(-?\d+\.\d+)%2C(-?\d+\.\d+)');
                m = regExp.firstMatch(content);
                if (m != null) { lat = double.tryParse(m.group(1)!); lng = double.tryParse(m.group(2)!); return; }
                
                regExp = RegExp(r'center=(-?\d+\.\d+),(-?\d+\.\d+)');
                m = regExp.firstMatch(content);
                if (m != null) { lat = double.tryParse(m.group(1)!); lng = double.tryParse(m.group(2)!); return; }
              }
              
              extractCoords(finalUrl);
              if (lat == null || lng == null) extractCoords(responseBody);
            }
          }
        } catch (e) {
          debugPrint("Failed to extract coordinates: $e");
        }

        final eventData = Event(
          id: _editingEventId ?? '', 
          title: _nameController.text.isEmpty ? 'Untitled Event' : _nameController.text,
          description: _descriptionController.text,
          category: _selectedCategory,
          date: eventDateTime,
          location: _locationController.text,
          venueName: _venueNameController.text.isEmpty ? 'Venue TBD' : _venueNameController.text,
          imageUrl: finalImageUrl, 
          price: price,
          latitude: lat,
          longitude: lng,
          createdBy: _auth.currentUser?.uid ?? '',
        ).toMap();
        
        if (_editingEventId != null) {
          await FirebaseFirestore.instance.collection('events').doc(_editingEventId).update(eventData);
        } else {
          await FirebaseFirestore.instance.collection('events').add(eventData);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_editingEventId != null ? 'Event updated successfully!' : 'Event created successfully!')),
          );
          if (_editingEventId != null) {
            _clearForm();
            _tabController.animateTo(1); // Switch back to manage tab
          } else {
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save event: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  void _clearForm() {
    setState(() {
      _editingEventId = null;
      _nameController.clear();
      _locationController.clear();
      _venueNameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _imageUrlController.clear();
      _selectedImage = null;
      _selectedDate = DateTime.now().add(const Duration(days: 1));
      _selectedTime = const TimeOfDay(hour: 18, minute: 0);
      _selectedCategory = 'Tech Events';
    });
  }

  void _editEvent(Event event) {
    setState(() {
      _editingEventId = event.id;
      _nameController.text = event.title;
      _locationController.text = event.location;
      _venueNameController.text = event.venueName;
      _descriptionController.text = event.description;
      _priceController.text = event.price.toStringAsFixed(0);
      _imageUrlController.text = event.imageUrl;
      _selectedDate = event.date;
      _selectedTime = TimeOfDay.fromDateTime(event.date);
      _selectedCategory = event.category;
    });
    _tabController.animateTo(0); // Switch to create/edit tab
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF6342E8);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: primaryPurple,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryPurple,
          unselectedLabelColor: Colors.black54,
          indicatorColor: primaryPurple,
          tabs: const [
            Tab(text: 'Create Event'),
            Tab(text: 'Manage Events'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
            // Tab 1: Create Event
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _editingEventId != null ? 'Edit Event' : 'Create New Event', 
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                        if (_editingEventId != null)
                          TextButton.icon(
                            onPressed: _clearForm,
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Cancel Edit'),
                          ),
                      ],
                    ),
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
                    Row(
                      children: [
                        Expanded(
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
                        const SizedBox(width: 12),
                        Expanded(
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
    
                    // Location Integration
                    const Text('Event Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '1. Tap the button below to open Google Maps.\n2. Find your exact location and tap "Share".\n3. Copy the link and paste it in the field below.',
                            style: TextStyle(fontSize: 13, color: Colors.blue, height: 1.5),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _openGoogleMaps,
                              icon: const Icon(Icons.map),
                              label: const Text('Open Google Maps'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Map Link
                    _buildTextField(
                      label: 'Google Maps Link',
                      hint: 'Paste link here (e.g., https://maps.app.goo.gl/...)',
                      controller: _locationController,
                      validator: (value) => value == null || value.isEmpty ? 'Please paste the location link' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Venue Name
                    _buildTextField(
                      label: 'Venue / Building Name',
                      hint: 'e.g., Grand Hall, Marriott Hotel',
                      controller: _venueNameController,
                      validator: (value) => value == null || value.isEmpty ? 'Please enter the venue name' : null,
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
                        onPressed: _isSaving ? null : _saveEvent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSaving 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _editingEventId != null ? 'Update Event' : 'Create Event', 
                                  style: const TextStyle(fontSize: 16, color: Colors.white)
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, color: Colors.white),
                              ],
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                      onPressed: () => _editEvent(event),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDelete(context, doc.id, event.title),
                    ),
                  ],
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
    int maxLines = 1,
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
