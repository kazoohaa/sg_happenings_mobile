import 'package:flutter/material.dart';
import '../events_details/events_details_page.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0), // Light beige background
      body: SafeArea(
        child: Column(
          children: [
            // Header with title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    'Events',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Search',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.tune,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Events list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: 6, // 6 events as shown in the image
                itemBuilder: (context, index) {
                  return _buildEventCard(context, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, int index) {
    final events = [
      {
        'title': 'Live Concert',
        'date': 'Fri, Apr 12 • 7:00 PM',
        'location': 'Esplanade Hall',
        'image': _buildConcertImage(),
      },
      {
        'title': 'Art Exhibition',
        'date': 'Sat, Apr 20 • 10:00 AM',
        'location': 'City Gallery',
        'image': _buildArtImage(),
      },
      {
        'title': 'Cooking Workshop',
        'date': 'Sun, Apr 28 • 2:00 PM',
        'location': 'Community Center',
        'image': _buildCookingImage(),
      },
    ];

    final event = events[index % events.length];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventsDetailsPage(
              event: {
                'title': event['title'],
                'date': event['date'],
                'location': event['location'],
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF0EDE8), // Slightly darker beige for cards
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Event image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: event['image'] as Widget,
              ),
              const SizedBox(width: 12),
              
              // Event details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['title'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event['date'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event['location'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConcertImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35), // Orange background
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.mic,
        color: Colors.white,
        size: 40,
      ),
    );
  }

  Widget _buildArtImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFFFA726), // Light orange background
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.palette,
        color: Colors.white,
        size: 40,
      ),
    );
  }

  Widget _buildCookingImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF8D6E63), // Brown background
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.restaurant,
        color: Colors.white,
        size: 40,
      ),
    );
  }

}
