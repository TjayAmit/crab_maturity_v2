class Crab {
  final int id;
  final String commonName;
  final String scientificName;
  final String speciesType;
  final String gender;
  final String description;
  final String meatyInformation; // how to tell if the crab is meaty
  final bool isPoisonous;
  final String maturity;
  final String habitat;
  final String diet;
  final String lifespan;
  final String? subjectTag;
  final List<String> attachments; // list of image URLs

  Crab({
    required this.id,
    required this.commonName,
    required this.scientificName,
    required this.speciesType,
    required this.gender,
    required this.description,
    required this.meatyInformation,
    required this.isPoisonous,
    required this.maturity,
    this.habitat = '',
    this.diet = '',
    this.lifespan = '',
    this.subjectTag,
    required this.attachments,
  });

  factory Crab.fromJson(Map<String, dynamic> json) {
    final attachmentsData = json['attachments'] as List<dynamic>? ?? [];
    return Crab(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      commonName: (json['common_name'] ?? json['name'] ?? 'Unknown Crab').toString(),
      scientificName: (json['scientific_name'] ?? '').toString(),
      speciesType: (json['species_type'] ?? '').toString(),
      gender: (json['gender'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      meatyInformation: (json['meaty_information'] ?? json['meaty_info'] ?? '').toString(),
      isPoisonous: json['is_poisonous'] == true ||
          json['is_poisonous'] == 1 ||
          json['is_poisonous'] == '1' ||
          json['is_poisonous'] == 'true',
      maturity: (json['maturity_cycle'] ?? json['maturity'] ?? '').toString(),
      habitat: (json['habitat'] ?? '').toString(),
      diet: (json['diet'] ?? '').toString(),
      lifespan: (json['lifespan'] ?? '').toString(),
      subjectTag: json['subject_tag']?.toString(),
      attachments: attachmentsData
          .map<String>((e) {
            if (e is Map<String, dynamic> && e.containsKey('url')) {
              return (e['url'] ?? '').toString();
            } else if (e is Map && e.containsKey('url')) {
              return (e['url'] ?? '').toString();
            } else if (e is String) {
              return e;
            }
            return '';
          })
          .where((url) => url.isNotEmpty)
          .toList(),
    );
  }

  String get firstImage =>
      attachments.isNotEmpty
          ? attachments.first
          : 'https://via.placeholder.com/300x400?text=No+Image';
}
