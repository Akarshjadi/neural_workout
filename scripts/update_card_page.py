import os

path = '/Users/akarsh/Desktop/Prompts/study/neural_workout_app/lib/ui/pages/card_page.dart'
with open(path, 'r') as f:
    text = f.read()

# Replace _RateLink constructor calls
text = text.replace("() => state.reviewNote(note, fsrs.Rating.again)", "() => handleRate(context, state, note, fsrs.Rating.again)")
text = text.replace("() => state.reviewNote(note, fsrs.Rating.hard)", "() => handleRate(context, state, note, fsrs.Rating.hard)")
text = text.replace("() => state.reviewNote(note, fsrs.Rating.good)", "() => handleRate(context, state, note, fsrs.Rating.good)")
text = text.replace("() => state.reviewNote(note, fsrs.Rating.easy)", "() => handleRate(context, state, note, fsrs.Rating.easy)")

parts = text.split("class _RateLink extends StatelessWidget {")
new_class = """
  Future<void> handleRate(BuildContext context, AppState state, Note note, fsrs.Rating rating) async {
    await state.reviewNote(note, rating);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('FSRS spacing updated.', style: TextStyle(fontFamily: 'monospace'))),
    );
    final dueCount = state.dueNotesList.length;
    if (dueCount > 0) {
        final target = state.dueNotesList.first;
        state.startSession('Review: ${target.title}', anchorNoteId: target.id);
        state.triggerPage(5); // Stay on card page
    } else {
        state.triggerPage(2);
    }
  }
}

class _RateLink extends StatelessWidget {"""
text = new_class.join(parts)

text = text.replace("final VoidCallback onTap;", "final Future<void> Function() onTap;")

inkwell_snippet = """    return InkWell(
      onTap: () {
        onTap();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('FSRS spacing updated.', style: TextStyle(fontFamily: 'monospace'))),
        );
      },"""
new_inkwell = """    return InkWell(
      onTap: onTap,"""
text = text.replace(inkwell_snippet, new_inkwell)

with open(path, 'w') as f:
    f.write(text)
