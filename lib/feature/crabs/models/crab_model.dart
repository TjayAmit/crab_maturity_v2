class Crabs {
  final String name;
  final String commonName;
  final String scientificName;
  final Map<String, dynamic> description;
  final List<String> images;

  Crabs({
    required this.name,
    required this.commonName,
    required this.scientificName,
    required this.description,
    required this.images,
  });

  factory Crabs.fromJson(Map<String, dynamic> json) {
    return Crabs(
      name: json['name'],
      commonName: json['common_name'],
      scientificName: json['scientific_name'],
      description: Map<String, dynamic>.from(json['description']),
      images: List<String>.from(json['images']),
    );
  }
}