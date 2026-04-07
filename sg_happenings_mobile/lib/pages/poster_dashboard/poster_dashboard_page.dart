import 'package:flutter/material.dart';

import '../../api/app_api.dart';
import '../../api/event_list_item.dart';
import '../../api/event_poster_repository.dart';
import '../../api/submission_row.dart';
import '../events_details/events_details_page.dart';
import 'create_edit_event_page.dart';

class PosterDashboardPage extends StatefulWidget {
  const PosterDashboardPage({super.key});

  @override
  State<PosterDashboardPage> createState() => _PosterDashboardPageState();
}

class _PosterDashboardPageState extends State<PosterDashboardPage> {
  bool _loading = true;
  String? _approvedError;
  String? _pendingError;
  String? _historyError;
  List<EventListItem> _approved = [];
  List<SubmissionRow> _pending = [];
  List<SubmissionRow> _history = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _approvedError = null;
      _pendingError = null;
      _historyError = null;
    });

    await Future.wait([
      _loadApproved(),
      _loadPending(),
      _loadHistory(),
    ]);

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadApproved() async {
    try {
      final list = await eventPosterRepository.listMyApprovedEvents();
      if (!mounted) return;
      setState(() => _approved = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _approvedError = e.toString());
    }
  }

  Future<void> _loadPending() async {
    try {
      final list = await eventPosterRepository.listPendingSubmissions();
      if (!mounted) return;
      setState(() => _pending = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _pendingError = e.toString());
    }
  }

  Future<void> _loadHistory() async {
    try {
      final list = await eventPosterRepository.listSubmissionHistory();
      if (!mounted) return;
      setState(() => _history = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _historyError = e.toString());
    }
  }

  Future<void> _openCreate() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const CreateEditEventPage(),
      ),
    );
    if (saved == true && mounted) await _bootstrap();
  }

  Future<void> _openEdit(EventListItem event) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => CreateEditEventPage(existing: event),
      ),
    );
    if (saved == true && mounted) await _bootstrap();
  }

  Future<void> _openEditSubmission(SubmissionRow row) async {
    final eventId = row.effectiveEventId;
    if (eventId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing id for this submission.')),
      );
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('Loading event…')),
          ],
        ),
      ),
    );
    try {
      final event = await eventPosterRepository.getEvent(eventId);
      if (!mounted) return;
      Navigator.of(context).pop();
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (context) => CreateEditEventPage(existing: event),
        ),
      );
      if (saved == true && mounted) await _bootstrap();
    } on PosterApiException catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load event: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteSubmission(SubmissionRow row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete submission?'),
        content: Text(
          '“${row.title}” will be removed. This may not be reversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await eventPosterRepository.deleteEvent(row.effectiveEventId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission deleted.')),
      );
      await _bootstrap();
    } on PosterApiException catch (e) {
      if (row.id != row.effectiveEventId) {
        try {
          await eventPosterRepository.deleteEventApplication(row.id);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Submission deleted.')),
          );
          await _bootstrap();
          return;
        } on PosterApiException catch (e2) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e2.message)),
          );
          return;
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _confirmDelete(EventListItem event) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete event?'),
        content: Text(
          '“${event.title}” will be removed. This may not be reversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await eventPosterRepository.deleteEvent(event.eventId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event deleted.')),
      );
      await _bootstrap();
    } on PosterApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _bootstrap,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your events and submissions.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _loading ? null : _openCreate,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Create event'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B35),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_loading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              SliverToBoxAdapter(child: _sectionTitle('Current events')),
              if (_approvedError != null)
                SliverToBoxAdapter(child: _errorCard(_approvedError!))
              else if (!_loading && _approved.isEmpty)
                SliverToBoxAdapter(
                  child: _emptyHint('No current events yet.'),
                )
              else ...[
                SliverToBoxAdapter(child: _subsectionTitle('Published')),
                _approvedEventsSliver(
                  _publishedOnly(_approved),
                  loading: _loading,
                ),
                SliverToBoxAdapter(child: _subsectionTitle('Completed')),
                _approvedEventsSliver(
                  _completedOnly(_approved),
                  loading: _loading,
                ),
                if (_otherCurrentOnly(_approved).isNotEmpty) ...[
                  SliverToBoxAdapter(child: _subsectionTitle('Other')),
                  _approvedEventsSliver(
                    _otherCurrentOnly(_approved),
                    loading: _loading,
                  ),
                ],
              ],
              SliverToBoxAdapter(child: _sectionTitle('Pending submissions')),
              if (_pendingError != null)
                SliverToBoxAdapter(child: _errorCard(_pendingError!))
              else if (!_loading && _pending.isEmpty)
                SliverToBoxAdapter(
                  child: _emptyHint('Nothing waiting for review.'),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: _SubmissionTile(
                        row: _pending[i],
                        onEdit: () => _openEditSubmission(_pending[i]),
                        onDelete: () => _confirmDeleteSubmission(_pending[i]),
                      ),
                    ),
                    childCount: _loading ? 0 : _pending.length,
                  ),
                ),
              SliverToBoxAdapter(child: _sectionTitle('Submission history')),
              if (_historyError != null)
                SliverToBoxAdapter(child: _errorCard(_historyError!))
              else if (!_loading && _history.isEmpty)
                SliverToBoxAdapter(
                  child: _emptyHint('No past submissions yet.'),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: _SubmissionTile(row: _history[i]),
                    ),
                    childCount: _loading ? 0 : _history.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  List<EventListItem> _publishedOnly(List<EventListItem> all) =>
      all.where((e) => e.isStatusPublished).toList();

  List<EventListItem> _completedOnly(List<EventListItem> all) =>
      all.where((e) => e.isStatusCompleted).toList();

  List<EventListItem> _otherCurrentOnly(List<EventListItem> all) =>
      all.where((e) => e.isStatusOtherCurrent).toList();

  /// One sliver: cards for [items], or a short empty line when not [loading].
  Widget _approvedEventsSliver(
    List<EventListItem> items, {
    required bool loading,
  }) {
    if (loading) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 16, bottom: 10),
          child: Text(
            'None yet.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: _ApprovedEventCard(
            event: items[i],
            onTapDetails: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => EventsDetailsPage(
                    event: items[i].toDetailMap(),
                  ),
                ),
              );
            },
            onEdit: () => _openEdit(items[i]),
            onDelete: () => _confirmDelete(items[i]),
          ),
        ),
        childCount: items.length,
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.brown.shade900,
        ),
      ),
    );
  }

  Widget _subsectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.brown.shade700,
        ),
      ),
    );
  }

  Widget _errorCard(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange[800]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyHint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey[600], fontSize: 14),
      ),
    );
  }
}

