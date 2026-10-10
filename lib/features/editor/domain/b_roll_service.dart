import '../../../core/database/schemas/word.dart';

/// Represents a detected visual concept where B-roll footage enhances viewer retention.
class BRollCue {
  final String keyword;
  final String category;
  final String searchTopic;
  final double startTime;
  final double endTime;
  final String contextSentence;

  const BRollCue({
    required this.keyword,
    required this.category,
    required this.searchTopic,
    required this.startTime,
    required this.endTime,
    required this.contextSentence,
  });

  /// Deep link to free stock video search on Pexels
  String get pexelsUrl => 'https://www.pexels.com/search/videos/${Uri.encodeComponent(searchTopic)}/';

  /// Deep link to free stock video search on Pixabay
  String get pixabayUrl => 'https://pixabay.com/videos/search/${Uri.encodeComponent(searchTopic)}/';
}

/// Service that analyzes spoken transcript to detect visual b-roll opportunities
/// matching Submagic and CapCut desktop intelligence.
class BRollSuggestionService {
  BRollSuggestionService._();
  static final BRollSuggestionService instance = BRollSuggestionService._();

  static String _removeDiacritics(String str) {
    const withDia = 'ÀÁÂÃÄÅàáâãäåÈÉÊËèéêëÌÍÎÏìíîïÒÓÔÕÖØòóôõöøÙÚÛÜùúûüÑñÇçÝýÿ';
    const withoutDia = 'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOOooooooUUUUuuuuNnCcYyy';
    var res = str;
    for (int i = 0; i < withDia.length; i++) {
      res = res.replaceAll(withDia[i], withoutDia[i]);
    }
    return res;
  }

