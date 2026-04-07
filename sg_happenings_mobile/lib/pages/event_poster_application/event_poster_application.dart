import 'package:flutter/material.dart';

import '../../api/app_api.dart';
import '../../api/event_poster_application_create_payload.dart';
import '../../api/event_poster_repository.dart';

class EventPosterApplicationPage extends StatefulWidget {
  const EventPosterApplicationPage({super.key});

  @override
  State<EventPosterApplicationPage> createState() => _EventPosterApplicationPageState();
}

class _EventPosterApplicationPageState extends State<EventPosterApplicationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _orgController = TextEditingController();
  final TextEditingController _portfolioController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _agreed = false;
  bool _submitting = false;
  bool _roleChecked = false;
  bool _blockedByRole = false;

  @override
  void initState() {
    super.initState();
    _guardAgainstPosterOrAdmin();
  }

  Future<void> _guardAgainstPosterOrAdmin() async {
    try {
      final me = await usersRepository.getMe();
      final blocked = me.isEventPoster || me.isAdmin;
      if (!mounted) return;
      if (blocked) {
        setState(() {
          _roleChecked = true;
          _blockedByRole = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You already have access as an event poster/admin.')),
          );
          Navigator.of(context).maybePop();
        });
        return;
      }
      setState(() => _roleChecked = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _roleChecked = true);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _orgController.dispose();
    _portfolioController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_roleChecked) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F3F0),
        body: SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_blockedByRole) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F3F0),
        body: SafeArea(child: SizedBox.shrink()),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Apply to be an\nEvent Poster',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.brown.shade900,
                  ),
                ),

                const SizedBox(height: 20),

                _field('Full name', _fullNameController, TextInputType.name),
                const SizedBox(height: 12),
                _field('Email', _emailController, TextInputType.emailAddress),
                const SizedBox(height: 12),
                _field('Phone', _phoneController, TextInputType.phone),
                const SizedBox(height: 12),
                _field('Organization', _orgController, TextInputType.text),
                const SizedBox(height: 12),
                _field('Portfolio/Website', _portfolioController, TextInputType.url),
                const SizedBox(height: 12),
                _descriptionField(),

                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _agreed,
                      activeColor: const Color(0xFFFF6B35),
                      onChanged: (v) => setState(() => _agreed = v ?? false),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'I agree to the terms and conditions',
                        style: TextStyle(fontSize: 14, color: Color(0xFF514B45)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _outlineAction(
                        label: 'Cancel',
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _primaryAction(
                        label: 'Submit',
                        onTap: _submitting ? null : _submit,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String hint, TextEditingController controller, TextInputType type) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF7A6F66)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _descriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: _descriptionController,
        keyboardType: TextInputType.multiline,
        minLines: 4,
        maxLines: 6,
        decoration: const InputDecoration(
          hintText: 'Description',
          hintStyle: TextStyle(color: Color(0xFF7A6F66)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _outlineAction({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD8D2C6)),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF514B45),
            ),
          ),
        ),
      ),
    );
  }

  Widget _primaryAction({required String label, required VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: onTap == null
              ? const Color(0xFFFF6B35).withValues(alpha: 0.55)
              : const Color(0xFFFF6B35),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the terms and conditions.'),
          backgroundColor: Color(0xFFFF6B35),
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() => _submitting = true);
    try {
      final payload = EventPosterApplicationCreatePayload(
        organization: _orgController.text.trim().isEmpty ? null : _orgController.text.trim(),
        website: _portfolioController.text.trim().isEmpty ? null : _portfolioController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      );
      await eventPosterRepository.createEventPosterApplication(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted!'),
          backgroundColor: Color(0xFFFF6B35),
        ),
      );
      Navigator.of(context).pop(true);
    } on PosterApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not submit application.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}


