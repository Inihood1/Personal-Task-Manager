/// Formats a [DateTime] into a short, human-friendly label for task metadata.
///
/// Uses relative wording for recent times ("just now", "5m ago", "3h ago",
/// "2d ago") and falls back to an absolute date ("15 Jul 2026") beyond a week.
/// Kept intl-free to avoid an extra dependency for a single format.
String formatTaskDate(DateTime dateTime, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final diff = reference.difference(dateTime);

  if (diff.isNegative) return 'just now';
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';

  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
}
