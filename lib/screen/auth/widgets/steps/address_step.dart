// ignore_for_file: use_build_context_synchronously

import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/utils/validator_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';

class BusinessAddressStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController addressController;
  final TextEditingController landmarkController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController countryController;
  final TextEditingController zipCodeController;
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;

  final FocusNode addressNode;
  final FocusNode landmarkNode;
  final FocusNode cityNode;
  final FocusNode stateNode;
  final FocusNode countryNode;
  final FocusNode zipCodeNode;

  const BusinessAddressStep({
    super.key,
    required this.formKey,
    required this.addressController,
    required this.landmarkController,
    required this.cityController,
    required this.stateController,
    required this.countryController,
    required this.zipCodeController,
    required this.latitudeController,
    required this.longitudeController,
    required this.addressNode,
    required this.landmarkNode,
    required this.cityNode,
    required this.stateNode,
    required this.countryNode,
    required this.zipCodeNode,
  });

  @override
  State<BusinessAddressStep> createState() => _BusinessAddressStepState();
}

class _BusinessAddressStepState extends State<BusinessAddressStep> {
  bool _isLoading = false;
  bool _isFromMapLoading = false;

  Future<void> _autoFetchLocation(BuildContext? l10n) async {
    setState(() => _isLoading = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError(
            l10n?.tr('locationPermissionDenied') ?? 'Location permission denied',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError(
          l10n?.tr('locationPermissionPermanentlyDenied') ??
              'Location permissions are permanently denied',
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          widget.addressController.text = [
            place.street,
            place.subLocality,
            place.locality,
          ].where((e) => e != null && e.isNotEmpty).join(', ');
          widget.landmarkController.text = place.subLocality ?? '';
          widget.cityController.text = place.locality ?? '';
          widget.stateController.text = place.administrativeArea ?? '';
          widget.zipCodeController.text = place.postalCode ?? '';
          widget.latitudeController.text = position.latitude.toStringAsFixed(6);
          widget.longitudeController.text = position.longitude.toStringAsFixed(
            6,
          );
          widget.countryController.text = place.country ?? '';
          if (mounted) {
            showCustomSnackbar(
              context: context,
              message:
                  l10n?.tr('locationFetchedSuccess') ??
                  'Location fetched successfully!',
            );
          }
        });
      }
    } catch (e) {
      _showError(l10n?.tr('failedToGetLocation') ?? 'Failed to get location: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openMapScreen() async {
    // Option A: Try to use existing values first
    double? lat = double.tryParse(widget.latitudeController.text);
    double? lng = double.tryParse(widget.longitudeController.text);

    // If we don't have valid coordinates yet → try to auto-fetch once
    if (lat == null || lng == null || lat == 0 || lng == 0) {
      setState(() {
        _isFromMapLoading = true;
      });
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          Position position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          );
          lat = position.latitude;
          lng = position.longitude;
        } else {
          _showError(
            context.tr('locationPermissionDenied') ??
                'Location permission denied',
          );
        }
      } catch (e) {
        debugPrint('Location error: $e');
        _showError('Could not get current location. Map will open anyway.');
        // continue anyway — map screen has fallback
      } finally {
        setState(() {
          _isFromMapLoading = false;
        });
      }
    }

    // Now open map (with best available coordinates or null)
    final result = await context.push<Map<String, dynamic>>(
      AppRoutes.mapScreen,
      extra: {'latitude': lat, 'longitude': lng},
    );

    if (result != null && mounted) {
      setState(() {
        widget.landmarkController.text = result['sublocality'] ?? '';
        widget.addressController.text = result['address'] ?? '';
        widget.cityController.text = result['city'] ?? '';
        widget.stateController.text = result['state'] ?? '';
        widget.zipCodeController.text = result['zipCode'] ?? '';
        widget.latitudeController.text = result['latitude']?.toString() ?? '';
        widget.longitudeController.text = result['longitude']?.toString() ?? '';
        widget.countryController.text = result['country'] ?? '';
      });
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context;

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field with location icon
          Row(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CustomLoadingIndicator())
                    : SecondaryButton(
                        text: l10n?.tr('autoFetch') ?? "Auto Fetch",
                        icon: Icons.my_location,
                        onPressed: () => _autoFetchLocation(l10n),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _isFromMapLoading
                    ? const Center(child: CustomLoadingIndicator())
                    : PrimaryButton(
                        text: l10n?.tr('fromMap') ?? "From Map",
                        icon: Icons.location_on_rounded,
                        onPressed: _openMapScreen,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          CustomTextField(
            label: l10n?.tr('address') ?? "Address",
            isRequired: true,
            hint: context.tr('eg123ShreeComplexStationRoad'),
            controller: widget.addressController,
            validator: (value) => ValidatorUtils.validateEmpty(context, value),
            focusNode: widget.addressNode,
          ),
          const SizedBox(height: 20),

          CustomTextField(
            label: l10n?.tr('city') ?? "City",
            isRequired: true,
            hint: context.tr('egBhuj'),
            controller: widget.cityController,
            validator: (value) => ValidatorUtils.validateEmpty(context, value),
            focusNode: widget.cityNode,
          ),
          const SizedBox(height: 20),

          CustomTextField(
            label: l10n?.tr('landmark') ?? "Landmark",
            isRequired: true,
            hint: context.tr('egNearBusStand'),
            controller: widget.landmarkController,
            validator: (value) => ValidatorUtils.validateEmpty(context, value),
            focusNode: widget.landmarkNode,
          ),
          const SizedBox(height: 20),

          CustomTextField(
            label: l10n?.tr('state') ?? "State",
            isRequired: true,
            hint: context.tr('egGujarat'),
            controller: widget.stateController,
            validator: (value) => ValidatorUtils.validateEmpty(context, value),
            focusNode: widget.stateNode,
          ),
          const SizedBox(height: 20),

          CustomTextField(
            label: l10n?.tr('zipCode') ?? "Zipcode",
            isRequired: true,
            hint: context.tr('eg370001'),
            controller: widget.zipCodeController,
            keyboardType: TextInputType.number,
            validator: (value) => ValidatorUtils.validateEmpty(context, value),
            focusNode: widget.zipCodeNode,
          ),
          const SizedBox(height: 20),

          CustomTextField(
            label: l10n?.tr('country') ?? "Country",
            hint: context.tr('egIndia'),
            isRequired: true,
            controller: widget.countryController,
            validator: (value) => ValidatorUtils.validateEmpty(context, value),
            focusNode: widget.countryNode,
          ),
          const SizedBox(height: 20),

          CustomTextField(
            label: l10n?.tr('latitude') ?? "Latitude",
            hint: context.tr('eg23241999'),
            isRequired: true,
            controller: widget.latitudeController,
            keyboardType: TextInputType.number,
            readOnly: true,
            validator: (value) => ValidatorUtils.validateEmpty(context, value),
          ),
          const SizedBox(height: 20),

          CustomTextField(
            label: l10n?.tr('longitude') ?? "Longitude",
            hint: context.tr('eg69666881'),
            isRequired: true,
            controller: widget.longitudeController,
            keyboardType: TextInputType.number,
            readOnly: true,
            validator: (value) => ValidatorUtils.validateEmpty(context, value),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
