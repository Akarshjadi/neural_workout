/// Seeds the app with real content so you're not starting from a blank slate
/// (PLAN §7, decision #11; ARCH §10).
///
/// Two modes:
///   - paste text → one note
///   - structured markdown → split on `##`/`###` headers into atomic notes,
///     which maps your existing `DCCN_MID1_CheatSheet.md` straight into the
///     knowledge graph.
///
/// No AI parsing — deterministic, and the caller can adjust after.
class ImportService {
  /// Splits a markdown body on ## / ### headings into (title, body) slices.
  /// This is the pure, testable part. The caller constructs real Notes with a
  /// fresh FSRS Card.
  static List<({String title, String body})> splitMarkdown(String md) {
    final lines = md.split('\n');
    final sections = <({String title, String body})>[];
    String? currentTitle;
    final currentBody = <String>[];

    void flush() {
      final title = currentTitle;
      if (title != null) {
        final body = currentBody.join('\n').trim();
        if (body.isNotEmpty) {
          sections.add((title: title, body: body));
        }
      }
      currentBody.clear();
    }

    for (final line in lines) {
      final header = RegExp(r'^#{2,3}\s+(.*)$').firstMatch(line);
      if (header != null) {
        flush();
        currentTitle = header.group(1)!.trim();
      } else {
        currentBody.add(line);
      }
    }
    flush();
    return sections;
  }
}