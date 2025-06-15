import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:SkyNet/widgets/Layout.dart';
import 'package:SkyNet/provider/users_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<UserProvider>(context, listen: false).loadUsers());
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    // Definir ancho de tarjeta: máximo 320px en desktop, 70% en móvil
    double cardWidth = screenWidth * 0.7;
    if (screenWidth > 600) {
      cardWidth = 320;
    }

    return LayoutWrapper(
      titleBuilder: (loc) => loc.home,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Stack(
              children: [
                SizedBox(
                  height: 280,
                  width: double.infinity,
                  child: Image.asset(
                    'assets/drones_banner.webp',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  bottom: 30,
                  left: 24,
                  right: 24,
                  child: Text(
                    loc.welcomeMessage,
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                            blurRadius: 6,
                            color: Colors.black.withOpacity(0.5),
                            offset: Offset(2, 2))
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.appDescription,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),

                      Text(
                        loc.features,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Feature Cards Scroll adaptado a móvil y PC
                      SizedBox(
                        height: 260,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          scrollDirection: Axis.horizontal,
                          itemCount: 4,
                          itemBuilder: (context, index) {
                            final features = [
                              {
                                'image': 'assets/drones_store.webp',
                                'title': loc.storeFeatureTitle,
                                'description': loc.storeFeatureDescription,
                              },
                              {
                                'image': 'assets/drones_community.webp',
                                'title': loc.socialFeatureTitle,
                                'description': loc.socialFeatureDescription,
                              },
                              {
                                'image': 'assets/drones_chat.webp',
                                'title': loc.chatFeatureTitle,
                                'description': loc.chatFeatureDescription,
                              },
                              {
                                'image': 'assets/drones_games.webp',
                                'title': loc.gamesFeatureTitle,
                                'description': loc.gamesFeatureDescription,
                              },
                            ];

                            final feature = features[index];

                            return _HoverFeatureCard(
                              image: feature['image']!,
                              title: feature['title']!,
                              description: feature['description']!,
                              maxWidth: cardWidth,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _HoverFeatureCard extends StatefulWidget {
  final String image;
  final String title;
  final String description;
  final double maxWidth;

  const _HoverFeatureCard({
    super.key,
    required this.image,
    required this.title,
    required this.description,
    required this.maxWidth,
  });

  @override
  State<_HoverFeatureCard> createState() => __HoverFeatureCardState();
}

class __HoverFeatureCardState extends State<_HoverFeatureCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Container(
          width: widget.maxWidth,
          margin: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: colors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.asset(
                  widget.image,
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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
}
