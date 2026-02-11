class Crab {
  final int id;
  final String commonName;
  final String scientificName;
  final String speciesType;
  final String gender;
  final String description;
  final bool isPoisonous;
  final String maturity;
  final String meatyInformation;
  final List<String> attachments;

  Crab({
    required this.id,
    required this.commonName,
    required this.scientificName,
    required this.speciesType,
    required this.gender,
    required this.description,
    required this.isPoisonous,
    required this.maturity,
    required this.meatyInformation,
    required this.attachments,
  });

  factory Crab.fromJson(Map<String, dynamic> json) {
    final attachmentsData = json['attachments'] as List<dynamic>? ?? [];
    return Crab(
      id: json['id'],
      commonName: json['common_name'] ?? 'Unknown Crab',
      scientificName: json['scientific_name'] ?? '',  
      speciesType: json['species_type'] ?? '',
      gender: json['gender'] ?? '',
      description: json['description'] ?? '',
      isPoisonous: json['is_poisonous'] == '0',
      maturity: json['maturity_cycle'],
      meatyInformation: json['meaty_information'] ?? '',
      attachments: attachmentsData
          .map<String>((e) => e['url'] as String)
          .toList(), // extract URLs
    );
  }

  String get firstImage =>
      attachments.isNotEmpty
          ? attachments.first
          : 'https://via.placeholder.com/300x400?text=No+Image';
}
