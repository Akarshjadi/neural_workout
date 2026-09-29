with open("lib/data/app_database.dart", "r") as f:
    text = f.read()

blurt_target = """  static int _backfillAttemptsFromBlurts() {
    final src = Hive.box(_bb);
    final dst = Hive.box(_ab);
    if (src.isEmpty) return 0;
    var n = 0;
    for (final key in src.keys) {"""
blurt_replacement = """  static int _backfillAttemptsFromBlurts() {
    final src = Hive.box(_bb);
    final dst = Hive.box(_ab);
    if (src.isEmpty) return 0;

    final already = <String>{};
    for (final e in dst.values) {
      if (e is HiveAttempt) {
        final tag = e.extras?['legacy_source'];
        if (tag != null) already.add(tag as String);
      }
    }

    var n = 0;
    for (final key in src.keys) {
      final tag = 'blurt:$key';
      if (already.contains(tag)) continue;"""
text = text.replace(blurt_target, blurt_replacement)

text = text.replace(
    "        ..extras = {\n          'legacy': 'blurt',",
    "        ..extras = {\n          'legacy_source': tag,\n          'legac    "        ..extras = {\n      "    "        ..extras = {\n          'legacy_ {
    final src = Hive.box(_rb);
    final dst = Hive.box(_ab);
    var n = 0;
    for (f    for (f    for (f    for (vi    for (f    for (f    foic int _backfillAttemptsFromReviews() {
    final s    final s    final s    fal dst = H    final s    final s    final s    fal dst = H    fin already = <String>{};
    for (final e in dst.values) {
      if (e is Hiv      if (e is Hiv      i tag = e.extras?['legacy_source'];
                                    (tag as String);
      }
    }

    var n = 0;
    for (final key in src.keys) {    for (final key in src.keys) {    for (final key.contains(tag)) continue;"""
text = text.replace(review_target, review_replacement)

text = text.rtext = text.rtext = text.rtext = textacy': 'review', 'rating': r.rating ?? 'good'}",
    "        ..extras = {'legacy_sou    "        ..extras = {'legacy_sou    "         ?? 'good'}"
)

with open("lib/data/app_database.dart", "w") as f:
    f.write(text)
