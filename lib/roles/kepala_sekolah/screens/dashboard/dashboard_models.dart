class IssueItem {
  final String title;
  final String status;

  const IssueItem({required this.title, required this.status});
}

class EventItem {
  final String title;
  final String schedule;
  final String location;

  const EventItem({
    required this.title,
    required this.schedule,
    required this.location,
  });
}

class ComparisonItem {
  final String title;
  final String subtitle;
  final String badge;

  const ComparisonItem({
    required this.title,
    required this.subtitle,
    required this.badge,
  });
}

class TrendItem {
  final String label;
  final String primaryValue;
  final String secondaryValue;

  const TrendItem({
    required this.label,
    required this.primaryValue,
    required this.secondaryValue,
  });
}

class InsightItem {
  final String title;
  final String description;
  final String badge;

  const InsightItem({
    required this.title,
    required this.description,
    required this.badge,
  });
}

class CrossModuleItem {
  final String title;
  final String value;
  final String note;

  const CrossModuleItem({
    required this.title,
    required this.value,
    required this.note,
  });
}

class SnapshotItem {
  final String label;
  final String value;
  final String note;

  const SnapshotItem({
    required this.label,
    required this.value,
    required this.note,
  });
}
