class Participant {
  final String country;
  final String artist;
  final String song;
  int points;

  Participant({
    required this.country, 
    required this.artist, 
    required this.song, 
    this.points = 0
  });

  // Cette fonction servira quand on connectera ton API Flask
  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      country: json['country'] ?? 'Inconnu',
      artist: json['participant'] ?? 'Artiste',
      song: json['song'] ?? 'Titre',
    );
  }
}