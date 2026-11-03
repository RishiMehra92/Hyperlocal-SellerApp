import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/image_picker_utils.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/widgets/custom/custom_network_image.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';
import '../bloc/watch_and_buy_bloc.dart';
import '../bloc/watch_and_buy_event.dart';
import '../bloc/watch_and_buy_state.dart';
import '../model/watch_and_buy_profile_model.dart';

class WatchAndBuyProfilePage extends StatefulWidget {
  const WatchAndBuyProfilePage({super.key});

  @override
  State<WatchAndBuyProfilePage> createState() => _WatchAndBuyProfilePageState();
}

class _WatchAndBuyProfilePageState extends State<WatchAndBuyProfilePage> {
  // Create profile form fields
  final _createFormKey = GlobalKey<FormState>();
  final _createUsernameController = TextEditingController();
  final _createBioController = TextEditingController();
  File? _createPhoto;

  // Edit profile form fields
  final _editFormKey = GlobalKey<FormState>();
  final _editUsernameController = TextEditingController();
  final _editBioController = TextEditingController();
  File? _editPhoto;
  bool _isEditingProfile = false;
  bool _initializedEditFields = false;

  @override
  void initState() {
    super.initState();
    context.read<WatchAndBuyBloc>().add(FetchWatchAndBuyProfileEvent());
  }

  @override
  void dispose() {
    _createUsernameController.dispose();
    _createBioController.dispose();
    _editUsernameController.dispose();
    _editBioController.dispose();
    super.dispose();
  }

  Future<void> _pickCreatePhoto() async {
    final String? pickedPath = await ImagePickerUtils.pickMedia(context, mediaType: MediaType.image, maxSizeMb: 2.0);

    if (pickedPath != null) {
      setState(() {
        _createPhoto = File(pickedPath);
      });
    }
  }

  Future<void> _pickEditPhoto() async {
    final String? pickedPath = await ImagePickerUtils.pickMedia(context, mediaType: MediaType.image, maxSizeMb: 2.0);

    if (pickedPath != null) {
      setState(() {
        _editPhoto = File(pickedPath);
      });
    }
  }

  void _submitCreateProfile() {
    if (!DemoGuard.shouldProceed(context)) return;

    final l10n = context;

    if (_createPhoto == null) {
      showCustomSnackbar(
        context: context,
        message: l10n?.tr('pleaseSelectProfilePhoto') ?? 'Please select a profile photo',
        isError: true,
      );
      return;
    }

    if (!_createFormKey.currentState!.validate()) return;

    final rawUsername = _createUsernameController.text.trim();
    final cleanUsername = rawUsername.startsWith('@') ? rawUsername.substring(1) : rawUsername;

    context.read<WatchAndBuyBloc>().add(
      CreateWatchAndBuyProfileEvent(
        username: cleanUsername,
        bio: _createBioController.text.trim(),
        photo: _createPhoto,
      ),
    );
  }

  void _submitEditProfile() {
    if (!DemoGuard.shouldProceed(context)) return;

    if (!_editFormKey.currentState!.validate()) return;

    final rawUsername = _editUsernameController.text.trim();
    final cleanUsername = rawUsername.startsWith('@') ? rawUsername.substring(1) : rawUsername;

    context.read<WatchAndBuyBloc>().add(
      CreateWatchAndBuyProfileEvent(username: cleanUsername, bio: _editBioController.text.trim(), photo: _editPhoto),
    );
  }

