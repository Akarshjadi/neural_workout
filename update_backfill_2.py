import re

with open("lib/data/app_database.dart", "r") as f:
    text = f.read()

# Blurts replacement
blurt_target_regex = r"(static\s+int\s+_backfillAttemptsFromBlurts\(\)\s*\{[^{]*?if\s*\(src\.isEmpty\)\s*return\s*0;\s*)(var\s+n\s*=\s*0;\s*for\s*\(final\s+key\s+in\s+src\.keys\)\s*\{)"
blurt_replacement = r"\1\n    final already = <String>{};\n    for (final e in dst.values) {\n      if (e is HiveAttempt) {\n        final tag = e.extras?['legacy_source'];\n        if (tag != null) already.add(tag as String);\n      }\n    }\n\n    var n = 0;\n    for (final key in src.keys) {\n      final tag = 'blurt:$key';\n      if (already.contains(tag)) continue;"
text = re.sub(blurt_target_regex, blurt_replacement, text)

# Blurts extras replacement
blurt_extras_regex = r"(\.\.extras\s*=\s*\{\s*)('legacy':\s*'blurt',)"
blurt_extras_replacement = r"\1'legacy_source': tag,\n          \2"
text = re.sub(blurt_extras_regex, blurt_extras_replacement, text)


# Reviews replacement
review_target_regex = r"(static\s+int\s+_backfillAttemptsFromReviews\(\)\s*\{[^{]*?)(var\s+n\s*=\s*0;\s*freview_target_rege\s+review_target_\)\s*\{)"
review_replacement = r"\1if (src.isEmpty) return 0;\n\n    final already = <String>{};\n    for (final e in dst.values) {\n      if (e is HiveAttempt) {\n        final tag = e.extras?['legacy_source'];\n        if (tag != null) already.add(tag as String);\n      }\n    }\n\n    var n = 0;\n    for (final key in src.keys) {\n      final tag = 'review:$key';\n      if (already.contains(tag)) continue;"
text = re.sub(review_target_regex, review_replacement, text)


# Reviews extras replacement
review_extras_regex = r"(\.\.extras\s*=\s*\{)('legacy':\s*'review',\s*'rating':\s*r\.rating\s*\?\?\s*'good'\})"
review_extras_replacement = r"\1'legacy_source': tag, \2"
text = re.sub(review_extras_regex, review_extras_rtext = re.sub(review_extras_regex, review_extras_rtext = re"w") as f:
    f.write(text)
