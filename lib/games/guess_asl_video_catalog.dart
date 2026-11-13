import '../models/alphabet_sign.dart';
import '../models/number_sign.dart';

class GuessAslVideoSource {
  final String videoUrl;
  final String videoAsset;

  const GuessAslVideoSource({
    required this.videoUrl,
    required this.videoAsset,
  });
}

String guessAslVideoKey(String type, String label) =>
    '${type.toUpperCase()}:${label.trim().toUpperCase()}';

Map<String, GuessAslVideoSource> buildGuessAslVideoCatalog({
  required List<AlphabetSign> alphabetSigns,
  required List<NumberSign> numberSigns,
}) {
  return {
    for (final sign in alphabetSigns)
      guessAslVideoKey('ALPHABET', sign.letter): GuessAslVideoSource(
        videoUrl: sign.videoUrl.trim().isNotEmpty
            ? sign.videoUrl
            : sign.frontVideoUrl,
        videoAsset: sign.videoAsset,
      ),
    for (final sign in numberSigns)
      guessAslVideoKey('NUMBER', sign.number.toString()): GuessAslVideoSource(
        videoUrl: sign.videoUrl.trim().isNotEmpty
            ? sign.videoUrl
            : sign.frontVideoUrl,
        videoAsset: sign.videoAsset,
      ),
  };
}