class _ApprovedEventCard extends StatelessWidget {
  const _ApprovedEventCard({
    required this.event,
    required this.onTapDetails,
    required this.onEdit,
    required this.onDelete,
  });

  final EventListItem event;
  final VoidCallback onTapDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF0EDE8),
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onTapDetails,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PosterThumb(event: event),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.formattedStart,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            event.location,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (event.status.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              event.status,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.brown[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[700]),
                  label: Text('Delete', style: TextStyle(color: Colors.red[700])),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PosterThumb extends StatelessWidget {
  const _PosterThumb({required this.event});

  final EventListItem event;

  @override
  Widget build(BuildContext context) {
    final url = event.primaryImageUrl;
    if (url != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(context),
        ),
      );
    }
    if (event.media.isNotEmpty && event.media.first.isVideo) {
      return Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.play_circle_filled, color: Colors.white54, size: 36),
      );
    }
    return _placeholder(context);
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35).withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.event, color: Color(0xFFFF6B35)),
    );
  }
}

class _SubmissionTile extends StatelessWidget {
  const _SubmissionTile({
    required this.row,
    this.onEdit,
    this.onDelete,
  });

  final SubmissionRow row;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF0EDE8),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              row.title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              row.submittedLine,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    row.statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.brown[800],
                    ),
                  ),
                ),
              ],
            ),
            if (row.detail != null && row.detail!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                row.detail!,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ],
            if (onEdit != null || onDelete != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onEdit != null)
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                  if (onDelete != null)
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[700]),
                      label: Text('Delete', style: TextStyle(color: Colors.red[700])),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
