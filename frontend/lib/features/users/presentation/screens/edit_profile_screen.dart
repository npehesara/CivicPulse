import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';
import '../../../issues/data/models/default_territories.dart';
import '../../../issues/data/models/territory_model.dart';
import '../../../issues/data/repositories/issue_repository.dart';
import '../../../issues/data/services/nominatim_service.dart';
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

  // Profile Photo State
  Uint8List? _pendingImageBytes;
  String? _pendingImagePath;
  String? _pendingImageFilename;
  bool _removePhotoRequested = false;

  // Home Location & Map State
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final NominatimService _nominatimService = NominatimService();
  Timer? _debounceTimer;

  List<TerritoryModel> _territories = [];
  List<NominatimPlace> _searchResults = [];
  TerritoryModel? _selectedTerritory;
  late LatLng _selectedLocation;
  late LatLng _mapCenterLocation;
  bool _hasSelectedHomeLocation = false;
  bool _isPickingOnMap = false;
  String? _selectedAddressTitle;
  Offset? _mapTapDownPosition;

  bool _isLoadingTerritories = true;
  bool _isLocating = false;
  bool _isSearching = false;
  bool _isSearchLoading = false;
  bool _hasSearchError = false;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.profile.fullName);
    _phoneController = TextEditingController(text: widget.profile.phoneNumber ?? '');

    // Initialize Home Location from current profile if present, else default to Colombo
    if (widget.profile.homeLatitude != null && widget.profile.homeLongitude != null) {
      _selectedLocation = LatLng(widget.profile.homeLatitude!, widget.profile.homeLongitude!);
      _hasSelectedHomeLocation = true;
    } else {
      _selectedLocation = const LatLng(6.9271, 79.8612); // Colombo default
      _hasSelectedHomeLocation = false;
    }
    _mapCenterLocation = _selectedLocation;

    _loadTerritories();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTerritories() async {
    setState(() => _isLoadingTerritories = true);
    final fallbackList = kSriLankanDistricts.map((d) => d.toModel()).toList();
    try {
      final terrs = await context.read<IssueRepository>().getTerritories();
      if (!mounted) return;
      setState(() {
        _territories = terrs.isNotEmpty ? terrs : fallbackList;

        final currentTerrId = widget.profile.territoryId ?? widget.profile.registeredTerritoryId;
        if (currentTerrId != null) {
          _selectedTerritory = _territories.cast<TerritoryModel?>().firstWhere(
                (t) => t?.territoryId == currentTerrId,
                orElse: () => null,
              );
        }

        if (_selectedTerritory == null && _hasSelectedHomeLocation) {
          _selectedTerritory = findDistrictForCoordinates(_selectedLocation, _territories);
        }

        _isLoadingTerritories = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _territories = fallbackList;
          if (_hasSelectedHomeLocation) {
            _selectedTerritory = findDistrictForCoordinates(_selectedLocation, _territories);
          }
          _isLoadingTerritories = false;
        });
      }
    }
  }

  // ==================== PHOTO MANAGEMENT ====================

  Future<void> _showPhotoOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Profile Picture',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.photo_camera, color: AppColors.primary),
                  ),
                  title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.photo_library, color: AppColors.primary),
                  ),
                  title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if ((widget.profile.profileImage != null && widget.profile.profileImage!.isNotEmpty && !_removePhotoRequested) ||
                    _pendingImageBytes != null) ...[
                  const Divider(),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.errorBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline, color: AppColors.error),
                    ),
                    title: const Text('Remove Photo', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      setState(() {
                        _pendingImageBytes = null;
                        _pendingImagePath = null;
                        _pendingImageFilename = null;
                        _removePhotoRequested = true;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source);
      if (picked == null) return;

      // Process and compress image safely below 3 MB target
      final processed = await ImageUtils.processProfileImage(picked);

      setState(() {
        _pendingImageBytes = processed.bytes;
        _pendingImagePath = picked.path;
        _pendingImageFilename = processed.filename;
        _removePhotoRequested = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ==================== LOCATION & MAP UX ====================

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable GPS / location services on your device.')),
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is required to detect your location.')),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      final latLng = LatLng(pos.latitude, pos.longitude);
      final matchedTerritory = findDistrictForCoordinates(latLng, _territories);

      if (mounted) {
        setState(() {
          _selectedLocation = latLng;
          _mapCenterLocation = latLng;
          _selectedTerritory = matchedTerritory;
          _hasSelectedHomeLocation = true;
          _isPickingOnMap = false;
          _selectedAddressTitle = null;
        });
        try {
          _mapController.move(latLng, 14.5);
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access current GPS location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _isSearchLoading = false;
        _hasSearchError = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isSearchLoading = trimmed.length >= 2;
      _hasSearchError = false;
    });

    if (trimmed.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearchLoading = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      _performNominatimSearch(trimmed);
    });
  }

  Future<void> _performNominatimSearch(String query) async {
    if (!mounted) return;
    setState(() {
      _isSearchLoading = true;
      _hasSearchError = false;
    });

    try {
      final results = await _nominatimService.search(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearchLoading = false;
          _hasSearchError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearchLoading = false;
          _hasSearchError = true;
        });
      }
    }
  }

  void _selectNominatimPlace(NominatimPlace place) {
    final latLng = place.location;
    final matched = findDistrictForCoordinates(
      latLng,
      _territories,
      hintDistrictName: place.resolvedDistrict ?? place.district,
    );

    setState(() {
      _selectedLocation = latLng;
      _mapCenterLocation = latLng;
      _selectedTerritory = matched;
      _selectedAddressTitle = place.title;
      _hasSelectedHomeLocation = true;
      _isSearching = false;
      _isPickingOnMap = false;
      _searchResults = [];
      _isSearchLoading = false;
      _hasSearchError = false;
      _searchController.text = place.title;
    });

    try {
      _mapController.move(latLng, 14.5);
    } catch (_) {}
  }

  void _confirmMapLocation(LatLng center) {
    final matched = findDistrictForCoordinates(center, _territories);
    setState(() {
      _selectedLocation = center;
      _selectedTerritory = matched;
      _hasSelectedHomeLocation = true;
      _isPickingOnMap = false;
      _selectedAddressTitle = null;
    });

    try {
      _mapController.move(center, _mapController.camera.zoom);
    } catch (_) {}
  }

  // ==================== CHANGE PASSWORD DIALOG ====================

  void _showChangePasswordModal() {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final passFormKey = GlobalKey<FormState>();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSubmitting = false;
    String? passError;

    final messenger = ScaffoldMessenger.of(context);
    final profileCtrl = context.read<ProfileController>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: passFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Change Password',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textMuted),
                            onPressed: () => Navigator.of(modalContext).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (passError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.errorBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.error),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, size: 18, color: AppColors.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(passError!, style: const TextStyle(fontSize: 13, color: AppColors.error)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      CustomTextField(
                        controller: currentPassCtrl,
                        label: 'Current Password',
                        obscureText: obscureCurrent,
                        suffixIcon: IconButton(
                          icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility, color: AppColors.textMuted),
                          onPressed: () => setModalState(() => obscureCurrent = !obscureCurrent),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Current password is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: newPassCtrl,
                        label: 'New Password (min 8 characters)',
                        obscureText: obscureNew,
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, color: AppColors.textMuted),
                          onPressed: () => setModalState(() => obscureNew = !obscureNew),
                        ),
                        validator: (val) {
                          if (val == null || val.length < 8) return 'Must be at least 8 characters';
                          if (val == currentPassCtrl.text) return 'New password must be different';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: confirmPassCtrl,
                        label: 'Confirm New Password',
                        obscureText: obscureConfirm,
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, color: AppColors.textMuted),
                          onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                        ),
                        validator: (val) {
                          if (val != newPassCtrl.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Update Password',
                        isLoading: isSubmitting,
                        onPressed: () async {
                          if (!passFormKey.currentState!.validate()) return;
                          setModalState(() {
                            isSubmitting = true;
                            passError = null;
                          });

                          final success = await profileCtrl.changePassword(
                                currentPassword: currentPassCtrl.text,
                                newPassword: newPassCtrl.text,
                                confirmPassword: confirmPassCtrl.text,
                              );

                          if (!modalContext.mounted) return;

                          if (success) {
                            Navigator.of(modalContext).pop();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Password changed successfully!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          } else {
                            final err = profileCtrl.errorMessage;
                            setModalState(() {
                              isSubmitting = false;
                              passError = err ?? 'Failed to update password. Check current password.';
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== SAVE PROFILE ====================

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final profileController = context.read<ProfileController>();
      final authController = context.read<AuthController>();

      // 1. Photo management
      if (_pendingImageBytes != null && _pendingImageFilename != null) {
        final imgOk = await profileController.uploadProfileImage(
          bytes: _pendingImageBytes,
          filePath: _pendingImagePath,
          filename: _pendingImageFilename!,
        );
        if (!imgOk) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(profileController.errorMessage ?? 'Failed to upload profile photo.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }
      } else if (_removePhotoRequested) {
        final removeOk = await profileController.deleteProfileImage();
        if (!removeOk) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(profileController.errorMessage ?? 'Failed to remove profile photo.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }
      }

      // 2. Text & Location updates
      final success = await profileController.updateProfile(
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        registeredTerritoryId: _selectedTerritory?.territoryId,
        territoryId: _selectedTerritory?.territoryId,
        homeLatitude: _hasSelectedHomeLocation ? _selectedLocation.latitude : null,
        homeLongitude: _hasSelectedHomeLocation ? _selectedLocation.longitude : null,
      );

      if (mounted) {
        if (success) {
          final updated = profileController.profile;
          if (updated != null) {
            authController.syncUserProfile(updated);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(profileController.errorMessage ?? 'Failed to update profile.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ==================== BUILD UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Profile Photo Card
              _buildSectionCard(
                title: 'Profile Photo',
                icon: Icons.camera_alt_outlined,
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          _buildAvatarPreview(),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _showPhotoOptions,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.edit, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _showPhotoOptions,
                          icon: const Icon(Icons.photo_camera_outlined, size: 16, color: AppColors.primary),
                          label: const Text('Change Photo', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        if ((widget.profile.profileImage != null && widget.profile.profileImage!.isNotEmpty && !_removePhotoRequested) ||
                            _pendingImageBytes != null) ...[
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _pendingImageBytes = null;
                                _pendingImagePath = null;
                                _pendingImageFilename = null;
                                _removePhotoRequested = true;
                              });
                            },
                            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                            label: const Text('Remove', style: TextStyle(color: AppColors.error, fontSize: 13)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Personal Information Card
              _buildSectionCard(
                title: 'Personal Information',
                icon: Icons.person_outline,
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _fullNameController,
                      label: 'Full Name *',
                      hint: 'Enter your full name',
                      prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.textMuted),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Full name is required';
                        if (val.trim().length > 100) return 'Max 100 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hint: 'e.g. 0771234567',
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textMuted),
                      validator: (val) {
                        if (val != null && val.trim().isNotEmpty) {
                          final cleaned = val.trim().replaceAll(RegExp(r'[\s-]'), '');
                          if (!RegExp(r'^(?:\+94|0)?[0-9]{9,10}$').hasMatch(cleaned)) {
                            return 'Enter a valid phone number (e.g. 0771234567)';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Account Information Card (Read-Only Email)
              _buildSectionCard(
                title: 'Account Information',
                icon: Icons.lock_outline,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      initialValue: widget.profile.email,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMuted),
                        suffixIcon: const Icon(Icons.lock, size: 16, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: const [
                        Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Account login email cannot be changed.',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 4. Home Location Card (Interactive Map + GPS + Nominatim Search + Auto-District)
              _buildSectionCard(
                title: 'Home Location',
                icon: Icons.location_on_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Set your default home coordinates. District is automatically detected from your location.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),

                    // Location Search Bar
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search city, town, or address in Sri Lanka...',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),

                    // Search Results List
                    if (_isSearching) ...[
                      const SizedBox(height: 6),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: _isSearchLoading
                            ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                  ),
                                ),
                              )
                            : _hasSearchError
                                ? const Padding(
                                    padding: EdgeInsets.all(14.0),
                                    child: Center(
                                      child: Text(
                                        'Failed to load search results. Please check network.',
                                        style: TextStyle(fontSize: 13, color: AppColors.error),
                                      ),
                                    ),
                                  )
                                : _searchResults.isEmpty
                                    ? const Padding(
                                        padding: EdgeInsets.all(14.0),
                                        child: Center(
                                          child: Text(
                                            'No locations found in Sri Lanka',
                                            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        shrinkWrap: true,
                                        itemCount: _searchResults.length,
                                        separatorBuilder: (context, index) => const Divider(height: 1),
                                        itemBuilder: (ctx, idx) {
                                          final place = _searchResults[idx];
                                          return ListTile(
                                            dense: true,
                                            leading: const Icon(Icons.location_on, size: 18, color: AppColors.primary),
                                            title: Text(
                                              place.title,
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                            ),
                                            subtitle: Text(
                                              place.subtitle,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                            ),
                                            onTap: () => _selectNominatimPlace(place),
                                          );
                                        },
                                      ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Quick Actions Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isLocating ? null : _useCurrentLocation,
                            icon: _isLocating
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                  )
                                : const Icon(Icons.my_location, size: 16, color: AppColors.primary),
                            label: Text(
                              _isLocating ? 'Locating...' : 'Current Location',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _isPickingOnMap = !_isPickingOnMap;
                              _mapCenterLocation = _selectedLocation;
                            });
                            if (_isPickingOnMap) {
                              try {
                                _mapController.move(_selectedLocation, 14.0);
                              } catch (_) {}
                            }
                          },
                          icon: Icon(
                            _isPickingOnMap ? Icons.close : Icons.touch_app_outlined,
                            size: 16,
                            color: _isPickingOnMap ? AppColors.textSecondary : AppColors.primary,
                          ),
                          label: Text(
                            _isPickingOnMap ? 'Close picker' : 'Move Pin',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _isPickingOnMap ? AppColors.textSecondary : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Interactive Map Container
                    _buildMapContainer(),

                    if (_isPickingOnMap) ...[
                      const SizedBox(height: 10),
                      CustomButton(
                        text: 'Confirm this Location',
                        icon: Icons.check_circle_outline,
                        onPressed: () => _confirmMapLocation(_mapCenterLocation),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Location Status Badge Card
                    _buildLocationStatusCard(),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 5. Security & Password Card
              _buildSectionCard(
                title: 'Security',
                icon: Icons.shield_outlined,
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Password',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Update your account password securely',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _showChangePasswordModal,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Change', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Save Changes Action Button
              CustomButton(
                text: 'Save Changes',
                icon: Icons.save_outlined,
                isLoading: _isSaving,
                onPressed: _saveProfile,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildAvatarPreview() {
    if (_pendingImageBytes != null) {
      return CircleAvatar(
        radius: 46,
        backgroundColor: AppColors.surfaceVariant,
        child: ClipOval(
          child: Image.memory(
            _pendingImageBytes!,
            width: 88,
            height: 88,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    if (!_removePhotoRequested &&
        widget.profile.profileImage != null &&
        widget.profile.profileImage!.trim().isNotEmpty &&
        widget.profile.profileImage!.startsWith('http')) {
      return CircleAvatar(
        radius: 46,
        backgroundColor: AppColors.surfaceVariant,
        child: ClipOval(
          child: Image.network(
            widget.profile.profileImage!.trim(),
            width: 88,
            height: 88,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary));
            },
            errorBuilder: (context, error, stackTrace) => _buildFallbackInitial(),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 46,
      backgroundColor: AppColors.primaryLight,
      child: _buildFallbackInitial(),
    );
  }

  Widget _buildFallbackInitial() {
    final initial = widget.profile.fullName.trim().isNotEmpty
        ? widget.profile.fullName.trim()[0].toUpperCase()
        : 'C';
    return Text(
      initial,
      style: const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildMapContainer() {
    return Container(
      height: _isPickingOnMap ? 260 : 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isPickingOnMap ? AppColors.primary : AppColors.border,
          width: _isPickingOnMap ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: _isLoadingTerritories
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Stack(
              alignment: Alignment.center,
              children: [
                Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (e) => _mapTapDownPosition = e.localPosition,
                  onPointerUp: (e) {
                    final down = _mapTapDownPosition;
                    if (down != null && (e.localPosition - down).distance > 20) return;
                    if (_isPickingOnMap) return;
                    try {
                      final point = _mapController.camera.pointToLatLng(
                        math.Point(e.localPosition.dx, e.localPosition.dy),
                      );
                      _mapCenterLocation = point;
                      _confirmMapLocation(point);
                    } catch (_) {}
                  },
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _selectedLocation,
                      initialZoom: 13.0,
                      onPositionChanged: (camera, hasGesture) {
                        _mapCenterLocation = camera.center;
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.civicpulse.app',
                      ),
                      if (!_isPickingOnMap && _hasSelectedHomeLocation)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedLocation,
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.location_pin, color: AppColors.error, size: 36),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Fixed Center Pin when in picking mode
                if (_isPickingOnMap)
                  IgnorePointer(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 36.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Move map to position pin',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Icon(Icons.location_pin, color: AppColors.primary, size: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildLocationStatusCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, size: 16, color: AppColors.success),
              const SizedBox(width: 6),
              const Text('Detected District:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _selectedTerritory?.territoryName ?? 'Detecting...',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
            ],
          ),
          if (_selectedAddressTitle != null) ...[
            const SizedBox(height: 4),
            Text(
              _selectedAddressTitle!,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
            ),
          ],
          if (_hasSelectedHomeLocation) ...[
            const SizedBox(height: 6),
            Text(
              'Coordinates: ${_selectedLocation.latitude.toStringAsFixed(4)}° N, ${_selectedLocation.longitude.toStringAsFixed(4)}° E',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
