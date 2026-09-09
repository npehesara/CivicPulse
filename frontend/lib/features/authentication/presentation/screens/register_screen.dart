import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../../issues/data/models/territory_model.dart';
import '../../../issues/data/repositories/issue_repository.dart';
import '../controllers/auth_controller.dart';
import '../widgets/password_field.dart';

/// Predefined approximate centroid coordinates for known Sri Lankan administrative territories.
const Map<String, LatLng> _knownTerritoryCentroids = {
  'colombo': LatLng(6.9271, 79.8612),
  'dehiwala': LatLng(6.8301, 79.8801),
  'moratuwa': LatLng(6.7730, 79.8816),
  'kotte': LatLng(6.8944, 79.9025),
  'kandy': LatLng(7.2906, 80.6337),
  'galle': LatLng(6.0535, 80.2210),
  'matara': LatLng(5.9549, 80.5550),
  'balapitiya': LatLng(6.2730, 80.0410),
  'hambantota': LatLng(6.1429, 81.1212),
  'jaffna': LatLng(9.6615, 80.0255),
  'kilinochchi': LatLng(9.3803, 80.3770),
  'mannar': LatLng(8.9810, 79.9044),
  'vavuniya': LatLng(8.7542, 80.4982),
  'mullaitivu': LatLng(9.2671, 80.8143),
  'batticaloa': LatLng(7.7310, 81.6747),
  'ampara': LatLng(7.2912, 81.6724),
  'trincomalee': LatLng(8.5874, 81.2152),
  'kurunegala': LatLng(7.4818, 80.3609),
  'puttalam': LatLng(8.0408, 79.8394),
  'anuradhapura': LatLng(8.3114, 80.4037),
  'polonnaruwa': LatLng(7.9403, 81.0188),
  'badulla': LatLng(6.9934, 81.0550),
  'bandarawela': LatLng(6.8259, 80.9982),
  'monaragala': LatLng(6.8728, 81.3507),
  'ratnapura': LatLng(6.6828, 80.4034),
  'kegalle': LatLng(7.2513, 80.3464),
  'kalutara': LatLng(6.5854, 79.9607),
  'negombo': LatLng(7.2008, 79.8736),
  'gampaha': LatLng(7.0840, 79.9939),
  'matale': LatLng(7.4675, 80.6234),
  'nuwara eliya': LatLng(6.9497, 80.7891),
};

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0; // 0 = Step 1, 1 = Step 2, 2 = Step 3, 3 = Step 4, 4 = Step 5

  // Step 1: Personal Details
  final _formKeyStep1 = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Step 2: Location / Territory
  final MapController _mapController = MapController();
  final _searchController = TextEditingController();
  List<TerritoryModel> _territories = [];
  List<TerritoryModel> _filteredTerritories = [];
  TerritoryModel? _selectedTerritory;
  LatLng _selectedLocation = const LatLng(6.9271, 79.8612); // Colombo default
  bool _isLoadingTerritories = true;
  bool _isLocating = false;
  bool _isSearching = false;

  // Step 3: Password
  final _formKeyStep3 = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Step 4: Profile Photo
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadTerritories();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _searchController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadTerritories() async {
    setState(() => _isLoadingTerritories = true);
    try {
      final repo = context.read<IssueRepository>();
      final list = await repo.getTerritories();
      if (mounted) {
        setState(() {
          _territories = list;
          _filteredTerritories = list;
          _isLoadingTerritories = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingTerritories = false);
      }
    }
  }

  void _goToPage(int page) {
    setState(() => _currentStep = page);
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleBack() {
    if (_currentStep > 0 && _currentStep < 4) {
      _goToPage(_currentStep - 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  // --- Step 1 Navigation ---
  void _handleStep1Next() {
    context.read<AuthController>().clearError();
    if (_formKeyStep1.currentState?.validate() ?? false) {
      _goToPage(1);
    }
  }

  // --- Step 2 Location Handling ---
  LatLng _getCoordinatesForTerritory(TerritoryModel territory) {
    final lowerName = territory.territoryName.toLowerCase();
    for (final entry in _knownTerritoryCentroids.entries) {
      if (lowerName.contains(entry.key)) {
        return entry.value;
      }
    }
    // Fallback to default
    return const LatLng(6.9271, 79.8612);
  }

  void _selectTerritory(TerritoryModel territory) {
    final coords = _getCoordinatesForTerritory(territory);
    setState(() {
      _selectedTerritory = territory;
      _selectedLocation = coords;
      _isSearching = false;
      _searchController.text = territory.territoryName;
    });
    try {
      _mapController.move(coords, 13.0);
    } catch (_) {}
  }

  void _selectMapCoordinate(LatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
    });

    if (_territories.isEmpty) return;

    // Nearest-neighbor matching against known territory centroids
    const distance = Distance();
    TerritoryModel? closestTerritory;
    double minDistance = double.infinity;

    for (final territory in _territories) {
      final centroid = _getCoordinatesForTerritory(territory);
      final dist = distance.as(LengthUnit.Kilometer, latLng, centroid);
      if (dist < minDistance) {
        minDistance = dist;
        closestTerritory = territory;
      }
    }

    if (closestTerritory != null) {
      final matched = closestTerritory;
      setState(() {
        _selectedTerritory = matched;
        _searchController.text = matched.territoryName;
      });
    }
  }

  Future<void> _handleGpsLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        final latLng = LatLng(position.latitude, position.longitude);
        _selectMapCoordinate(latLng);
        try {
          _mapController.move(latLng, 14.0);
        } catch (_) {}
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission was denied.')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not access current GPS location.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredTerritories = _territories;
        _isSearching = false;
      });
    } else {
      final lower = query.trim().toLowerCase();
      setState(() {
        _filteredTerritories = _territories.where((t) {
          return t.territoryName.toLowerCase().contains(lower) ||
              (t.parentTerritoryName?.toLowerCase().contains(lower) ?? false) ||
              (t.regionType?.toLowerCase().contains(lower) ?? false);
        }).toList();
        _isSearching = true;
      });
    }
  }

  void _handleStep2Next() {
    if (_selectedTerritory != null) {
      _goToPage(2);
    }
  }

  // --- Step 3 Navigation ---
  void _handleStep3Next() {
    context.read<AuthController>().clearError();
    if (_formKeyStep3.currentState?.validate() ?? false) {
      _goToPage(3);
    }
  }

  // --- Step 4 Profile Photo Handling ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _selectedImageBytes = bytes;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not select image. Please try again.')),
        );
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
    });
  }

  // --- Final Submission ---
  Future<void> _handleSubmit() async {
    final authController = context.read<AuthController>();
    authController.clearError();

    if (_selectedTerritory == null) {
      _goToPage(1);
      return;
    }

    final success = await authController.register(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      registeredTerritoryId: _selectedTerritory!.territoryId,
      profileImagePath: _selectedImage?.path,
      profileImageBytes: _selectedImageBytes,
      profileImageFilename: _selectedImage?.name,
    );

    if (success && mounted) {
      _goToPage(4); // Move to Step 5 (Completion)
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _currentStep < 4
            ? AppBar(
                backgroundColor: AppColors.background,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
                  onPressed: _handleBack,
                ),
                title: Text(
                  '${_currentStep + 1} of 5',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                centerTitle: true,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(4),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / 5.0,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 3,
                  ),
                ),
              )
            : null,
        body: SafeArea(
          child: Consumer<AuthController>(
            builder: (context, authController, _) {
              return PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1PersonalDetails(authController),
                  _buildStep2LocationSelection(authController),
                  _buildStep3Password(authController),
                  _buildStep4ProfilePhoto(authController),
                  _buildStep5RegistrationComplete(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ==========================================
  // STEP 1: PERSONAL DETAILS
  // ==========================================
  Widget _buildStep1PersonalDetails(AuthController authController) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _formKeyStep1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStepHeader(
                  title: 'Create your account',
                  subtitle: 'Enter your personal details to get started with CivicPulse.',
                ),
                const SizedBox(height: 20),
                ErrorBanner(
                  message: authController.errorMessage,
                  onDismiss: authController.clearError,
                ),
                CustomTextField(
                  controller: _fullNameController,
                  label: AppStrings.fullNameLabel,
                  hint: AppStrings.fullNameHint,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: Validators.validateFullName,
                  errorText: authController.validationErrors?['fullName'],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  label: AppStrings.emailLabel,
                  hint: AppStrings.emailHint,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.validateEmail,
                  errorText: authController.validationErrors?['email'],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _phoneController,
                  label: AppStrings.phoneLabel,
                  hint: AppStrings.phoneHint,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  validator: Validators.validatePhoneNumber,
                  errorText: authController.validationErrors?['phoneNumber'],
                  onFieldSubmitted: (_) => _handleStep1Next(),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Next',
                  onPressed: _handleStep1Next,
                ),
                const SizedBox(height: 24),
                _buildSignInLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // STEP 2: LOCATION / MAP SELECTION
  // ==========================================
  Widget _buildStep2LocationSelection(AuthController authController) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStepHeader(
                title: 'Select your location',
                subtitle: 'Choose your local municipal council or territory to connect with community issues.',
              ),
              const SizedBox(height: 16),

              // Search Box
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search location or council...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),

              // Suggestions Dropdown List if searching
              if (_isSearching && _filteredTerritories.isNotEmpty)
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  elevation: 4,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _filteredTerritories.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.divider),
                      itemBuilder: (context, index) {
                        final t = _filteredTerritories[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_city, color: AppColors.primary, size: 20),
                          title: Text(
                            t.territoryName,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          subtitle: Text(
                            t.parentTerritoryName ?? t.regionType ?? '',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          onTap: () => _selectTerritory(t),
                        );
                      },
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // GPS Button
              OutlinedButton.icon(
                icon: _isLocating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : const Icon(Icons.my_location, size: 18, color: AppColors.primary),
                label: Text(
                  _isLocating ? 'Locating...' : 'Use my current location',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isLocating ? null : _handleGpsLocation,
              ),

              const SizedBox(height: 12),

              // Interactive Map Container
              Container(
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: _isLoadingTerritories
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _selectedLocation,
                          initialZoom: 12.0,
                          onTap: (_, point) => _selectMapCoordinate(point),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.civicpulse.app',
                            errorTileCallback: (tile, error, stackTrace) {},
                            evictErrorTileStrategy: EvictErrorTileStrategy.none,
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _selectedLocation,
                                width: 44,
                                height: 44,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: AppColors.error,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 14),

              // Selected Location Display Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _selectedTerritory != null ? AppColors.primaryLight.withValues(alpha: 0.3) : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedTerritory != null ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedTerritory != null ? Icons.check_circle : Icons.info_outline,
                      color: _selectedTerritory != null ? AppColors.primary : AppColors.textMuted,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedTerritory != null ? 'Selected Location' : 'No Location Selected',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _selectedTerritory != null ? AppColors.primaryDark : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedTerritory != null
                                ? '${_selectedTerritory!.territoryName}${_selectedTerritory!.parentTerritoryName != null ? " · ${_selectedTerritory!.parentTerritoryName}" : ""}'
                                : 'Tap map, use GPS, or search above to select your territory.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _selectedTerritory != null ? FontWeight.w700 : FontWeight.w400,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              CustomButton(
                text: 'Next',
                onPressed: _selectedTerritory != null ? _handleStep2Next : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // STEP 3: PASSWORD
  // ==========================================
  Widget _buildStep3Password(AuthController authController) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _formKeyStep3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStepHeader(
                  title: 'Create a password',
                  subtitle: 'Create a strong password with at least 8 characters, letters, and numbers.',
                ),
                const SizedBox(height: 20),
                ErrorBanner(
                  message: authController.errorMessage,
                  onDismiss: authController.clearError,
                ),
                PasswordField(
                  controller: _passwordController,
                  label: AppStrings.passwordLabel,
                  hint: AppStrings.passwordHint,
                  textInputAction: TextInputAction.next,
                  validator: Validators.validatePassword,
                  errorText: authController.validationErrors?['password'],
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _confirmPasswordController,
                  label: AppStrings.confirmPasswordLabel,
                  hint: AppStrings.confirmPasswordHint,
                  textInputAction: TextInputAction.done,
                  validator: (value) => Validators.validateConfirmPassword(
                    _passwordController.text,
                    value,
                  ),
                  onFieldSubmitted: (_) => _handleStep3Next(),
                ),
                const SizedBox(height: 28),
                CustomButton(
                  text: 'Next',
                  onPressed: _handleStep3Next,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // STEP 4: PROFILE PHOTO (OPTIONAL)
  // ==========================================
  Widget _buildStep4ProfilePhoto(AuthController authController) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStepHeader(
                title: 'Add a profile photo',
                subtitle: 'Help people recognize you. You can skip this for now.',
              ),
              const SizedBox(height: 24),
              ErrorBanner(
                message: authController.errorMessage,
                onDismiss: authController.clearError,
              ),

              // Avatar Circle Preview
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceVariant,
                        border: Border.all(color: AppColors.primary, width: 3),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: ClipOval(
                        child: _selectedImageBytes != null
                            ? Image.memory(
                                _selectedImageBytes!,
                                fit: BoxFit.cover,
                                width: 140,
                                height: 140,
                              )
                            : (!kIsWeb && _selectedImage != null
                                ? Image.file(
                                    File(_selectedImage!.path),
                                    fit: BoxFit.cover,
                                    width: 140,
                                    height: 140,
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.person,
                                      size: 72,
                                      color: AppColors.textMuted,
                                    ),
                                  )),
                      ),
                    ),
                    if (_selectedImage != null)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _removePhoto,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons: Take Photo & Choose Gallery
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text('Take Photo'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: authController.isLoading ? null : () => _pickImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: authController.isLoading ? null : () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Submit / Create Account Button
              CustomButton(
                text: 'Create Account',
                onPressed: _handleSubmit,
                isLoading: authController.isLoading,
              ),

              const SizedBox(height: 16),

              // Skip Button
              if (_selectedImage == null)
                Center(
                  child: TextButton(
                    onPressed: authController.isLoading ? null : _handleSubmit,
                    child: const Text(
                      'Skip for now',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // STEP 5: REGISTRATION COMPLETE
  // ==========================================
  Widget _buildStep5RegistrationComplete() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.successBackground,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.successBorder, width: 3),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 56,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "You're all set! 🎉",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your CivicPulse account has been created successfully. You can now log in to start reporting and tracking civic issues.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),

              // Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(Icons.person_outline, 'Name', _fullNameController.text),
                    const Divider(height: 16, color: AppColors.divider),
                    _buildSummaryRow(Icons.email_outlined, 'Email', _emailController.text),
                    const Divider(height: 16, color: AppColors.divider),
                    _buildSummaryRow(
                      Icons.location_on_outlined,
                      'Territory',
                      _selectedTerritory?.territoryName ?? 'Selected Territory',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              CustomButton(
                text: 'Log in',
                icon: Icons.login_rounded,
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widgets
  Widget _buildStepHeader({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSignInLink() {
    return Center(
      child: Text.rich(
        TextSpan(
          text: AppStrings.hasAccountPrompt,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                onTap: () {
                  context.read<AuthController>().clearError();
                  Navigator.of(context).pop();
                },
                child: const Text(
                  AppStrings.loginLink,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
