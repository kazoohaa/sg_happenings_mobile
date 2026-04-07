import 'package:intl/intl.dart';

/// A row in pending or history queues (moderation / submissions).
///
/// JSON keys are flexible so different FastAPI shapes still parse.
class SubmissionRow {
  SubmissionRow({
    required this.id,
    this.eventId,
    required this.title,
    required this.status,
    this.submittedAt,
    this.detail,
  });

  /// Row id (often `submission_id` or generic `id`).
  final String id;

  /// Event row id when the API sends both submission and event (use for GET/PATCH/DELETE `/events/...`).
  final String? eventId;

  final String title;
  final String status;
  final DateTime? submittedAt;
  final String? detail;

  /// Prefer [eventId] for event-scoped APIs when present.
  String get effectiveEventId {
    final e = eventId?.trim();
    if (e != null && e.isNotEmpty) return e;
    return id.trim();
  }

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
    final eventIdRaw = json['event_id']?.toString().trim();
    final submissionId = json['submission_id']?.toString().trim();
    final genericId = json['id']?.toString().trim();
    final primaryId = submissionId?.isNotEmpty == true
        ? submissionId!
        : (genericId?.isNotEmpty == true
            ? genericId!
            : (eventIdRaw?.isNotEmpty == true ? eventIdRaw! : ''));
    return SubmissionRow(
      id: primaryId,
      eventId: eventIdRaw?.isNotEmpty == true ? eventIdRaw : null,
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
