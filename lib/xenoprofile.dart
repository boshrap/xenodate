import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xenodate/models/xenoprofile.dart';
import 'package:xenodate/services/xenoprofserv.dart'; // Assuming your service path

class XenoprofileDisplayPage extends StatelessWidget {
  final String xenoprofileId;

  const XenoprofileDisplayPage({Key? key, required this.xenoprofileId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Access the XenoprofileService using Provider
    final xenoprofileService = Provider.of<XenoprofileService>(context, listen: false);
    print("XenoprofileDisplayPage: Attempting to load profile with UID: '$xenoprofileId'");

    return Scaffold(
      extendBodyBehindAppBar: true, // Make body extend behind app bar for cool effect
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent app bar
        elevation: 0, // No shadow
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<Xenoprofile?>(
        future: xenoprofileService.getXenoprofileById(xenoprofileId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                'Error loading profile or profile not found.',
                style: TextStyle(color: Colors.red[300], fontSize: 16),
              ),
            );
          }

          final profile = snapshot.data!;

          // Assuming profile.interests is a comma-separated string
          // e.g., "reading,hiking,coding"
          final List<String> interestList = profile.interests ?? [];

          return Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: Image.network(
                  profile.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
                    ),
                  ),
                  loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              ),
              // Gradient Overlay for text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.8), Colors.transparent, Colors.black.withOpacity(0.8)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Profile Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${profile.name} ${profile.surname}, ${profile.earthage ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(blurRadius: 10.0, color: Colors.black, offset: Offset(2.0, 2.0)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${profile.species} - ${profile.subspecies}',
                      style: TextStyle(fontSize: 18, color: Colors.grey[300], fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.location,
                      style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile.biography,
                      style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Interests'),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      // Updated interest mapping
                      children: interestList.map((interest) {
                        // Trim whitespace from each interest in case of spaces after commas
                        final trimmedInterest = interest.trim();
                        if (trimmedInterest.isNotEmpty) { // Avoid creating empty chips
                          return Chip(
                            label: Text(trimmedInterest),
                            backgroundColor: Colors.tealAccent.withOpacity(0.7),
                          );
                        }
                        return null; // Or an empty SizedBox(), or filter out nulls later
                      }).whereType<Chip>().toList(), // whereType<Chip>() filters out any nulls
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn('Likes', profile.likes, Icons.thumb_up, Colors.greenAccent),
                        _buildStatColumn('Dislikes', profile.dislikes, Icons.thumb_down, Colors.redAccent),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Looking For'),
                    Text(profile.lookingfor, style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9))),
                    const SizedBox(height: 8),
                    _buildSectionTitle('Orientation'),
                    Text(profile.orientation, style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9))),
                    const SizedBox(height: 8),
                    _buildSectionTitle('Red Flags'),
                    Text(profile.redflags, style: TextStyle(fontSize: 16, color: Colors.redAccent[100])),

                    const SizedBox(height: 60), // Space for exit button if it were at the bottom
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.tealAccent[100],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[300])),
        const SizedBox(height: 2),
        Text(
          value.isNotEmpty ? value : 'N/A',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
