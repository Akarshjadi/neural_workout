import os
p = "lib/state/app_state.dart"
lines = open(p).readlines()
for i, line in enumerate(lines):
    if line.startswith("  Future<void> startSession(String anchorTitle, {int? anchorNoteId}) async {"):
        lines[i] = "  Future<void> startSession(String anchorTitle, {int? anchorNoteId}) async {\n    if (_transitioning) return;\n    _transitioning = true;\n    try {\n"
    elif line.startswith("  Future<BlurtScore?> finishBlurt({"):
        lines[i] = "  Future<BlurtScore?> finishBlurt({\n    if (_transitioning) return null;\n    _transitioning = true;\n    try {\n"
    elif "notifyListeners();" in line and "}" in lines[i+1] and "Future<void> startSession" in "".join(lines[max(0, i-50):i]): # very naive
        pass 
open(p, "w").writelines(lines)
