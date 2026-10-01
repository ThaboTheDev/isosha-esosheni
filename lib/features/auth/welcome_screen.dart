import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/journey_list.dart';
import '../../core/widgets/panel.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.canvas,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: const BoxDecoration(gradient: C.brandHeader),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 36, 24, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/crest.png',
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Center(child: Eyebrow(
                        'The Revelation Spiritual Home Kingdom',
                        onDark: true,
                      )),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          'Isosha Esosheni',
                          style: T.display.copyWith(
                            color: Colors.white,
                            fontSize: 34,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Relationships that grow toward family',
                        style: T.headline.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Isosha Esosheni is a platform for meaningful '
                        'relationships, responsible courtship, spiritual '
                        'guidance and building families within The '
                        'Revelation Spiritual Home.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'It is not a casual dating site. Every relationship '
                        'moves at the pace both people choose, with Indawo '
                        'Ephakeme guidance before dating begins.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 22),
                      GoldButton(
                        label: 'Create your account',
                        onPressed: () => context.go('/register'),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          onPressed: () => context.go('/login'),
                          child: const Text(
                            'Sign in',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const BrandBar(),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Eyebrow('The journey'),
                        const SizedBox(height: 12),
                        const JourneyList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Eyebrow('Why Isosha Esosheni'),
                  const SizedBox(height: 12),
                  const _FeatureCard(
                    icon: Icons.diversity_3,
                    title: 'Members of the Spiritual Home',
                    body: 'Every profile belongs to a member of The '
                        'Revelation Spiritual Home Kingdom, so you meet '
                        'people who share your spiritual home.',
                  ),
                  const _FeatureCard(
                    icon: Icons.handshake_outlined,
                    title: 'Guidance before commitment',
                    body: 'Indawo Ephakeme consultation comes before '
                        'dating, so no one walks this path alone.',
                  ),
                  const _FeatureCard(
                    icon: Icons.lock_outline,
                    title: 'Your information, your choice',
                    body: 'You decide what other members see, and protected '
                        'details stay protected.',
                  ),
                  const _FeatureCard(
                    icon: Icons.event_outlined,
                    title: 'Love Life Conferences',
                    body: 'Teaching, fellowship and honest conversation '
                        'about relationships that honour God and family.',
                  ),
                  const SizedBox(height: 16),
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Eyebrow('Recommendations, not verdicts'),
                        const SizedBox(height: 8),
                        Text(
                          'Scores are a starting point for conversation, '
                          'not a verdict. They reflect only what members '
                          'have chosen to share.',
                          style: T.body.copyWith(fontSize: 14.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'A platform of The Revelation Spiritual Home Kingdom',
                      style: T.small.copyWith(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Panel(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: C.plum100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: C.plum700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: T.headline.copyWith(fontSize: 19)),
                  const SizedBox(height: 4),
                  Text(body,
                      style: T.body.copyWith(fontSize: 14, color: C.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
