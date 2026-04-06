import 'package:flutter/material.dart';

import '../../api/app_api.dart';
import '../../api/category_option.dart';
import '../../api/create_event_payload.dart';
import '../../api/event_list_item.dart';
import '../../api/event_poster_repository.dart';

class CreateEditEventPage extends StatefulWidget {
  const CreateEditEventPage({super.key, this.existing});

  /// When non-null, PATCH [existing.eventId]; otherwise POST new event.
  final EventListItem? existing;

  @override
  State<CreateEditEventPage> createState() => _CreateEditEventPageState();
}

class _CreateEditEventPageState extends State<CreateEditEventPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _location;
  late final TextEditingController _categoryIdManual;
  late final TextEditingController _capacity;

  List<CategoryOption> _categories = [];
  String? _selectedCategoryId;
  /// True when the event's category is not in the dropdown list.
  bool _manualCategoryFallback = false;
  DateTime? _start;
  DateTime? _end;
  bool _loadingCategories = true;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _location = TextEditingController(text: e?.location ?? '');
    _categoryIdManual = TextEditingController(text: e?.categoryId ?? '');
    _selectedCategoryId = e?.categoryId.isNotEmpty == true ? e!.categoryId : null;
    _start = e?.startTime;
    _end = e?.endTime;
    _capacity = TextEditingController(
      text: e?.capacity != null ? '${e!.capacity}' : '',
    );
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final list = await eventPosterRepository.listCategories();
      if (!mounted) return;
      setState(() {
        _categories = list;
        if (_selectedCategoryId != null &&
            !_categories.any((c) => c.id == _selectedCategoryId)) {
          _manualCategoryFallback = true;
          _categoryIdManual.text = _selectedCategoryId!;
        }
        _loadingCategories = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCategories = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _categoryIdManual.dispose();
    _capacity.dispose();
    super.dispose();
  }

  String get _effectiveCategoryId {
    if (_categories.isNotEmpty &&
        !_manualCategoryFallback &&
        _selectedCategoryId != null) {
      return _selectedCategoryId!;
    }
    return _categoryIdManual.text.trim();
  }

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final initial = _start ?? now;
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (t == null || !mounted) return;
    setState(() {
      _start = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  Future<void> _pickEnd() async {
    final base = _start ?? DateTime.now();
    final initial = _end ?? base.add(const Duration(hours: 2));
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(base.year - 1),
      lastDate: DateTime(base.year + 5),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (t == null || !mounted) return;
    setState(() {
      _end = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;

    final cat = _effectiveCategoryId;
    if (cat.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose or enter a category.')),
      );
      return;
    }
    if (_start == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set a start date and time.')),
      );
      return;
    }

    final capRaw = _capacity.text.trim();
    int? cap;
    if (capRaw.isNotEmpty) {
      cap = int.tryParse(capRaw);
      if (cap == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Capacity must be a number.')),
        );
        return;
      }
    }

    final payload = CreateEventPayload(
      title: _title.text.trim(),
      description: _description.text.trim(),
      location: _location.text.trim(),
      categoryId: cat,
      startTime: _start,
      endTime: _end,
      capacity: cap,
    );

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await eventPosterRepository.updateEvent(widget.existing!.eventId, payload);
      } else {
        await eventPosterRepository.createEvent(payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on PosterApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save event.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F3F0),
        foregroundColor: Colors.brown.shade900,
        elevation: 0,
        title: Text(_isEdit ? 'Edit event' : 'Create event'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _field(
                label: 'Title',
                controller: _title,
                isRequired: true,
              ),
              const SizedBox(height: 12),
              _field(
                label: 'Description',
                controller: _description,
                maxLines: 4,
                isRequired: true,
              ),
              const SizedBox(height: 12),
              _field(
                label: 'Location',
                controller: _location,
                isRequired: true,
              ),
              const SizedBox(height: 12),
              if (_loadingCategories)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: LinearProgressIndicator(),
                  ),
                )
              else if (_categories.isNotEmpty && !_manualCategoryFallback) ...[
                DropdownButtonFormField<String>(
                  value: _selectedCategoryId != null &&
                          _categories.any((c) => c.id == _selectedCategoryId)
                      ? _selectedCategoryId
                      : null,
                  decoration: _inputDecoration('Category'),
                  items: _categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name.isNotEmpty ? c.name : c.id),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Pick a category';
                    return null;
                  },
                ),
              ] else ...[
                _field(
                  label: 'Category ID',
                  controller: _categoryIdManual,
                  hint: 'UUID from your API',
                  isRequired: true,
                ),
              ],
              const SizedBox(height: 12),
              _dateRow(
                label: 'Starts',
                value: _start,
                onTap: _pickStart,
              ),
              const SizedBox(height: 8),
              _dateRow(
                label: 'Ends (optional)',
                value: _end,
                onTap: _pickEnd,
                clearable: true,
                onClear: () => setState(() => _end = null),
              ),
              const SizedBox(height: 12),
              _field(
                label: 'Capacity (optional)',
                controller: _capacity,
                keyboard: TextInputType.number,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isEdit ? 'Save changes' : 'Submit event'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateRow({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    VoidCallback? onClear,
    bool clearable = false,
  }) {
    final text = value != null
        ? '${MaterialLocalizations.of(context).formatFullDate(value)} · '
            '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(value))}'
        : 'Tap to set';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: _inputDecoration(label),
              child: Text(
                text,
                style: TextStyle(
                  color: value != null ? Colors.black87 : Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        if (clearable && value != null) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.clear),
            tooltip: 'Clear',
          ),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: _inputDecoration(label, hint: hint),
      validator: (v) {
        if (!isRequired) return null;
        if (v == null || v.trim().isEmpty) return 'Required';
        return null;
      },
    );
  }
}
