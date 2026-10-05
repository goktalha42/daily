import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Günlük bulmaca tohumu (seed) üretimi.
///
/// `seed = HMAC_SHA256(secret, "<oyun_id>|<YYYY-MM-DD>|<salt>")`
///
/// Tohum her oyun, gün ve deneme için farklıdır; sabit tohumlu havuz yoktur.
/// README Bölüm 4'e bakın.
class PuzzleSeed {
  /// SADECE yerel geliştirme (Aşama A) için gizli anahtar.
  /// Aşama B'de (VDS) gerçek anahtar yalnızca sunucuda durur ve istemciye gönderilmez.
  static const String devSecret = 'zuhtu-local-dev-secret';

  const PuzzleSeed._();

  /// 32 baytlık ham HMAC-SHA256 çıktısı.
  static List<int> derive(
    String gameId,
    String dateId, {
    String salt = '',
    String secret = devSecret,
  }) {
    final hmac = Hmac(sha256, utf8.encode(secret));
    return hmac.convert(utf8.encode('$gameId|$dateId|$salt')).bytes;
  }

  /// HMAC çıktısının ilk 4 baytını işaretsiz 32-bit tamsayıya çevirir.
  static int toInt(List<int> bytes) {
    return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
  }

  /// Verilen oyun/gün/denemeye özel deterministik rastgele sayı üreteci.
  static Random random(
    String gameId,
    String dateId, {
    String salt = '',
    String secret = devSecret,
  }) {
    return Random(toInt(derive(gameId, dateId, salt: salt, secret: secret)));
  }

  /// Kanonik tahta metninin SHA-256 parmak izi (benzersizlik kontrolü için).
  static String fingerprint(String canonicalBoard) {
    return sha256.convert(utf8.encode(canonicalBoard)).toString();
  }
}
