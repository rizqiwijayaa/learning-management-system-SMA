class HumasRecord {
  final int id;
  final String title;
  final String category;
  final String partner;
  final String location;
  final String scheduleDate;
  final String status;
  final String description;

  const HumasRecord({
    required this.id,
    required this.title,
    required this.category,
    required this.partner,
    required this.location,
    required this.scheduleDate,
    required this.status,
    required this.description,
  });

  factory HumasRecord.fromJson(Map<String, dynamic> json) {
    return HumasRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: '${json['title'] ?? ''}',
      category: '${json['category'] ?? ''}',
      partner: '${json['partner'] ?? ''}',
      location: '${json['location'] ?? ''}',
      scheduleDate: '${json['schedule_date'] ?? json['scheduleDate'] ?? ''}',
      status: '${json['status'] ?? ''}',
      description: '${json['description'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'partner': partner,
      'location': location,
      'schedule_date': scheduleDate,
      'status': status,
      'description': description,
    };
  }
}
