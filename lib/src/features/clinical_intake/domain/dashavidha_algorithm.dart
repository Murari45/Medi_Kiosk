class DashavidhaQuestion {
  final String key;
  final String titleKey;
  final String sanskritTerm;
  final String englishMeaning;
  final List<String> options;

  const DashavidhaQuestion({
    required this.key,
    required this.titleKey,
    required this.sanskritTerm,
    required this.englishMeaning,
    required this.options,
  });
}

class DashavidhaAlgorithm {
  static const List<DashavidhaQuestion> parameters = [
    DashavidhaQuestion(
      key: 'prakriti',
      titleKey: 'ayush_prakriti',
      sanskritTerm: 'Prakriti (प्रकृति)',
      englishMeaning: 'Constitutional Body Type',
      options: ['Vata Predominant (Lean, Light, Active)', 'Pitta Predominant (Medium, Warm, Sharp)', 'Kapha Predominant (Sturdy, Calm, Heavy)', 'Vata-Pitta', 'Pitta-Kapha', 'Tridosha Balanced'],
    ),
    DashavidhaQuestion(
      key: 'vikriti',
      titleKey: 'ayush_vikriti',
      sanskritTerm: 'Vikriti (विकृति)',
      englishMeaning: 'Current Dosha Imbalance / Pathological State',
      options: ['Vata Aggravation (Pain, Dryness, Anxiety)', 'Pitta Aggravation (Burning, Acid Reflux, Heat)', 'Kapha Aggravation (Congestion, Lethargy, Heaviness)', 'Dwandwaja (Dual Dosha)'],
    ),
    DashavidhaQuestion(
      key: 'sara',
      titleKey: 'ayush_sara',
      sanskritTerm: 'Sara (सार)',
      englishMeaning: 'Tissue Vitality & Essence (Dhatu Quality)',
      options: ['Pravara (Excellent / High Vitality)', 'Madhyama (Medium Vitality)', 'Avara (Poor / Low Tissue Strength)'],
    ),
    DashavidhaQuestion(
      key: 'samhanana',
      titleKey: 'ayush_samhanana',
      sanskritTerm: 'Samhanana (संहनन)',
      englishMeaning: 'Body Compactness & Musculoskeletal Symmetry',
      options: ['Susamhata (Compact & Well-knit)', 'Madhyama (Moderate Build)', 'Heena (Poorly compacted / Fragile)'],
    ),
    DashavidhaQuestion(
      key: 'pramana',
      titleKey: 'ayush_pramana',
      sanskritTerm: 'Pramana (प्रमाण)',
      englishMeaning: 'Anthropometric Proportions & Balance',
      options: ['Yathokta (Harmonious / Ideal Proportions)', 'Ati-Sthula (Obese / Heavy)', 'Ati-Krisha (Emaciated / Underweight)'],
    ),
    DashavidhaQuestion(
      key: 'satmya',
      titleKey: 'ayush_satmya',
      sanskritTerm: 'Satmya (सात्म्य)',
      englishMeaning: 'Habituation & Dietary Adaptability',
      options: ['Sarva-Rasa Satmya (Adapted to all 6 tastes)', 'Eka-Rasa (Restricted habituation)', 'Visham Satmya (Digestive sensitivity)'],
    ),
    DashavidhaQuestion(
      key: 'satva',
      titleKey: 'ayush_satva',
      sanskritTerm: 'Satva (सत्व)',
      englishMeaning: 'Mental Strength & Stress Tolerance',
      options: ['Pravara Satva (High resilience & calm mind)', 'Madhyama Satva (Moderate tolerance)', 'Avara Satva (Easily anxious / overwhelmed)'],
    ),
    DashavidhaQuestion(
      key: 'ahara_shakti',
      titleKey: 'ayush_ahara',
      sanskritTerm: 'Ahara Shakti & Agni (आहार शक्ति एवं अग्नि)',
      englishMeaning: 'Digestive Capacity & Appetite Fire',
      options: ['Tikshnagni (Strong / Fast digestion)', 'Mandagni (Sluggish digestion / heaviness)', 'Vishamagni (Irregular appetite)', 'Samagni (Balanced digestion)'],
    ),
    DashavidhaQuestion(
      key: 'vyayama_shakti',
      titleKey: 'ayush_vyayama',
      sanskritTerm: 'Vyayama Shakti (व्यायाम शक्ति)',
      englishMeaning: 'Physical Endurance & Work Capacity',
      options: ['Uttama (High physical endurance)', 'Madhyama (Moderate endurance)', 'Heena (Fatigues easily / low stamina)'],
    ),
    DashavidhaQuestion(
      key: 'vaya',
      titleKey: 'ayush_vaya',
      sanskritTerm: 'Vaya (वय)',
      englishMeaning: 'Age & Chronological Stage',
      options: ['Bala (Childhood / Growth Stage)', 'Madhyama (Youth & Adult 16-60 yrs)', 'Vriddha (Elderly 60+ yrs)'],
    ),
  ];
}
