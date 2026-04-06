import 'package:intl/intl.dart';

/// A row in pending or history queues (moderation / submissions).
///
/// JSON keys are flexible so different FastAPI shapes still parse.
class SubmissionRow {
  SubmissionRow({
    required this.id,
    required this.title,
    required this.status,
    this.submittedAt,
    this.detail,
  });

  final String id;
  final String title;
  final String status;
  final DateTime? submittedAt;
  final String? detail;

  String get statusLabel {
    if (status.isEmpty) return '—';
    return status.replaceAll('_', ' ');
  }

  String get submittedLine {
    final t = submittedAt;
    if (t == null) return 'Date unknown';
    return DateFormat('MMM d, y • h:mm a').format(t.toLocal());
  }

  factory SubmissionRow.fromJson(Map<String, dynamic> json) {
    return SubmissionRow(
      id: json['submission_id']?.toString() ??
          json['id']?.toString() ??
          json['event_id']?.toString() ??
          '',
      title: json['title'] as String? ?? 'Untitled',
      status: json['status'] as String? ??
          json['submission_status'] as String? ??
          '',
      submittedAt: _parseDate(json['submitted_at'] ?? json['created_at']),
      detail: json['detail'] as String? ??
          json['note'] as String? ??
          json['rejection_reason'] as String?,
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null || v is! String || v.isEmpty) return null;
    return DateTime.tryParse(v);
  }
}