  static const Map<String, ({String category, String searchTopic})> _visualKeywords = {
    // -------------------------------------------------------------
    // Finance & Business (Multilingual)
    // -------------------------------------------------------------
    // English
    'money': (category: 'Finance', searchTopic: 'cash money finance'),
    'cash': (category: 'Finance', searchTopic: 'cash counting'),
    'dollar': (category: 'Finance', searchTopic: 'dollars money'),
    'crypto': (category: 'Finance', searchTopic: 'cryptocurrency bitcoin'),
    'bitcoin': (category: 'Finance', searchTopic: 'bitcoin trading'),
    'profit': (category: 'Business', searchTopic: 'business growth chart'),
    'revenue': (category: 'Business', searchTopic: 'business analytics dashboard'),
    'investment': (category: 'Finance', searchTopic: 'stock market investing'),
    'rich': (category: 'Lifestyle', searchTopic: 'luxury lifestyle success'),
    'sales': (category: 'Business', searchTopic: 'handshake business deal'),
    'marketing': (category: 'Business', searchTopic: 'social media marketing office'),
    // Spanish
    'dinero': (category: 'Finance', searchTopic: 'cash money finance'),
    'plata': (category: 'Finance', searchTopic: 'cash money finance'),
    'billetes': (category: 'Finance', searchTopic: 'cash counting'),
    'dolares': (category: 'Finance', searchTopic: 'dollars money'),
    'cripto': (category: 'Finance', searchTopic: 'cryptocurrency bitcoin'),
    'inversion': (category: 'Finance', searchTopic: 'stock market investing'),
    'beneficio': (category: 'Business', searchTopic: 'business growth chart'),
    'ganancia': (category: 'Business', searchTopic: 'business growth chart'),
    'negocio': (category: 'Business', searchTopic: 'handshake business deal'),
    'ventas': (category: 'Business', searchTopic: 'business analytics dashboard'),
    // French
    'argent': (category: 'Finance', searchTopic: 'cash money finance'),
    'billets': (category: 'Finance', searchTopic: 'cash counting'),
    'investissement': (category: 'Finance', searchTopic: 'stock market investing'),
    'benefice': (category: 'Business', searchTopic: 'business growth chart'),
    'entreprise': (category: 'Business', searchTopic: 'handshake business deal'),
    'vente': (category: 'Business', searchTopic: 'business analytics dashboard'),
    // German
    'geld': (category: 'Finance', searchTopic: 'cash money finance'),
    'bargeld': (category: 'Finance', searchTopic: 'cash counting'),
    'krypto': (category: 'Finance', searchTopic: 'cryptocurrency bitcoin'),
    'investition': (category: 'Finance', searchTopic: 'stock market investing'),
    'gewinn': (category: 'Business', searchTopic: 'business growth chart'),
    'umsatz': (category: 'Business', searchTopic: 'business analytics dashboard'),
    'vermogen': (category: 'Lifestyle', searchTopic: 'luxury lifestyle success'),
    'verkauf': (category: 'Business', searchTopic: 'handshake business deal'),
    // Portuguese
    'dinheiro': (category: 'Finance', searchTopic: 'cash money finance'),
    'grana': (category: 'Finance', searchTopic: 'cash money finance'),
    'investimento': (category: 'Finance', searchTopic: 'stock market investing'),
    'lucro': (category: 'Business', searchTopic: 'business growth chart'),
    'receita': (category: 'Business', searchTopic: 'business analytics dashboard'),
    // Italian
    'soldi': (category: 'Finance', searchTopic: 'cash money finance'),
    'denaro': (category: 'Finance', searchTopic: 'cash money finance'),
    'contanti': (category: 'Finance', searchTopic: 'cash counting'),
    'guadagno': (category: 'Business', searchTopic: 'business growth chart'),
    'profitto': (category: 'Business', searchTopic: 'business growth chart'),
    'affari': (category: 'Business', searchTopic: 'handshake business deal'),
    // Hindi (Transliterated / Phonetic)
    'paise': (category: 'Finance', searchTopic: 'cash money finance'),
    'paisa': (category: 'Finance', searchTopic: 'cash money finance'),
    'dhan': (category: 'Finance', searchTopic: 'stock market investing'),
    'daulat': (category: 'Lifestyle', searchTopic: 'luxury lifestyle success'),
    'vyapar': (category: 'Business', searchTopic: 'handshake business deal'),

    // -------------------------------------------------------------
    // Technology & Coding (Multilingual)
    // -------------------------------------------------------------
    // English
    'computer': (category: 'Technology', searchTopic: 'laptop typing workspace'),
    'laptop': (category: 'Technology', searchTopic: 'modern laptop desk'),
    'code': (category: 'Technology', searchTopic: 'programming screen dark'),
    'coding': (category: 'Technology', searchTopic: 'software engineer coding'),
    'software': (category: 'Technology', searchTopic: 'technology interface digital'),
    'app': (category: 'Technology', searchTopic: 'smartphone user interface'),
    'phone': (category: 'Technology', searchTopic: 'person using smartphone'),
    'ai': (category: 'Technology', searchTopic: 'artificial intelligence abstract neural network'),
    'robot': (category: 'Technology', searchTopic: 'futuristic robotics tech'),
    'algorithm': (category: 'Technology', searchTopic: 'data streams matrix cyber'),
    // Spanish
    'computadora': (category: 'Technology', searchTopic: 'laptop typing workspace'),
    'ordenador': (category: 'Technology', searchTopic: 'modern laptop desk'),
    'portatil': (category: 'Technology', searchTopic: 'modern laptop desk'),
    'codigo': (category: 'Technology', searchTopic: 'programming screen dark'),
    'programacion': (category: 'Technology', searchTopic: 'software engineer coding'),
    'aplicacion': (category: 'Technology', searchTopic: 'smartphone user interface'),
    'telefono': (category: 'Technology', searchTopic: 'person using smartphone'),
    'movil': (category: 'Technology', searchTopic: 'person using smartphone'),
    'celular': (category: 'Technology', searchTopic: 'person using smartphone'),
    'algoritmo': (category: 'Technology', searchTopic: 'data streams matrix cyber'),
    // French
    'ordinateur': (category: 'Technology', searchTopic: 'laptop typing workspace'),
    'programmation': (category: 'Technology', searchTopic: 'software engineer coding'),
    'logiciel': (category: 'Technology', searchTopic: 'technology interface digital'),
    'appli': (category: 'Technology', searchTopic: 'smartphone user interface'),
    'algorithme': (category: 'Technology', searchTopic: 'data streams matrix cyber'),
    // German
    'programmieren': (category: 'Technology', searchTopic: 'software engineer coding'),
    'handy': (category: 'Technology', searchTopic: 'person using smartphone'),
    'roboter': (category: 'Technology', searchTopic: 'futuristic robotics tech'),
    'algorithmus': (category: 'Technology', searchTopic: 'data streams matrix cyber'),
    // Portuguese
    'computador': (category: 'Technology', searchTopic: 'laptop typing workspace'),
    'notebook': (category: 'Technology', searchTopic: 'modern laptop desk'),
    'programacao': (category: 'Technology', searchTopic: 'software engineer coding'),
    'aplicativo': (category: 'Technology', searchTopic: 'smartphone user interface'),
    'robo': (category: 'Technology', searchTopic: 'futuristic robotics tech'),
    // Italian
    'portatile': (category: 'Technology', searchTopic: 'modern laptop desk'),
    'codice': (category: 'Technology', searchTopic: 'programming screen dark'),

    // -------------------------------------------------------------
    // Growth & Success (Multilingual)
    // -------------------------------------------------------------
    // English
    'rocket': (category: 'Growth', searchTopic: 'rocket launch space speed'),
    'growth': (category: 'Growth', searchTopic: 'upward graph growth time-lapse'),
    'scale': (category: 'Growth', searchTopic: 'skyscraper city scale'),
    'winner': (category: 'Achievement', searchTopic: 'celebration winning podium'),
    'trophy': (category: 'Achievement', searchTopic: 'trophy award success'),
    'goal': (category: 'Achievement', searchTopic: 'target dart bullseye goal'),
    // Spanish
    'cohete': (category: 'Growth', searchTopic: 'rocket launch space speed'),
    'crecimiento': (category: 'Growth', searchTopic: 'upward graph growth time-lapse'),
    'exito': (category: 'Achievement', searchTopic: 'celebration winning podium'),
    'ganador': (category: 'Achievement', searchTopic: 'celebration winning podium'),
    'trofeo': (category: 'Achievement', searchTopic: 'trophy award success'),
    'objetivo': (category: 'Achievement', searchTopic: 'target dart bullseye goal'),
    'meta': (category: 'Achievement', searchTopic: 'target dart bullseye goal'),
    // French
    'fusee': (category: 'Growth', searchTopic: 'rocket launch space speed'),
    'croissance': (category: 'Growth', searchTopic: 'upward graph growth time-lapse'),
    'succes': (category: 'Achievement', searchTopic: 'celebration winning podium'),
    'gagnant': (category: 'Achievement', searchTopic: 'celebration winning podium'),
    'trophee': (category: 'Achievement', searchTopic: 'trophy award success'),
    // German
    'rakete': (category: 'Growth', searchTopic: 'rocket launch space speed'),
    'wachstum': (category: 'Growth', searchTopic: 'upward graph growth time-lapse'),
    'erfolg': (category: 'Achievement', searchTopic: 'celebration winning podium'),
    'gewinner': (category: 'Achievement', searchTopic: 'celebration winning podium'),
    'trophae': (category: 'Achievement', searchTopic: 'trophy award success'),
    'ziel': (category: 'Achievement', searchTopic: 'target dart bullseye goal'),
    // Portuguese
    'foguete': (category: 'Growth', searchTopic: 'rocket launch space speed'),
    'sucesso': (category: 'Achievement', searchTopic: 'celebration winning podium'),
    'vencedor': (category: 'Achievement', searchTopic: 'celebration winning podium'),
    'trofeu': (category: 'Achievement', searchTopic: 'trophy award success'),
    // Italian
    'razzo': (category: 'Growth', searchTopic: 'rocket launch space speed'),
    'crescita': (category: 'Growth', searchTopic: 'upward graph growth time-lapse'),
    'vincitore': (category: 'Achievement', searchTopic: 'celebration winning podium'),
    'traguardo': (category: 'Achievement', searchTopic: 'target dart bullseye goal'),
    // Hindi
    'vikas': (category: 'Growth', searchTopic: 'upward graph growth time-lapse'),
    'safalta': (category: 'Achievement', searchTopic: 'celebration winning podium'),
    'vijeta': (category: 'Achievement', searchTopic: 'celebration winning podium'),
    'lakshya': (category: 'Achievement', searchTopic: 'target dart bullseye goal'),

    // -------------------------------------------------------------
    // Emotion & Human Connection (Multilingual)
    // -------------------------------------------------------------
    // English
    'happy': (category: 'Emotion', searchTopic: 'happy smiling people laughing'),
    'sad': (category: 'Emotion', searchTopic: 'thoughtful rain window solitary'),
    'angry': (category: 'Emotion', searchTopic: 'frustrated office worker stress'),
    'shocked': (category: 'Emotion', searchTopic: 'surprised gasp reaction'),
    'team': (category: 'Teamwork', searchTopic: 'diverse office team high five meeting'),
    'friends': (category: 'Lifestyle', searchTopic: 'friends laughing outdoors sunset'),
    // Spanish
    'feliz': (category: 'Emotion', searchTopic: 'happy smiling people laughing'),
    'alegria': (category: 'Emotion', searchTopic: 'happy smiling people laughing'),
    'triste': (category: 'Emotion', searchTopic: 'thoughtful rain window solitary'),
    'enojo': (category: 'Emotion', searchTopic: 'frustrated office worker stress'),
    'equipo': (category: 'Teamwork', searchTopic: 'diverse office team high five meeting'),
    'amigos': (category: 'Lifestyle', searchTopic: 'friends laughing outdoors sunset'),
    'amistad': (category: 'Lifestyle', searchTopic: 'friends laughing outdoors sunset'),
    // French
    'heureux': (category: 'Emotion', searchTopic: 'happy smiling people laughing'),
    'joie': (category: 'Emotion', searchTopic: 'happy smiling people laughing'),
    'tristesse': (category: 'Emotion', searchTopic: 'thoughtful rain window solitary'),
    'colere': (category: 'Emotion', searchTopic: 'frustrated office worker stress'),
    'equipe': (category: 'Teamwork', searchTopic: 'diverse office team high five meeting'),
    'amis': (category: 'Lifestyle', searchTopic: 'friends laughing outdoors sunset'),
    'amitie': (category: 'Lifestyle', searchTopic: 'friends laughing outdoors sunset'),
    // German
    'glucklich': (category: 'Emotion', searchTopic: 'happy smiling people laughing'),
    'gluecklich': (category: 'Emotion', searchTopic: 'happy smiling people laughing'),
    'freude': (category: 'Emotion', searchTopic: 'happy smiling people laughing'),
    'traurig': (category: 'Emotion', searchTopic: 'thoughtful rain window solitary'),
    'wutend': (category: 'Emotion', searchTopic: 'frustrated office worker stress'),
    'freunde': (category: 'Lifestyle', searchTopic: 'friends laughing outdoors sunset'),
    'freundschaft': (category: 'Lifestyle', searchTopic: 'friends laughing outdoors sunset'),
    // Portuguese
    'raiva': (category: 'Emotion', searchTopic: 'frustrated office worker stress'),
    'amizade': (category: 'Lifestyle', searchTopic: 'friends laughing outdoors sunset'),
    // Italian
    'felice': (category: 'Emotion', searchTopic: 'happy smiling people laughing'),
    'felicita': (category: 'Emotion', searchTopic: 'happy smiling people laughing'),
    'arrabbiato': (category: 'Emotion', searchTopic: 'frustrated office worker stress'),
    'squadra': (category: 'Teamwork', searchTopic: 'diverse office team high five meeting'),
    'amici': (category: 'Lifestyle', searchTopic: 'friends laughing outdoors sunset'),
    // Hindi
    'khushi': (category: 'Emotion', searchTopic: 'happy smiling people laughing'),
    'khush': (category: 'Emotion', searchTopic: 'happy smiling people laughing'),
    'udaas': (category: 'Emotion', searchTopic: 'thoughtful rain window solitary'),
    'gussa': (category: 'Emotion', searchTopic: 'frustrated office worker stress'),
    'dosti': (category: 'Lifestyle', searchTopic: 'friends laughing outdoors sunset'),
    'dost': (category: 'Lifestyle', searchTopic: 'friends laughing outdoors sunset'),
    'parivar': (category: 'Lifestyle', searchTopic: 'happy family bonding outdoors'),

    // -------------------------------------------------------------
    // Creation & Media (Multilingual)
    // -------------------------------------------------------------
    // English
    'camera': (category: 'Production', searchTopic: 'cinema camera lens gimbal'),
    'video': (category: 'Production', searchTopic: 'video editing timeline studio'),
    'youtube': (category: 'Media', searchTopic: 'content creator studio recording'),
    'creator': (category: 'Media', searchTopic: 'creative workspace artist desk'),
    'podcast': (category: 'Media', searchTopic: 'studio microphone neon headphones'),
    'puzzle': (category: 'Innovation', searchTopic: 'solving jigsaw puzzle table hands'),
    'puzzles': (category: 'Innovation', searchTopic: 'solving jigsaw puzzle table hands'),
    'building': (category: 'Creation', searchTopic: 'building constructing blocks hands architecture'),
    'build': (category: 'Creation', searchTopic: 'building constructing blocks hands architecture'),
    'scratch': (category: 'Creation', searchTopic: 'craftsman building from scratch workshop design'),
    'ideas': (category: 'Innovation', searchTopic: 'brainstorming ideas innovation lightbulb'),
    'idea': (category: 'Innovation', searchTopic: 'brainstorming ideas innovation lightbulb'),
    'learning': (category: 'Education', searchTopic: 'person reading book studying learning desk'),
    'learn': (category: 'Education', searchTopic: 'person reading book studying learning desk'),
    'curiosity': (category: 'Innovation', searchTopic: 'curious explorer looking microscope discovery'),
    'passion': (category: 'Inspiration', searchTopic: 'passionate artist working focus determination'),
    'creating': (category: 'Creation', searchTopic: 'digital artist tablet drawing designing creating'),
    'create': (category: 'Creation', searchTopic: 'digital artist tablet drawing designing creating'),
    'discover': (category: 'Innovation', searchTopic: 'discovery science laboratory telescope space'),
    'discovered': (category: 'Innovation', searchTopic: 'discovery science laboratory telescope space'),
    // Spanish
    'camara': (category: 'Production', searchTopic: 'cinema camera lens gimbal'),
    'creador': (category: 'Media', searchTopic: 'creative workspace artist desk'),
    'grabacion': (category: 'Production', searchTopic: 'video editing timeline studio'),
    // French
    'createur': (category: 'Media', searchTopic: 'creative workspace artist desk'),
    'tournage': (category: 'Production', searchTopic: 'cinema camera lens gimbal'),
    // German
    'kamera': (category: 'Production', searchTopic: 'cinema camera lens gimbal'),
    'schopfer': (category: 'Media', searchTopic: 'creative workspace artist desk'),
    'aufnahme': (category: 'Production', searchTopic: 'cinema camera lens gimbal'),
    // Portuguese
    'criador': (category: 'Media', searchTopic: 'creative workspace artist desk'),
    'gravacao': (category: 'Production', searchTopic: 'video editing timeline studio'),
    // Italian
    'telecamera': (category: 'Production', searchTopic: 'cinema camera lens gimbal'),

    // -------------------------------------------------------------
    // Travel & Nature (Multilingual)
    // -------------------------------------------------------------
    // English
    'travel': (category: 'Travel', searchTopic: 'airplane travel window tropical beach'),
    'beach': (category: 'Travel', searchTopic: 'sunny tropical ocean beach drone'),
    'mountain': (category: 'Nature', searchTopic: 'mountain summit sunrise epic landscape'),
    'city': (category: 'Urban', searchTopic: 'futuristic city skyline night timelapse'),
    'earth': (category: 'Nature', searchTopic: 'planet earth space view'),
    // Spanish
    'viaje': (category: 'Travel', searchTopic: 'airplane travel window tropical beach'),
    'viajar': (category: 'Travel', searchTopic: 'airplane travel window tropical beach'),
    'playa': (category: 'Travel', searchTopic: 'sunny tropical ocean beach drone'),
    'montana': (category: 'Nature', searchTopic: 'mountain summit sunrise epic landscape'),
    'ciudad': (category: 'Urban', searchTopic: 'futuristic city skyline night timelapse'),
    'tierra': (category: 'Nature', searchTopic: 'planet earth space view'),
    'mundo': (category: 'Travel', searchTopic: 'planet earth space view'),
    // French
    'voyage': (category: 'Travel', searchTopic: 'airplane travel window tropical beach'),
    'voyager': (category: 'Travel', searchTopic: 'airplane travel window tropical beach'),
    'plage': (category: 'Travel', searchTopic: 'sunny tropical ocean beach drone'),
    'montagne': (category: 'Nature', searchTopic: 'mountain summit sunrise epic landscape'),
    'ville': (category: 'Urban', searchTopic: 'futuristic city skyline night timelapse'),
    'terre': (category: 'Nature', searchTopic: 'planet earth space view'),
    'monde': (category: 'Travel', searchTopic: 'planet earth space view'),
    // German
    'reise': (category: 'Travel', searchTopic: 'airplane travel window tropical beach'),
    'reisen': (category: 'Travel', searchTopic: 'airplane travel window tropical beach'),
    'strand': (category: 'Travel', searchTopic: 'sunny tropical ocean beach drone'),
    'berg': (category: 'Nature', searchTopic: 'mountain summit sunrise epic landscape'),
    'berge': (category: 'Nature', searchTopic: 'mountain summit sunrise epic landscape'),
    'stadt': (category: 'Urban', searchTopic: 'futuristic city skyline night timelapse'),
    'erde': (category: 'Nature', searchTopic: 'planet earth space view'),
    'welt': (category: 'Travel', searchTopic: 'planet earth space view'),
    // Portuguese
    'viagem': (category: 'Travel', searchTopic: 'airplane travel window tropical beach'),
    'praia': (category: 'Travel', searchTopic: 'sunny tropical ocean beach drone'),
    'montanha': (category: 'Nature', searchTopic: 'mountain summit sunrise epic landscape'),
    'cidade': (category: 'Urban', searchTopic: 'futuristic city skyline night timelapse'),
    // Italian
    'viaggio': (category: 'Travel', searchTopic: 'airplane travel window tropical beach'),
    'viaggiare': (category: 'Travel', searchTopic: 'airplane travel window tropical beach'),
    'spiaggia': (category: 'Travel', searchTopic: 'sunny tropical ocean beach drone'),
    'montagna': (category: 'Nature', searchTopic: 'mountain summit sunrise epic landscape'),
    'citta': (category: 'Urban', searchTopic: 'futuristic city skyline night timelapse'),
    // Hindi
    'yatra': (category: 'Travel', searchTopic: 'airplane travel window tropical beach'),
    'safar': (category: 'Travel', searchTopic: 'airplane travel window tropical beach'),
    'pahad': (category: 'Nature', searchTopic: 'mountain summit sunrise epic landscape'),
    'samundar': (category: 'Travel', searchTopic: 'sunny tropical ocean beach drone'),
    'shahar': (category: 'Urban', searchTopic: 'futuristic city skyline night timelapse'),
    'duniya': (category: 'Travel', searchTopic: 'planet earth space view'),
  };

