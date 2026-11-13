import 'package:flutter_test/flutter_test.dart';
import 'package:sign_language_app/games/guess_asl_video_catalog.dart';
import 'package:sign_language_app/models/alphabet_sign.dart';
import 'package:sign_language_app/models/number_sign.dart';

void main() {
  test('matches lesson videos by normalized letter and number keys', () {
    final catalog = buildGuessAslVideoCatalog(
      alphabetSigns: [
        AlphabetSign.fromJson({
          'letter': 'a',
          'video_url': 'lesson-a-video',
        }),
      ],
      numberSigns: [
        NumberSign.fromJson({
          'number': 10,
          'video_url': 'lesson-10-video',
        }),
      ],
    );

    expect(catalog['ALPHABET:A']?.videoUrl, 'lesson-a-video');
    expect(catalog['NUMBER:10']?.videoUrl, 'lesson-10-video');
    expect(catalog.containsKey('NUMBER:0'), isFalse);
  });

  test('uses the lesson front-view URL when its default URL is empty', () {
    final catalog = buildGuessAslVideoCatalog(
      alphabetSigns: [
        AlphabetSign.fromJson({
          'letter': 'B',
          'video_url': '',
          'front_video_url': 'lesson-front-b-video',
        }),
      ],
      numberSigns: const [],
    );

    expect(
      catalog['ALPHABET:B']?.videoUrl,
      'lesson-front-b-video',
    );
  });
}
