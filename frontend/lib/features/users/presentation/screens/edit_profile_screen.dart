import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../issues/data/models/territory_model.dart';
import '../../../issues/data/repositories/issue_repository.dart';
import '../../data/models/user_profile_model.dart';
import '../controllers/profile_controller.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfileModel profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _imageController;

  List<TerritoryModel> _territories = [];
  TerritoryModel? _selectedTerritory;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.profile.fullName);
    _phoneController = TextEditingController(text: widget.profile.phoneNumber ?? '');
    _imageController = TextEditingController(text: widget.profile.profileImage ?? '');
    _loadTerritories();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _loadTerritories() async {
    setState(() => _isLoading = true);
    try {
      final terrs = await context.read<IssueRepository>().getTerritories();
      setState(() {
        _territories = terrs;
        if (widget.profile.registeredTerritoryId != null) {
          _selectedTerritory = terrs.cast<TerritoryModel?>().firstWhere(
                (t) => t?.territoryId == widget.profile.registeredTerritoryId,
                orElse: () => null,
              );
        }
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final success = await context.read<ProfileController>().updateProfile(
            fullName: _fullNameController.text.trim(),
            phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
            profileImage: _imageController.text.trim().isNotEmpty ? _imageController.text.trim() : null,
            registeredTerritoryId: _selectedTerritory?.territoryId,
          );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: AppColors.success),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update profile.'), backgroundColor: AppColors.error),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: _fullNameController,
                      label: 'Full Name *',
                      hint: 'Your Full Name',
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Full name is required';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hint: 'e.g. 0771234567',
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 16),

                    const Text('Registered Territory / Council', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<TerritoryModel>(
                      value: _selectedTerritory,
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                      hint: const Text('Select your local jurisdiction'),
                      items: _territories.map((t) {
                        return DropdownMenuItem(value: t, child: Text(t.territoryName));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedTerritory = val),
                    ),

                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _imageController,
                      label: 'Profile Image URL',
                      hint: 'https://...',
                    ),

                    const SizedBox(height: 32),

                    CustomButton(
                      text: 'Save Changes',
                      isLoading: _isSaving,
                      onPressed: _saveProfile,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
