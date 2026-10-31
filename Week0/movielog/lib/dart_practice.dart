class Movie {
  const Movie({
    required this.id,
    required this.title,
  });

  final int id;
  final String title;
}

void main() {
  const movie = <Movie> [
    Movie(id: 1, title: '별빛 아래 우린'),
    Movie(id: 2, title: '우주의 끝에서'),
    Movie(id: 3, title: '새로운 영화'),
  ];
  for (final m in movie) {
    print(m.title);
  }
  
  String? nickname;
  final safeNickname = nickname ?? '게스트';

  print(safeNickname);
}