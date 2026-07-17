import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../application/profile_controller.dart';
import '../domain/parent_guardian_entry.dart';

/// Student's Profile — Pathway form 1. Single screen, single Save button
/// (per the flow spec's "[Edit Fields] → [Submit]" — no per-section
/// saves, no autosave; see profile_controller.dart's doc comment on why
/// the site's own "saves automatically" copy isn't reproduced here). All
/// fields optional.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

/// One Parent/Guardian block's live-edited text, paired with the
/// controllers that hold it. Kept as its own small class rather than 5
/// parallel `List<TextEditingController>`s so add/remove/dispose all
/// operate on one list of these instead of five lists that have to stay
/// in lockstep by index.
class _ParentControllers {
  _ParentControllers({ParentGuardianEntry? from})
      : name = TextEditingController(text: from?.name ?? ''),
        phone = TextEditingController(text: from?.phone ?? ''),
        email = TextEditingController(text: from?.email ?? ''),
        availableTime = TextEditingController(text: from?.availableTime ?? ''),
        address = TextEditingController(text: from?.address ?? '');

  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController email;
  final TextEditingController availableTime;
  final TextEditingController address;

  ParentGuardianEntry toEntry() => ParentGuardianEntry(
        name: name.text,
        phone: phone.text,
        email: email.text,
        availableTime: availableTime.text,
        address: address.text,
      );

  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    availableTime.dispose();
    address.dispose();
  }
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _dobController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _siblingsController;
  late final TextEditingController _allergiesController;
  late final TextEditingController _regularMedicineController;
  late final TextEditingController _hospitalController;
  late final TextEditingController _transportationController;
  late final TextEditingController _emergencyContactController;

  late List<_ParentControllers> _parentBlocks;

  @override
  void initState() {
    super.initState();
    // Seeded once from whatever's already persisted. The controller's
    // `build()` already loaded it synchronously (Hive is local/sync), so
    // there's no async gap/loading state to handle here — matches the
    // flow spec's "Has Any Data? → Pre-filled Form / Blank Form" diamond.
    final profile = ref.read(profileControllerProvider).profile;
    _dobController = TextEditingController(text: _formatDate(profile.dateOfBirth));
    _phoneController = TextEditingController(text: profile.phoneNumber ?? '');
    _addressController = TextEditingController(text: profile.address ?? '');
    _siblingsController = TextEditingController(text: profile.siblings ?? '');
    _allergiesController = TextEditingController(text: profile.allergies ?? '');
    _regularMedicineController =
        TextEditingController(text: profile.regularMedicine ?? '');
    _hospitalController = TextEditingController(text: profile.hospital ?? '');
    _transportationController =
        TextEditingController(text: profile.transportation ?? '');
    _emergencyContactController =
        TextEditingController(text: profile.emergencyContact ?? '');

    _parentBlocks = profile.parents
        .map((p) => _ParentControllers(from: p))
        .toList(growable: true);
  }

  @override
  void dispose() {
    _dobController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _siblingsController.dispose();
    _allergiesController.dispose();
    _regularMedicineController.dispose();
    _hospitalController.dispose();
    _transportationController.dispose();
    _emergencyContactController.dispose();
    for (final block in _parentBlocks) {
      block.dispose();
    }
    super.dispose();
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  Future<void> _pickDate() async {
    final initial = parseDateOfBirth(_dobController.text) ?? DateTime(2008, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dobController.text = _formatDate(picked));
    }
  }

  void _addParentBlock() {
    setState(() => _parentBlocks.add(_ParentControllers()));
  }

  void _removeParentBlock(int index) {
    setState(() {
      _parentBlocks[index].dispose();
      _parentBlocks.removeAt(index);
    });
  }

  Future<void> _handleSave() async {
    await ref.read(profileControllerProvider.notifier).save(
          rawDateOfBirth: _dobController.text,
          phoneNumber: _phoneController.text,
          address: _addressController.text,
          parents: _parentBlocks.map((b) => b.toEntry()).toList(),
          siblings: _siblingsController.text,
          allergies: _allergiesController.text,
          regularMedicine: _regularMedicineController.text,
          hospital: _hospitalController.text,
          transportation: _transportationController.text,
          emergencyContact: _emergencyContactController.text,
        );

    if (!mounted) return;
    if (ref.read(profileControllerProvider).justSaved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    final studentName = ref.watch(authControllerProvider).session?.name ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text("Student's Profile")),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Text('🪪', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Text(
                  "Student's Profile",
                  style: AppFonts.display(fontSize: 20, color: AppColors.ink),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Your personal, family & medical details. This is shared with '
              'your Academic Advisor & Coordinator so the school can '
              'support and reach you.',
              style: AppFonts.body(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 20),

            const _SectionHeader('General information'),
            const SizedBox(height: 8),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Name'),
              child: Text(
                studentName,
                style: AppFonts.body(color: AppColors.muted),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('profile_dob_field'),
              controller: _dobController,
              keyboardType: TextInputType.datetime,
              decoration: InputDecoration(
                labelText: 'Date of birth (DD/MM/YYYY)',
                helperText: 'Optional',
                errorText: state.dateOfBirthWarning,
                errorMaxLines: 3,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today_outlined),
                  tooltip: 'Pick from calendar',
                  onPressed: _pickDate,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: 'Your phone / WhatsApp',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                hintText: 'Where you live',
              ),
            ),
            const SizedBox(height: 24),

            const _SectionHeader('Parent / guardian'),
            const SizedBox(height: 8),
            for (var i = 0; i < _parentBlocks.length; i++) ...[
              _ParentBlockCard(
                key: Key('parent_block_$i'),
                index: i,
                controllers: _parentBlocks[i],
                canRemove: _parentBlocks.length > 1,
                onRemove: () => _removeParentBlock(i),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton(
              key: const Key('add_parent_button'),
              onPressed: _addParentBlock,
              child: const Text('+ Add another parent / guardian'),
            ),
            const SizedBox(height: 24),

            const _SectionHeader('Siblings'),
            const SizedBox(height: 8),
            TextField(
              controller: _siblingsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Siblings',
                hintText: 'e.g. 1 older sister (at university), 1 younger '
                    'brother (Grade 4)',
              ),
            ),
            const SizedBox(height: 24),

            const _SectionHeader('Medical information'),
            const SizedBox(height: 8),
            TextField(
              controller: _allergiesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Allergies',
                hintText: "Food, medicine, environmental… or 'none'",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _regularMedicineController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Regular medicine',
                hintText: "Any medicine you take regularly… or 'none'",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hospitalController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Hospital history',
                hintText: "Past hospitalisations, conditions the school "
                    "should know… or 'none'",
              ),
            ),
            const SizedBox(height: 24),

            const _SectionHeader('Transportation'),
            const SizedBox(height: 8),
            TextField(
              controller: _transportationController,
              decoration: const InputDecoration(
                labelText: 'How you get to & from school',
                hintText: 'e.g. online ride service · ride a bike · '
                    'drop-off & pick-up by parents',
              ),
            ),
            const SizedBox(height: 24),

            const _SectionHeader('Emergency contact'),
            const SizedBox(height: 8),
            TextField(
              controller: _emergencyContactController,
              decoration: const InputDecoration(
                labelText: 'Who to contact in an emergency',
                hintText: 'Name · relationship · phone number',
              ),
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    key: const Key('profile_save_button'),
                    onPressed: state.isSaving ? null : _handleSave,
                    child: state.isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go(AppRoutes.studentHome),
                    child: const Text('← Back to home'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ParentBlockCard extends StatelessWidget {
  const _ParentBlockCard({
    super.key,
    required this.index,
    required this.controllers,
    required this.canRemove,
    required this.onRemove,
  });

  final int index;
  final _ParentControllers controllers;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Parent / Guardian ${index + 1}',
                  style: AppFonts.body(
                    weight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (canRemove)
                IconButton(
                  key: Key('parent_delete_$index'),
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Remove',
                  onPressed: onRemove,
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controllers.name,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Full name',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controllers.phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone',
              hintText: 'Phone number',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controllers.email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Email',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controllers.availableTime,
            decoration: const InputDecoration(
              labelText: 'Available time',
              hintText: 'e.g. weekdays after 5pm',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controllers.address,
            decoration: const InputDecoration(
              labelText: 'Address',
              hintText: 'Home address',
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppFonts.display(fontSize: 16, color: AppColors.ink),
    );
  }
}