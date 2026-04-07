import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/api_config.dart';

import '../../api/app_api.dart';
import '../../api/category_option.dart';
import '../../api/create_event_payload.dart';
import '../../api/event_application_create_payload.dart';
import '../../api/event_list_item.dart';
import '../../api/event_media_item.dart';
import '../../api/event_poster_repository.dart';
import '../../api/jwt_payload.dart';
import '../../api/user_me.dart';

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
  late final TextEditingController _postalCode;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;
  late final TextEditingController _categoryIdManual;
  late final TextEditingController _capacity;

  List<CategoryOption> _categories = [];
  final Set<String> _selectedCategoryIds = {};
  bool _manualCategoryFallback = false;
  DateTime? _start;
  DateTime? _end;
  bool _loadingCategories = true;
  bool _saving = false;
  bool _uploadingMedia = false;

  final List<EventMediaItem> _mediaItems = [];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _location = TextEditingController(text: e?.location ?? '');
    _postalCode = TextEditingController(text: e?.postalCode ?? '');
    _latitude = TextEditingController(
      text: e?.latitude != null ? _coordText(e!.latitude!) : '',
    );
    _longitude = TextEditingController(
      text: e?.longitude != null ? _coordText(e!.longitude!) : '',
    );
    _categoryIdManual = TextEditingController();
    if (e?.categoryId.isNotEmpty == true) {
      _selectedCategoryIds.add(e!.categoryId);
    }
    _start = e?.startTime;
    _end = e?.endTime;
    _capacity = TextEditingController(
      text: e == null
          ? '50'
          : (e.capacity != null ? '${e.capacity}' : ''),
    );
    if (e != null) {
      _mediaItems.addAll(e.media);
    }
    _loadCategories();
  }

  static String _coordText(double v) {
    if (v == v.roundToDouble()) {
      return '${v.round()}';
    }
    return v.toString();
  }

  Future<void> _loadCategories() async {
    try {
      final list = await eventPosterRepository.listCategories();
      if (!mounted) return;
      setState(() {
        _categories = list;
        if (_categories.isEmpty) {
          if (_selectedCategoryIds.isNotEmpty) {
            _manualCategoryFallback = true;
            _categoryIdManual.text = _selectedCategoryIds.join(', ');
          }
        } else if (_selectedCategoryIds.isNotEmpty) {
          final allInList = _selectedCategoryIds.every(
            (id) => _categories.any((c) => c.id == id),
          );
          if (!allInList) {
            _manualCategoryFallback = true;
            _categoryIdManual.text = _selectedCategoryIds.join(', ');
          }
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
    _postalCode.dispose();
    _latitude.dispose();
    _longitude.dispose();
    _categoryIdManual.dispose();
    _capacity.dispose();
    super.dispose();
  }

  List<String> get _effectiveCategoryIds {
    if (_categories.isNotEmpty && !_manualCategoryFallback) {
      final out = _selectedCategoryIds.toList();
      out.sort();
      return out;
    }
    return _categoryIdManual.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
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

  Future<void> _pickAndUploadMedia() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Photo from gallery'),
              onTap: () => Navigator.pop(ctx, 'photo'),
            ),
            ListTile(
              leading: const Icon(Icons.video_library_outlined),
              title: const Text('Video from gallery'),
              onTap: () => Navigator.pop(ctx, 'video'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;

    final picker = ImagePicker();
    final XFile? file = choice == 'photo'
        ? await picker.pickImage(source: ImageSource.gallery)
        : await picker.pickVideo(source: ImageSource.gallery);
    if (file == null || !mounted) return;

    setState(() => _uploadingMedia = true);
    try {
      final url = await eventPosterRepository.uploadEventMedia(
        filePath: file.path,
        filename: file.name,
      );
      if (!mounted) return;
      setState(() {
        _mediaItems.add(EventMediaItem.fromUrlString(url));
      });
    } on PosterApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed.')),
      );
    } finally {
      if (mounted) setState(() => _uploadingMedia = false);
    }
  }

  void _removeMediaAt(int index) {
    setState(() {
      _mediaItems.removeAt(index);
    });
  }

  void _previewMedia(EventMediaItem item) {
    final url = item.resolvedUrl;
    if (item.isVideo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video preview opens after the event is saved.')),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }

  bool _validateOptionalCoordinates() {
    final latT = _latitude.text.trim();
    final lonT = _longitude.text.trim();
    if (latT.isEmpty && lonT.isEmpty) return true;
    if (latT.isEmpty || lonT.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter both latitude and longitude, or leave both empty.'),
        ),
      );
      return false;
    }
    final lat = double.tryParse(latT.replaceAll(',', '.'));
    final lon = double.tryParse(lonT.replaceAll(',', '.'));
    if (lat == null || lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Latitude and longitude must be valid numbers.')),
      );
      return false;
    }
    return true;
  }

  double? _latValue() {
    final latT = _latitude.text.trim();
    final lonT = _longitude.text.trim();
    if (latT.isEmpty && lonT.isEmpty) return null;
    return double.tryParse(latT.replaceAll(',', '.'));
  }

  double? _lonValue() {
    final latT = _latitude.text.trim();
    final lonT = _longitude.text.trim();
    if (latT.isEmpty && lonT.isEmpty) return null;
    return double.tryParse(lonT.replaceAll(',', '.'));
  }

  /// Resolves `event_poster_id`: prefers [usersRepository.getMe] `userId`, then JWT
  /// (`user_id` / `userID` / `userId` / nested `user`, then `sub`). If `getMe` throws
  /// or omits id, JWT is still used so create can proceed when only the token has the id.
  Future<String?> _resolvePosterUserId() async {
    try {
      final me = await usersRepository.getMe();
      final id = me.userId?.trim();
      if (id != null && id.isNotEmpty) return id;
    } catch (_) {
      // e.g. network or 401; fall through to JWT
    }
    final token = authTokenStore.accessToken;
    final claims = token != null ? decodeJwtPayload(token) : null;
    if (claims == null) return null;
    return UserMe.userIdFromClaims(claims)?.trim();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;

    final cats = _effectiveCategoryIds;
    if (cats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose at least one category (or enter comma-separated IDs).'),
        ),
      );
      return;
    }
    if (!_validateOptionalCoordinates()) return;

    final lat = _latValue();
    final lon = _lonValue();
    final postal = _postalCode.text.trim();

    if (_start == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set a start date and time.')),
      );
      return;
    }
    if (!_isEdit && _end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Set an end date and time (required for submission).'),
        ),
      );
      return;
    }
    if (!_isEdit && _end != null && !_end!.isAfter(_start!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    final capRaw = _capacity.text.trim();
    if (capRaw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter capacity.')),
      );
      return;
    }
    final cap = int.tryParse(capRaw);
    if (cap == null || cap < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capacity must be a positive number.')),
      );
      return;
    }

    setState(() => _saving = true);
    if (kDebugMode) {
      debugPrint('[CreateEvent] API base: ${ApiConfig.baseUrl}');
      debugPrint(
        '[CreateEvent] ${_isEdit ? "PATCH existing" : "POST new application"}',
      );
      debugPrint('[CreateEvent] category_ids: $cats');
      debugPrint('[CreateEvent] start=$_start end=$_end capacity=$cap');
    }
    try {
      if (_isEdit) {
        final payload = CreateEventPayload(
          title: _title.text.trim(),
          description: _description.text.trim(),
          location: _location.text.trim(),
          postalCode: postal.isEmpty ? null : postal,
          categoryIds: cats,
          startTime: _start,
          endTime: _end,
          capacity: cap,
          latitude: lat,
          longitude: lon,
          mediaUrls: _mediaItems.map((m) => m.url).toList(),
        );
        await eventPosterRepository.updateEvent(widget.existing!.eventId, payload);
      } else {
        final posterId = await _resolvePosterUserId();
        if (posterId == null || posterId.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not determine your user id. Ensure /users/me or your JWT includes user_id.',
              ),
            ),
          );
          return;
        }
        final application = EventApplicationCreatePayload(
          eventPosterId: posterId,
          categoryIds: cats,
          title: _title.text.trim(),
          description: _description.text.trim(),
          location: _location.text.trim(),
          postalCode: postal.isEmpty ? null : postal,
          latitude: lat,
          longitude: lon,
          startDatetime: _start!,
          endDatetime: _end!,
          capacity: cap,
          mediaUrls: _mediaItems.map((m) => m.url).toList(),
        );
        await eventPosterRepository.createEventApplication(application);
      }
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint('[CreateEvent] success, popping route');
      }
      Navigator.of(context).pop(true);
    } on PosterApiException catch (e, st) {
      if (kDebugMode) {
        debugPrint('[CreateEvent] PosterApiException: ${e.message}');
        debugPrint('$st');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[CreateEvent] unexpected error: $e');
        debugPrint('$st');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save event: $e')),
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
        title: Text(_isEdit ? 'Edit event' : 'New event'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionLabel('Categories *'),
              const SizedBox(height: 4),
              Text(
                'Tap one or more categories.',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              if (_loadingCategories)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                )
              else if (_categories.isNotEmpty && !_manualCategoryFallback)
                _categoryChips()
              else
                _field(
                  label: 'Category IDs',
                  controller: _categoryIdManual,
                  hint: 'Comma-separated UUIDs from your API',
                  isRequired: true,
                ),
              const SizedBox(height: 12),
              _field(
                label: 'Title *',
                controller: _title,
                isRequired: true,
              ),
              const SizedBox(height: 12),
              _field(
                label: 'Description',
                controller: _description,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              _field(
                label: 'Location *',
                controller: _location,
                isRequired: true,
              ),
              const SizedBox(height: 12),
              _field(
                label: 'Postal code *',
                controller: _postalCode,
                hint: 'e.g. 238858',
                isRequired: true,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _field(
                      label: 'Latitude (optional)',
                      controller: _latitude,
                      keyboard: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      label: 'Longitude (optional)',
                      controller: _longitude,
                      keyboard: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _dateRow(
                label: 'Starts *',
                value: _start,
                onTap: _pickStart,
              ),
              const SizedBox(height: 8),
              _dateRow(
                label: _isEdit ? 'Ends (optional)' : 'Ends *',
                value: _end,
                onTap: _pickEnd,
                clearable: _isEdit,
                onClear: _isEdit ? () => setState(() => _end = null) : null,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 4),
                child: Text(
                  'Start and end times are in Singapore (SGT).',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
              const SizedBox(height: 8),
              _field(
                label: 'Capacity *',
                controller: _capacity,
                keyboard: TextInputType.number,
                isRequired: true,
              ),
              const SizedBox(height: 20),
              _mediaSection(),
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
                      : Text(_isEdit ? 'Save changes' : 'Create event'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.brown.shade900,
      ),
    );
  }

  Widget _categoryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((c) {
        final selected = _selectedCategoryIds.contains(c.id);
        return GestureDetector(
          onTap: () => setState(() {
            if (selected) {
              _selectedCategoryIds.remove(c.id);
            } else {
              _selectedCategoryIds.add(c.id);
            }
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFFFE0C2) : const Color(0xFFF7EEDC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? const Color(0xFFFF6B35) : Colors.transparent,
              ),
            ),
            child: Text(
              c.name.isNotEmpty ? c.name : c.id,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.brown.shade800,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _mediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Event media (optional)'),
        const SizedBox(height: 4),
        Text(
          'Upload images or videos. Tap an image to view full size. Use ✕ on a thumbnail to remove it before saving.',
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 120),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFB8D4E8)),
          ),
          child: _mediaItems.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_outlined, size: 40, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No files yet. Use the button below to add images or videos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                )
              : SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _mediaItems.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final m = _mediaItems[index];
                      final url = m.resolvedUrl;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          GestureDetector(
                            onTap: () => _previewMedia(m),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: m.isVideo
                                  ? Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.black12,
                                      child: const Icon(
                                        Icons.videocam,
                                        size: 40,
                                        color: Color(0xFFFF6B35),
                                      ),
                                    )
                                  : Image.network(
                                      url,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 100,
                                        height: 100,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.broken_image),
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Material(
                              color: Colors.white,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => _removeMediaAt(index),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.close, size: 18),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: (_uploadingMedia || _saving) ? null : _pickAndUploadMedia,
          icon: Icon(
            Icons.upload_file,
            color: _uploadingMedia ? Colors.grey : const Color(0xFFFF6B35),
          ),
          label: Text(
            _uploadingMedia ? 'Uploading…' : 'Upload image / video',
            style: TextStyle(
              color: _uploadingMedia ? Colors.grey : const Color(0xFFFF6B35),
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: _uploadingMedia ? Colors.grey : const Color(0xFFFF6B35),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
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
        : 'Not set — tap to choose';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: _inputDecoration(label),
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        color: value != null ? Colors.black87 : Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
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
