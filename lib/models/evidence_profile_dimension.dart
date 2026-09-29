class EvidenceProfileDimension {
  final String label;
  final double value; // 0.0 to 1.0
  final String detail;

  const EvidenceProfileDimension({
    required this.label,
    required this.value,
    this.detail = '',
  });
}
