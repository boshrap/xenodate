import 'package:flutter/material.dart';
import 'package:xenodate/xenoprofile.dart';
import 'package:xenodate/models/xenoprofile.dart'; // Assuming Xenoprofile model is here

class ProfileCard extends StatelessWidget {
  final Xenoprofile profile;
  final double compatibilityScore; // Value between 0.0 and 1.0
  final VoidCallback? onProfileButtonPressed;

  const ProfileCard({
    Key? key,
    required this.profile,
    required this.compatibilityScore,
    this.onProfileButtonPressed,
  }) : super(key: key);

  String _getCompatibilityEmoji(double score) {
    if (score >= 0.9) return '💖';
    if (score >= 0.8) return '😍';
    if (score >= 0.7) return '😊';
    if (score >= 0.6) return '🙂';
    if (score >= 0.5) return '🤔';
    return '🤷';
  }

  Color _getCompatibilityProgressColor(BuildContext context, double score) {
    if (score >= 0.8) return Colors.green.shade600;
    if (score >= 0.6) return Colors.orange.shade600;
    return Theme.of(context).colorScheme.primary.withOpacity(0.7);
  }

  void _handleProfileTap(BuildContext context, profile) {
    // Navigate to a profile screen, passing characterId or xenoProfileId
    Navigator.push(context, MaterialPageRoute(builder: (context) => XenoprofileDisplayPage(xenoprofileId: profile.id)));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigate to profile for ${profile.id}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    // Keep card height relative but perhaps slightly less dominant than before
    final cardHeight = screenHeight * 0.65;

    return Card(
      elevation: 4.0, // Softer elevation
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias, // Important for the image to respect border radius
      child: SizedBox(
        height: cardHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Image Section ---
            SizedBox(
              height: cardHeight * 0.55, // Image takes a significant portion
              width: double.infinity,
              child: Image.network(
                profile.imageUrl ?? 'https://via.placeholder.com/400x300?text=No+Image',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade300,
                    child: Center(
                        child: Icon(Icons.broken_image,
                            size: 50, color: Colors.grey.shade600)),
                  );
                },
              ),
            ),

            // --- Content Section ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            "${profile.name} ${profile.surname}, ${profile.earthage ?? 'N/A'}",
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Compatibility Badge
                        Column(
                          children: [
                            Text(
                              _getCompatibilityEmoji(compatibilityScore),
                              style: const TextStyle(fontSize: 24),
                            ),
                            Text(
                              "${(compatibilityScore * 100).toStringAsFixed(0)}%",
                              style: theme.textTheme.labelMedium?.copyWith(
                                  color: _getCompatibilityProgressColor(
                                      context, compatibilityScore),
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      profile.species,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: theme.colorScheme.secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 16, color: theme.textTheme.bodySmall?.color),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            profile.location,
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (profile.biography.isNotEmpty)
                      Text(
                        profile.biography,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.grey.shade700),
                      ),
                    const Spacer(), // Pushes content below to the bottom

                    // --- Interests & Action ---
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: profile.interests.map((interest) { // Directly map over the List
                              return Chip(
                                label: Text(interest.trim()), // Trim whitespace from each interest
                                visualDensity: VisualDensity.compact,
                                labelStyle: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSecondaryContainer),
                                backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.7),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: IconButton(
                              icon: Icon(Icons.arrow_forward_ios_rounded, color: theme.colorScheme.primary),
                              onPressed: () => _handleProfileTap(context, profile),
                              tooltip: "View Profile",
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
