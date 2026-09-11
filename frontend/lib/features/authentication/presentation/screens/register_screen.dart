import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../../issues/data/models/default_territories.dart';
import '../../../issues/data/models/territory_model.dart';
import '../../../issues/data/repositories/issue_repository.dart';
import '../../../issues/data/services/nominatim_service.dart';
import '../controllers/auth_controller.dart';
import '../widgets/password_field.dart';

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
  final NominatimService _nominatimService = NominatimService();
  Timer? _debounceTimer;
  List<TerritoryModel> _territories = [];
  List<NominatimPlace> _searchResults = [];
  TerritoryModel? _selectedTerritory;
  LatLng _selectedLocation = const LatLng(6.9271, 79.8612); // Colombo default
  LatLng _mapCenterLocation = const LatLng(6.9271, 79.8612);
  bool _hasSelectedHomeLocation = false;
  bool _isPickingOnMap = false;
  String? _selectedAddressTitle;
  bool _isLoadingTerritories = true;
  bool _isLocating = false;
  bool _isSearching = false;
  bool _isSearchLoading = false;
  bool _hasSearchError = false;
  Offset? _mapTapDownPosition;

  // Step 3: Password
  final _formKeyStep3 = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Step 4: Profile Photo
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _selectedImageFilename;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadTerritories();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
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
          if (list.isNotEmpty) {
            _territories = list;
          } else {
            _territories = kSriLankanDistricts.map((t) => t.toModel()).toList();
          }
          _isLoadingTerritories = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _territories = kSriLankanDistricts.map((t) => t.toModel()).toList();
          _isLoadingTerritories = false;
        });
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
  Future<void> _selectMapCoordinate(LatLng latLng) async {
    debugPrint('[Step2] Manual map tapped: ${latLng.latitude}, ${latLng.longitude}');
    final initialDistrict = findDistrictForCoordinates(latLng, _territories);
    setState(() {
      _selectedLocation = latLng;
      _mapCenterLocation = latLng;
      _selectedTerritory = initialDistrict;
      _hasSelectedHomeLocation = true;
    });

    try {
      _mapController.move(latLng, _mapController.camera.zoom);
    } catch (_) {}

    // Reverse geocode in background to refine district from OSM official boundary
    try {
      final place = await _nominatimService.reverseGeocode(latLng);
      if (place != null && mounted) {
        final refinedDistrict = findDistrictForCoordinates(
          latLng,
          _territories,
          hintDistrictName: place.resolvedDistrict ?? place.district,
        );
        setState(() {
          _selectedTerritory = refinedDistrict;
          _selectedAddressTitle = place.title;
        });
      }
    } catch (e) {
      debugPrint('[Step2] Reverse geocode error: $e');
    }
  }

  Future<void> _confirmMapLocation(LatLng latLng) async {
    debugPrint('[Step2] Confirming map location: ${latLng.latitude}, ${latLng.longitude}');
    final initialDistrict = findDistrictForCoordinates(latLng, _territories);
    setState(() {
      _selectedLocation = latLng;
      _mapCenterLocation = latLng;
      _selectedTerritory = initialDistrict;
      _hasSelectedHomeLocation = true;
      _isPickingOnMap = false;
      _selectedAddressTitle = initialDistrict.territoryName;
    });

    try {
      final place = await _nominatimService.reverseGeocode(latLng);
      if (place != null && mounted) {
        final refinedDistrict = findDistrictForCoordinates(
          latLng,
          _territories,
          hintDistrictName: place.resolvedDistrict ?? place.district,
        );
        setState(() {
          _selectedTerritory = refinedDistrict;
          _selectedAddressTitle = place.title;
        });
      }
    } catch (e) {
      debugPrint('[Step2] Reverse geocode error: $e');
    }
  }

  Future<void> _handleGpsLocation() async {
    debugPrint('[GPS] Initiating GPS location request...');
    setState(() => _isLocating = true);

    try {
      // 1. Check if location services are enabled
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('[GPS] Location services enabled: $isServiceEnabled');
      if (!isServiceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location services are turned off. Please enable GPS on your device.'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => Geolocator.openLocationSettings(),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // 2. Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('[GPS] Initial permission status: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('[GPS] Permission after request: $permission');
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[GPS] Location permission denied forever.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location permission is permanently denied. Please grant permission in App Settings.'),
              action: SnackBarAction(
                label: 'App Settings',
                onPressed: () => Geolocator.openAppSettings(),
              ),
              duration: const Duration(seconds: 6),
            ),
          );
        }
        return;
      }

      if (permission == LocationPermission.denied) {
        debugPrint('[GPS] Location permission denied by user.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission was denied.')),
          );
        }
        return;
      }

      // 3. Permission granted: get position
      debugPrint('[GPS] Permission granted! Acquiring current position...');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      debugPrint('[GPS] Position acquired: ${position.latitude}, ${position.longitude}');
      final latLng = LatLng(position.latitude, position.longitude);

      if (mounted) {
        try {
          _mapController.move(latLng, 14.5);
        } catch (_) {}
        await _selectMapCoordinate(latLng);
      }
    } catch (e) {
      debugPrint('[GPS] Error acquiring GPS position: $e');
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

    // Debounce Nominatim search by 600ms to respect OSM usage policy
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
      debugPrint('[Search] Nominatim search error: $e');
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

    // Resolve district using OSM resolved district or bounding box
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
      _mapController.move(latLng, 13.5);
    } catch (_) {}
  }

  void _handleStep2Next() {
    if (_hasSelectedHomeLocation || _selectedTerritory != null) {
      _selectedTerritory ??= findDistrictForCoordinates(_selectedLocation, _territories);
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
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (image != null) {
        final processed = await ImageUtils.processProfileImage(image);
        setState(() {
          _selectedImage = image;
          _selectedImageBytes = processed.bytes;
          _selectedImageFilename = processed.filename;
        });
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
      _selectedImageFilename = null;
    });
  }

  // --- Final Submission ---
  Future<void> _handleSubmit() async {
    final authController = context.read<AuthController>();
    authController.clearError();

    _selectedTerritory ??= findDistrictForCoordinates(_selectedLocation, _territories);

    if (!_hasSelectedHomeLocation && _selectedTerritory == null) {
      _goToPage(1);
      return;
    }

    final success = await authController.register(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      registeredTerritoryId: _selectedTerritory?.territoryId,
      territoryId: _selectedTerritory?.territoryId,
      homeLatitude: _selectedLocation.latitude,
      homeLongitude: _selectedLocation.longitude,
      profileImagePath: _selectedImage?.path,
      profileImageBytes: _selectedImageBytes,
      profileImageFilename: _selectedImageFilename ?? _selectedImage?.name,
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
                title: 'Your Home Location',
                subtitle: 'Select your default home location to automatically connect with your local district and community issues.',
              ),
              const SizedBox(height: 16),

              // 1. PRIMARY ACTION: Use Current Location
              _buildGpsPrimaryAction(),
              const SizedBox(height: 16),

              // 2. EASY OPTION: Search Location
              _buildSearchSection(),
              const SizedBox(height: 16),

              // 3. MANUAL OPTION: Pick on Map
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map_outlined, size: 18, color: AppColors.textPrimary),
                      SizedBox(width: 6),
                      Text(
                        'Pick on Map',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: _isPickingOnMap
                        ? TextButton.icon(
                            icon: const Icon(Icons.close, size: 14, color: AppColors.textSecondary),
                            label: const Text(
                              'Close',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            onPressed: () {
                              setState(() {
                                _isPickingOnMap = false;
                                _mapCenterLocation = _selectedLocation;
                              });
                              if (_hasSelectedHomeLocation) {
                                try {
                                  _mapController.move(_selectedLocation, _mapController.camera.zoom);
                                } catch (_) {}
                              }
                            },
                          )
                        : TextButton.icon(
                            icon: const Icon(Icons.touch_app_outlined, size: 16, color: AppColors.primary),
                            label: const Text(
                              'Move pin',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                            onPressed: () {
                              setState(() {
                                _isPickingOnMap = true;
                                _mapCenterLocation = _selectedLocation;
                              });
                              try {
                                _mapController.move(_selectedLocation, 14.0);
                              } catch (_) {}
                            },
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Interactive Map Container (with Fixed Center Pin when picking on map)
              _buildMapContainer(),

              // "Confirm this Location" Button when in manual map mode
              if (_isPickingOnMap) ...[
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Confirm this Location',
                  icon: Icons.check_circle_outline,
                  onPressed: () => _confirmMapLocation(_mapCenterLocation),
                ),
              ],

              const SizedBox(height: 16),

              // Selected / Confirmed Location Status Card
              _buildLocationStatusCard(),

              const SizedBox(height: 24),

              // Step 2 Next Button
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_hasSelectedHomeLocation && _selectedTerritory == null)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Select your home location above to continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  CustomButton(
                    text: 'Next',
                    onPressed: (_hasSelectedHomeLocation || _selectedTerritory != null) ? _handleStep2Next : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGpsPrimaryAction() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isLocating ? null : _handleGpsLocation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: _isLocating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.my_location, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isLocating ? 'Detecting Location...' : 'Use Current Location',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Use my current location',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Search Location',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search city, town, or address...',
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
        if (_isSearching)
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            elevation: 4,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isSearchLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Searching places on OpenStreetMap...',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // OpenStreetMap Nominatim place matches
                    if (_searchResults.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(left: 12, top: 8, bottom: 4),
                        child: Text(
                          'OpenStreetMap Places',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                        ),
                      ),
                      ..._searchResults.map((p) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.place_outlined, color: AppColors.primary, size: 20),
                            title: Text(
                              p.title,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            subtitle: Text(
                              p.subtitle,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _selectNominatimPlace(p),
                          )),
                    ],

                    // Empty state
                    if (!_isSearchLoading && _searchResults.isEmpty && !_hasSearchError)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No matching locations found for "${_searchController.text.trim()}". You can also search by city or address, use GPS, or pick on the map.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ),

                    // Search error / Retry state
                    if (_hasSearchError)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                            const SizedBox(width: 6),
                            const Text('Search failed. ', style: TextStyle(fontSize: 12, color: AppColors.error)),
                            TextButton(
                              onPressed: () => _performNominatimSearch(_searchController.text.trim()),
                              child: const Text('Retry', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),

                    // OSM Attribution
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text(
                        'Location data © OpenStreetMap contributors / Nominatim',
                        style: TextStyle(fontSize: 9, color: AppColors.textMuted),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMapContainer() {
    return Container(
      height: _isPickingOnMap ? 280 : 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
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
                  key: const Key('registration_map_gesture'),
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (event) {
                    _mapTapDownPosition = event.localPosition;
                  },
                  onPointerUp: (event) {
                    final downPos = _mapTapDownPosition;
                    if (downPos != null) {
                      final delta = (event.localPosition - downPos).distance;
                      if (delta > 20) return; // ignore panning / scrolling
                    }
                    // In manual picker mode: do NOT confirm or save location on tap
                    if (_isPickingOnMap) return;
                    // Outside picker mode: do NOT overwrite already confirmed home location
                    if (!_hasSelectedHomeLocation) {
                      try {
                        final point = _mapController.camera.pointToLatLng(
                          math.Point(event.localPosition.dx, event.localPosition.dy),
                        );
                        _mapCenterLocation = point;
                        _selectMapCoordinate(point);
                      } catch (e) {
                        debugPrint('[MapTap] pointToLatLng fallback: $e');
                        _selectMapCoordinate(_selectedLocation);
                      }
                    }
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
                        errorTileCallback: (tile, error, stackTrace) {},
                        evictErrorTileStrategy: EvictErrorTileStrategy.none,
                      ),
                      if (!_isPickingOnMap && _hasSelectedHomeLocation)
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

                // Fixed Center Pin when picking on map
                if (_isPickingOnMap)
                  IgnorePointer(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 38.0), // Pin tip exactly at center
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Move map under pin',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Icon(
                              Icons.location_pin,
                              color: AppColors.error,
                              size: 44,
                            ),
                            Container(
                              width: 8,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _hasSelectedHomeLocation ? AppColors.primaryLight.withValues(alpha: 0.3) : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasSelectedHomeLocation ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _hasSelectedHomeLocation ? Icons.check_circle : Icons.info_outline,
            color: _hasSelectedHomeLocation ? AppColors.primary : AppColors.textMuted,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hasSelectedHomeLocation ? 'Home location selected' : 'No Home Location Selected',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _hasSelectedHomeLocation ? AppColors.primaryDark : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                if (_hasSelectedHomeLocation) ...[
                  if (_selectedAddressTitle != null && _selectedAddressTitle!.isNotEmpty)
                    Text(
                      _selectedAddressTitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedTerritory != null
                        ? 'District: ${_selectedTerritory!.territoryName} (Auto-detected)'
                        : 'Lat: ${_selectedLocation.latitude.toStringAsFixed(4)}, Lon: ${_selectedLocation.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_selectedLocation.latitude.toStringAsFixed(5)}, ${_selectedLocation.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ] else
                  const Text(
                    'Tap map, use GPS, or search above to select your home location.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (_hasSelectedHomeLocation)
            IconButton(
              tooltip: 'Change location on map',
              icon: const Icon(Icons.edit_location_alt_outlined, size: 20, color: AppColors.primary),
              onPressed: () {
                setState(() {
                  _isPickingOnMap = true;
                  _mapCenterLocation = _selectedLocation;
                });
                try {
                  _mapController.move(_selectedLocation, 14.0);
                } catch (_) {}
              },
            ),
        ],
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