  void _initEditFields(WatchAndBuyProfile profile) {
    if (!_initializedEditFields) {
      _editUsernameController.text = profile.username;
      _editBioController.text = profile.bio ?? '';
      _initializedEditFields = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context;

    return BlocConsumer<WatchAndBuyBloc, WatchAndBuyState>(
      listenWhen: (previous, current) => previous.createStatus != current.createStatus,
      listener: (context, state) {
        if (state.createStatus == ApiStatus.success) {
          showCustomSnackbar(
            context: context,
            message: state.createMessage ?? (l10n?.tr('profileUpdatedSuccessfully') ?? 'Profile updated successfully'),
          );
          setState(() {
            _isEditingProfile = false;
            _editPhoto = null;
            _initializedEditFields = false;
          });
        } else if (state.createStatus == ApiStatus.failure) {
          showCustomSnackbar(
            context: context,
            message: state.createMessage ?? (l10n?.tr('failedToUpdateProfile') ?? 'Failed to update profile'),
            isError: true,
          );
        }
      },
      builder: (context, state) {
        if (state.status == ApiStatus.loading) {
          return CustomScaffold(
            title: HiveStorage.watchAndBuyTitle.isNotEmpty
                ? HiveStorage.watchAndBuyTitle
                : (l10n?.tr('watchAndBuyProfile') ?? 'Watch & Buy Profile'),
            showAppbar: true,
            centerTitle: true,
            onBackTap: () => Navigator.of(context).pop(),
            body: const Center(child: CustomLoadingIndicator()),
          );
        }

        if (state.status == ApiStatus.failure) {
          return CustomScaffold(
            title: HiveStorage.watchAndBuyTitle.isNotEmpty
                ? HiveStorage.watchAndBuyTitle
                : (l10n?.tr('watchAndBuyProfile') ?? 'Watch & Buy Profile'),
            showAppbar: true,
            centerTitle: true,
            onBackTap: () => Navigator.of(context).pop(),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      state.errorMessage ?? (l10n?.tr('somethingWentWrong') ?? 'Something went wrong'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: l10n?.tr('retry') ?? 'Retry',
                      width: 140,
                      onPressed: () {
                        context.read<WatchAndBuyBloc>().add(FetchWatchAndBuyProfileEvent());
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Profile found -> 3 Tappable Containers view
        if (state.profile != null) {
          _initEditFields(state.profile!);
          return _buildProfileView(context, state.profile!, state);
        }

        // No profile found -> Show Profile Create Screen
        return _buildCreateProfileView(context, state);
      },
    );
  }

  Widget _buildCreateProfileView(BuildContext context, WatchAndBuyState state) {
    final l10n = context;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenType = context.screenType;

    return CustomScaffold(
      title: HiveStorage.watchAndBuyTitle.isNotEmpty
          ? 'Create ${HiveStorage.watchAndBuyTitle} Profile'
          : (l10n?.tr('createWatchAndBuyProfile') ?? 'Create Watch & Buy Profile'),
      showAppbar: true,
      centerTitle: true,
      onBackTap: () {
        Navigator.of(context).pop();
      },
      body: SingleChildScrollView(
        padding: UIUtils.pagePadding(screenType),
        child: Form(
          key: _createFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notice banner: No User profile found
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primaryColor, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n?.tr('noUserProfileFoundPleaseCreate') ?? 'No User profile found, please create.',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Profile Photo Label
              Center(
                child: RichText(
                  text: TextSpan(
                    text: l10n?.tr('uploadPhoto') ?? 'Profile Photo',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: theme.colorScheme.tertiary),
                    children: const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Profile Photo Picker
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _pickCreatePhoto,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: isDark ? AppColors.mainDarkContainerBgColor : Colors.grey.shade200,
                        backgroundImage: _createPhoto != null ? FileImage(_createPhoto!) : null,
                        child: _createPhoto == null ? Icon(Icons.person, size: 50, color: Colors.grey.shade400) : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickCreatePhoto,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: AppColors.primaryColor, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Username Field
              CustomTextField(
                label: l10n?.tr('usernameLabel') ?? 'Username',
                hint: l10n?.tr('usernameHint') ?? 'username',
                isRequired: true,
                controller: _createUsernameController,
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
                  child: Text(
                    '@',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryColor),
                  ),
                ),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9._]'))],
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n?.tr('pleaseEnterUsername') ?? 'Please enter a valid username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Bio Field (3 lines)
              CustomTextField(
                label: l10n?.tr('bioLabel') ?? 'Bio',
                hint: l10n?.tr('bioHint') ?? 'Tell your audience about yourself or store...',
                isRequired: true,
                controller: _createBioController,
                maxLines: 3,
                minLines: 3,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n?.tr('pleaseEnterBio') ?? 'Please enter a bio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              PrimaryButton(
                text: l10n?.tr('createProfileButton') ?? 'Create Profile',
                isLoading: state.createStatus == ApiStatus.loading,
                onPressed: state.createStatus == ApiStatus.loading ? null : _submitCreateProfile,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileView(BuildContext context, WatchAndBuyProfile profile, WatchAndBuyState state) {
    final l10n = context;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenType = context.screenType;

    return CustomScaffold(
      title: HiveStorage.watchAndBuyTitle.isNotEmpty
          ? HiveStorage.watchAndBuyTitle
          : (l10n?.tr('watchAndBuyProfile') ?? 'Watch & Buy Profile'),
      showAppbar: true,
      centerTitle: true,
      onBackTap: () => Navigator.of(context).pop(),
      body: SingleChildScrollView(
        padding: UIUtils.pagePadding(screenType),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Profile Container (Tapable & Editable)
            _buildProfileContainer(context, profile, isDark, screenType, state),
            const SizedBox(height: 16),

            // 2. Stories Container (Tapable)
            _buildStoriesContainer(context, isDark, screenType),
            const SizedBox(height: 16),

            // 3. Reels Container (Tapable)
            _buildReelsContainer(context, isDark, screenType),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContainer(
    BuildContext context,
    WatchAndBuyProfile profile,
    bool isDark,
    ScreenType screenType,
    WatchAndBuyState state,
  ) {
    final l10n = context;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.mainDarkContainerBgColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isEditingProfile
              ? AppColors.primaryColor.withValues(alpha: 0.5)
              : (isDark ? Colors.transparent : Colors.grey.shade200),
          width: _isEditingProfile ? 1.5 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              // Avatar
              Stack(
                children: [
                  GestureDetector(
                    onTap: _isEditingProfile ? _pickEditPhoto : null,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: _editPhoto != null
                          ? Image.file(_editPhoto!, width: 64, height: 64, fit: BoxFit.cover)
                          : (profile.photoUrl != null && profile.photoUrl!.isNotEmpty
                                ? CustomNetworkImage(
                                    imageUrl: profile.photoUrl!,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 64,
                                    height: 64,
                                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                                    child: const Icon(Icons.person, size: 36, color: AppColors.primaryColor),
                                  )),
                    ),
                  ),
                  if (_isEditingProfile)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickEditPhoto,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(color: AppColors.primaryColor, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Title / Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '@${profile.username}',
                            style: TextStyle(fontSize: UIUtils.tileTitle(screenType), fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: profile.status.toLowerCase() == 'active'
                                ? Colors.green.withValues(alpha: 0.12)
                                : Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            profile.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: profile.status.toLowerCase() == 'active'
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isEditingProfile
                          ? (l10n?.tr('changePhoto') ?? 'Tap photo to change')
                          : (profile.bio != null && profile.bio!.isNotEmpty
                                ? profile.bio!
                                : (l10n?.tr('noBioAddedYet') ?? 'No bio added yet')),
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.2),
                      maxLines: _isEditingProfile ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Edit / Cancel toggle button
              IconButton(
                icon: Icon(
                  _isEditingProfile ? Icons.close : Icons.edit_outlined,
                  color: AppColors.primaryColor,
                  size: 22,
                ),
                tooltip: _isEditingProfile ? (l10n?.tr('cancel') ?? 'Cancel') : (l10n?.tr('profileTab') ?? 'Edit Profile'),
                onPressed: () {
                  if (!_isEditingProfile && !PermissionChecker.hasPermission(AppPermissions.watchBuyProfileEdit)) {
                    showCustomSnackbar(
                      context: context,
                      message: l10n?.tr('noPermissionError') ?? 'You do not have permission to perform this action',
                      isWarning: true,
                    );
                    return;
                  }
                  setState(() {
                    _isEditingProfile = !_isEditingProfile;
                    if (!_isEditingProfile) {
                      _editPhoto = null;
                      _initializedEditFields = false;
                    }
                  });
                },
              ),
            ],
          ),

          // Editable Form Content (when _isEditingProfile is true)
          if (_isEditingProfile) ...[
            const Divider(height: 28),
            Form(
              key: _editFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    label: l10n?.tr('usernameLabel') ?? 'Username',
                    hint: l10n?.tr('usernameHint') ?? 'username',
                    isRequired: true,
                    controller: _editUsernameController,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
                      child: Text(
                        '@',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryColor),
                      ),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9._]'))],
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return l10n?.tr('pleaseEnterUsername') ?? 'Please enter a valid username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: l10n?.tr('bioLabel') ?? 'Bio',
                    hint: l10n?.tr('bioHint') ?? 'Tell your audience about yourself or store...',
                    isRequired: true,
                    controller: _editBioController,
                    maxLines: 3,
                    minLines: 3,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return l10n?.tr('pleaseEnterBio') ?? 'Please enter a bio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _isEditingProfile = false;
                              _editPhoto = null;
                              _initializedEditFields = false;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(l10n?.tr('cancel') ?? 'Cancel', style: const TextStyle(color: Colors.red)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: PrimaryButton(
                          text: l10n?.tr('save') ?? 'Save Changes',
                          isLoading: state.createStatus == ApiStatus.loading,
                          onPressed: state.createStatus == ApiStatus.loading ? null : _submitEditProfile,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStoriesContainer(BuildContext context, bool isDark, ScreenType screenType) {
    final l10n = context;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (!PermissionChecker.hasPermission(AppPermissions.watchBuyStatusView)) {
            showCustomSnackbar(
              context: context,
              message: l10n?.tr('noPermissionError') ?? 'You do not have permission to perform this action',
              isWarning: true,
            );
            return;
          }
          context.pushNamed(AppRoutes.watchAndBuyStories);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.mainDarkContainerBgColor : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.amp_stories_rounded, color: Colors.purple, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.tr('storiesTab') ?? 'Stories',
                      style: TextStyle(fontSize: UIUtils.tileTitle(screenType), fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n?.tr('storiesSubtitle') ?? 'Manage and share your daily store stories',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReelsContainer(BuildContext context, bool isDark, ScreenType screenType) {
    final l10n = context;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (!PermissionChecker.hasPermission(AppPermissions.watchBuyReelView)) {
            showCustomSnackbar(
              context: context,
              message: l10n?.tr('noPermissionError') ?? 'You do not have permission to perform this action',
              isWarning: true,
            );
            return;
          }
          context.pushNamed(AppRoutes.watchAndBuyReels);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.mainDarkContainerBgColor : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.video_library_rounded, color: Colors.redAccent, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.tr('reelsTab') ?? 'Reels',
                      style: TextStyle(fontSize: UIUtils.tileTitle(screenType), fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n?.tr('reelsSubtitle') ?? 'Manage product video reels and promotions',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
