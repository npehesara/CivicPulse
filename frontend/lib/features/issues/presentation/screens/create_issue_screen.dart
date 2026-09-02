import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/models/category_model.dart';
import '../../data/models/department_model.dart';
import '../../data/models/territory_model.dart';
import '../../data/repositories/issue_repository.dart';
import '../controllers/issue_controller.dart';

class CreateIssueScreen extends StatefulWidget {
  const CreateIssueScreen({super.key});

  @override
  State<CreateIssueScreen> createState() => _CreateIssueScreenState();
}

class _CreateIssueScreenState extends State<CreateIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _imageUrlController = TextEditingController();

  List<CategoryModel> _categories = [];
  List<TerritoryModel> _territories = [];
  List<DepartmentModel> _departments = [];

  CategoryModel? _selectedCategory;
  TerritoryModel? _selectedTerritory;
  DepartmentModel? _selectedDepartment;
  String _selectedSeverity = 'MEDIUM';
  String _selectedVisibility = 'PUBLIC';
  bool _isTransitReport = false;

  bool _isLoadingMetadata = true;
  bool _isSubmitting = false;
  bool _isGettingLocation = false;

  XFile? _selectedImageFile;
  String? _selectedImageBase64;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadMetadata() async {
    final repo = context.read<IssueRepository>();
    try {
      final cats = await repo.getCategories();
      final terrs = await repo.getTerritories();
      final depts = await repo.getDepartments();

      setState(() {
        _categories = cats;
        _territories = terrs;
        _departments = depts;
        if (cats.isNotEmpty) _selectedCategory = cats.first;
        if (terrs.isNotEmpty) _selectedTerritory = terrs.first;
        _isLoadingMetadata = false;
      });
    } catch (_) {
      setState(() => _isLoadingMetadata = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled on device.')),
          );
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission was denied. You can enter coordinates manually.')),
            );
          }
          setState(() => _isGettingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is permanently denied.')),
          );
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      _latController.text = position.latitude.toStringAsFixed(6);
      _lngController.text = position.longitude.toStringAsFixed(6);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location detected successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get GPS location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 80);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _selectedImageFile = picked;
          _selectedImageBase64 = base64String;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _submitIssue() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = context.read<IssueRepository>();

      final double? lat = double.tryParse(_latController.text.trim());
      final double? lng = double.tryParse(_lngController.text.trim());

      final body = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'categoryId': _selectedCategory!.categoryId,
        'severity': _selectedSeverity,
        'visibility': _selectedVisibility,
        'isTransitReport': _isTransitReport,
        if (_selectedTerritory != null) 'territoryId': _selectedTerritory!.territoryId,
        if (_selectedDepartment != null) 'departmentId': _selectedDepartment!.departmentId,
        if (lat != null) 'latitude': lat,
        if (lng != null) 'longitude': lng,
      };

      final created = await repo.createIssue(body);

      // Attach image if provided
      if (_selectedImageBase64 != null) {
        try {
          await repo.addImageToIssue(
            created.issueId,
            _selectedImageBase64!,
            filename: _selectedImageFile?.name,
          );
        } catch (_) {}
      } else if (_imageUrlController.text.trim().isNotEmpty) {
        try {
          await repo.addImageToIssue(
            created.issueId,
            _imageUrlController.text.trim(),
          );
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Issue reported successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.read<IssueController>().loadFeed(isRefresh: true);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reporting issue: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
          'Report Civic Issue',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoadingMetadata
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: _titleController,
                      label: 'Title *',
                      hint: 'e.g. Broken water pipe near bus stand',
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Title is required';
                        if (val.trim().length < 5) return 'Title must be at least 5 characters';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Description
                    const Text('Description *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Describe the issue clearly with relevant details...',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.borderFocused, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Description is required';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Category Dropdown
                    const Text('Category *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<CategoryModel>(
                      value: _selectedCategory,
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                      items: _categories.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c.categoryName));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val),
                    ),

                    const SizedBox(height: 16),

                    // Territory Dropdown
                    const Text('Territory / Region', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
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
                      items: _territories.map((t) {
                        return DropdownMenuItem(value: t, child: Text(t.territoryName));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedTerritory = val),
                    ),

                    const SizedBox(height: 16),

                    // Severity & Visibility in two columns
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Severity', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _selectedSeverity,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.surfaceVariant,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'LOW', child: Text('Low')),
                                  DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                                  DropdownMenuItem(value: 'HIGH', child: Text('High')),
                                  DropdownMenuItem(value: 'CRITICAL', child: Text('Critical')),
                                ],
                                onChanged: (val) => setState(() => _selectedSeverity = val ?? 'MEDIUM'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Visibility', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _selectedVisibility,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.surfaceVariant,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'PUBLIC', child: Text('Public Feed')),
                                  DropdownMenuItem(value: 'PRIVATE', child: Text('Private Report')),
                                ],
                                onChanged: (val) => setState(() => _selectedVisibility = val ?? 'PUBLIC'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Transit Report Toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Transit Issue Report', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      subtitle: const Text('Enable if this relates to public bus, railway, or transit services', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      value: _isTransitReport,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _isTransitReport = val),
                    ),

                    const Divider(color: AppColors.divider, height: 28),

                    // Location Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Geo-Location Coordinates', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                        TextButton.icon(
                          onPressed: _isGettingLocation ? null : _getCurrentLocation,
                          icon: _isGettingLocation
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                              : const Icon(Icons.my_location, size: 16, color: AppColors.primary),
                          label: const Text('Use GPS', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _latController,
                            label: 'Latitude',
                            hint: 'e.g. 6.9271',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _lngController,
                            label: 'Longitude',
                            hint: 'e.g. 79.8612',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),

                    const Divider(color: AppColors.divider, height: 28),

                    // Photo Attachment
                    const Text('Attach Image / Photo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                    const SizedBox(height: 10),

                    if (_selectedImageBase64 != null) ...[
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              base64Decode(_selectedImageBase64!.split(',').last),
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              radius: 16,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                onPressed: () => setState(() {
                                  _selectedImageFile = null;
                                  _selectedImageBase64 = null;
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_outlined, color: AppColors.textSecondary, size: 20),
                            label: const Text('Camera', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined, color: AppColors.textSecondary, size: 20),
                            label: const Text('Gallery', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: _imageUrlController,
                      label: 'Image URL',
                      hint: 'Or paste image URL directly...',
                    ),

                    const SizedBox(height: 32),

                    // Submit Button
                    CustomButton(
                      text: 'Submit Issue Report',
                      isLoading: _isSubmitting,
                      onPressed: _submitIssue,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
