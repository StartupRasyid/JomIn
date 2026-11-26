import 'package:flutter/material.dart';

class EventTemplate {
  final String id;
  final String label;
  final String defaultCategory;
  final String sampleTitle;
  final String sampleVenue;
  final String sampleDescription;
  final IconData icon;
  final Color accentColor;

  const EventTemplate({
    required this.id,
    required this.label,
    required this.defaultCategory,
    required this.sampleTitle,
    required this.sampleVenue,
    required this.sampleDescription,
    required this.icon,
    required this.accentColor,
  });
}

const List<EventTemplate> kEventTemplates = [
  EventTemplate(
    id: 'template_tech_01',
    label: 'Hackathon',
    defaultCategory: 'Hackathon',
    sampleTitle: 'UTM AI Hackathon 2026',
    sampleVenue: 'Dewan Sultan Mizan, UTM JB',
    sampleDescription:
        'Build innovative tech solutions in 24 hours! Open to all UTM students. Form a team of 3–4 and compete for cash prizes and industry mentorship.',
    icon: Icons.terminal_rounded,
    accentColor: Color(0xFF4F46E5),
  ),
  EventTemplate(
    id: 'template_workshop_02',
    label: 'Tech Workshop',
    defaultCategory: 'Technical Workshop',
    sampleTitle: 'Hands-On Flutter & AI Workshop',
    sampleVenue: 'Active Learning Lab, Faculty of Computing',
    sampleDescription:
        'Learn practical skills step-by-step with guided mentorship. Bring your laptop; e-certificates and refreshments will be provided.',
    icon: Icons.build_circle_outlined,
    accentColor: Color(0xFF0284C7),
  ),
  EventTemplate(
    id: 'template_sports_03',
    label: 'Fun Run / Sports',
    defaultCategory: 'Fun Run',
    sampleTitle: 'UTM Night Neon Run 5KM',
    sampleVenue: 'Stadium Azman Hashim, UTM JB',
    sampleDescription:
        'Lace up for an energetic campus run! Includes race kit, finisher medal, lucky draw, and merit points for all participants.',
    icon: Icons.directions_run_rounded,
    accentColor: Color(0xFF059669),
  ),
  EventTemplate(
    id: 'template_talk_04',
    label: 'Talk / Seminar',
    defaultCategory: 'Talk / Seminar',
    sampleTitle: 'Industry Career & Leadership Talk',
    sampleVenue: 'Dewan Astana, Kolej Tuanku Canselor',
    sampleDescription:
        'Gain real-world insights from invited speakers and alumni. Includes interactive Q&A session and networking opportunity.',
    icon: Icons.campaign_outlined,
    accentColor: Color(0xFFD97706),
  ),
  EventTemplate(
    id: 'template_cultural_05',
    label: 'Cultural / Expo',
    defaultCategory: 'Cultural Exhibition',
    sampleTitle: 'UTM Cultural & Arts Festival',
    sampleVenue: 'Dataran UTM, Johor Bahru',
    sampleDescription:
        'Experience live performances, food booths, interactive exhibitions, and student club showcases across campus.',
    icon: Icons.festival_outlined,
    accentColor: Color(0xFFDB2777),
  ),
];