  /// Analyzes transcribed words and returns deduplicated B-Roll cut suggestions.
  List<BRollCue> suggestBRoll(
    List<WordSchema> words, {
    double minGapBetweenCues = 4.0,
    double defaultCueDuration = 2.5,
  }) {
    if (words.isEmpty) return [];

    final visibleWords = words.where((w) => w.hidden != true).toList();
    if (visibleWords.isEmpty) return [];

    final suggestions = <BRollCue>[];
    double lastCueEnd = -minGapBetweenCues;

    for (int i = 0; i < visibleWords.length; i++) {
      final w = visibleWords[i];
      final raw = (w.text ?? '').toLowerCase().trim();
      if (raw.isEmpty) continue;

      // Extract cleaned word stripping punctuation while preserving unicode characters
      final cleaned = raw.replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
      if (cleaned.isEmpty) continue;

      final normalized = _removeDiacritics(cleaned);

      final info = _visualKeywords[cleaned] ?? _visualKeywords[normalized];

      if (info != null) {
        final startTime = w.start ?? 0.0;
        final wordEndTime = w.end ?? (startTime + 0.3);

        if (startTime - lastCueEnd >= minGapBetweenCues) {
          // Extract sentence context around word
          final startIdx = (i - 4).clamp(0, visibleWords.length);
          final endIdx = (i + 5).clamp(0, visibleWords.length);
          final context = visibleWords
              .sublist(startIdx, endIdx)
              .map((item) => item.text ?? '')
              .join(' ');

          final cueEndTime = wordEndTime + defaultCueDuration;

          suggestions.add(BRollCue(
            keyword: cleaned,
            category: info.category,
            searchTopic: info.searchTopic,
            startTime: startTime,
            endTime: cueEndTime,
            contextSentence: context,
          ));

          lastCueEnd = cueEndTime;
        }
      }
    }

    return suggestions;
  }
}
