class SocratesQuestion {
  final String key;
  final String titleKey;
  final String description;
  final List<String> quickOptions;

  const SocratesQuestion({
    required this.key,
    required this.titleKey,
    required this.description,
    this.quickOptions = const [],
  });
}

class SocratesAlgorithm {
  static const List<SocratesQuestion> questions = [
    SocratesQuestion(
      key: 'site',
      titleKey: 'socrates_site',
      description: 'Site of symptom or pain',
      quickOptions: ['Chest', 'Abdomen', 'Head / Forehead', 'Lower Back', 'Left Arm', 'Throat', 'Joints'],
    ),
    SocratesQuestion(
      key: 'onset',
      titleKey: 'socrates_onset',
      description: 'Onset and onset speed',
      quickOptions: ['Sudden (few hours ago)', 'Gradual (few days ago)', 'Started this morning', 'Chronic (weeks)'],
    ),
    SocratesQuestion(
      key: 'character',
      titleKey: 'socrates_character',
      description: 'Character of pain or discomfort',
      quickOptions: ['Sharp & stabbing', 'Dull ache', 'Heavy pressure / squeezing', 'Burning sensation', 'Throbbing'],
    ),
    SocratesQuestion(
      key: 'radiation',
      titleKey: 'socrates_radiation',
      description: 'Radiation / spread of pain',
      quickOptions: ['Radiates to left shoulder/arm', 'Radiates to back', 'Spreads down leg', 'No radiation (localized)'],
    ),
    SocratesQuestion(
      key: 'associated',
      titleKey: 'socrates_associated',
      description: 'Associated symptoms',
      quickOptions: ['Shortness of breath & sweating', 'Nausea & vomiting', 'High fever & chills', 'Dizziness', 'None'],
    ),
    SocratesQuestion(
      key: 'timing',
      titleKey: 'socrates_timing',
      description: 'Timing and constancy',
      quickOptions: ['Constant and persistent', 'Comes and goes in waves', 'Worse in morning', 'Worse at night'],
    ),
    SocratesQuestion(
      key: 'exacerbating',
      titleKey: 'socrates_exacerbating',
      description: 'Exacerbating & relieving factors',
      quickOptions: ['Worse with exertion, better with rest', 'Worse after eating', 'Better after lying down', 'No change'],
    ),
  ];
}
