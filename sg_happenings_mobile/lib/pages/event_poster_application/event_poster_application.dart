import 'package:flutter/material.dart';

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

  final List<String> _categories = ['Music', 'Art', 'Food', 'Theatre'];
  final Set<String> _selectedCategories = {'Music', 'Art'}; // preselected per image

  String? _operatingArea;
  bool _agreed = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _orgController.dispose();
    _portfolioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: _categories.map((c) => _chip(c)).toList(),
                ),

                const SizedBox(height: 12),
                _operatingAreasDropdown(),

                const SizedBox(height: 12),
                Row(
                  children: [
                    _lightButton('ID Verification'),
                    const SizedBox(width: 12),
                    Expanded(child: _uploadButton()),
                  ],
                ),

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
                        onTap: _submit,
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
        color: Colors.white.withOpacity(0.65),
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

  Widget _chip(String label) {
    final bool selected = _selectedCategories.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (selected) {
            _selectedCategories.remove(label);
          } else {
            _selectedCategories.add(label);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFE0C2) : const Color(0xFFF7EEDC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.brown.shade700,
          ),
        ),
      ),
    );
  }

  Widget _operatingAreasDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _operatingArea,
          hint: const Text('Operating areas', style: TextStyle(color: Color(0xFF7A6F66))),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF7A6F66)),
          items: const [
            DropdownMenuItem(value: 'Central', child: Text('Central')),
            DropdownMenuItem(value: 'East', child: Text('East')),
            DropdownMenuItem(value: 'West', child: Text('West')),
            DropdownMenuItem(value: 'North', child: Text('North')),
            DropdownMenuItem(value: 'South', child: Text('South')),
          ],
          onChanged: (v) => setState(() => _operatingArea = v),
        ),
      ),
    );
  }

  Widget _lightButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EDE8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF514B45),
        ),
      ),
    );
  }

  Widget _uploadButton() {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload clicked'),
            backgroundColor: Color(0xFFFF6B35),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0EDE8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Upload file',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF514B45),
          ),
        ),
      ),
    );
  }

  Widget _outlineAction({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.4),
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

  Widget _primaryAction({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B35),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Submit',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Application submitted!'),
        backgroundColor: Color(0xFFFF6B35),
      ),
    );
  }
}


