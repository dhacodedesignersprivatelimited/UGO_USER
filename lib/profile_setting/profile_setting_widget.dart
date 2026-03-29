import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';

import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'profile_setting_model.dart';
export 'profile_setting_model.dart';

class ProfileSettingWidget extends StatefulWidget {
  const ProfileSettingWidget({super.key});

  static String routeName = 'Profile_setting';
  static String routePath = '/profileSetting';

  @override
  State<ProfileSettingWidget> createState() => _ProfileSettingWidgetState();
}

class _ProfileSettingWidgetState extends State<ProfileSettingWidget>
    with TickerProviderStateMixin {
  late ProfileSettingModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // UI State
  bool _loading = true;
  bool _saving = false;
  bool _referralLocked = false;
  String? _linkedReferralCode;

  String _profileImageUrl = '';
  FFUploadedFile? _pickedProfileImage;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _referralCodeController;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProfileSettingModel());

    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _referralCodeController = TextEditingController();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _referralCodeController.dispose();
    _model.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = FFAppState().userid;
      final token = FFAppState().accessToken;

      if (userId == 0 || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _nameController.text = 'Guest User';
          _phoneController.text = '';
          _emailController.text = '';
          _profileImageUrl = '';
        });
        return;
      }

      final res = await GetUserDetailsCall.call(userId: userId, token: token);

      if (!mounted) return;

      if (res.succeeded) {
        final first = (GetUserDetailsCall.firstName(res.jsonBody) ?? '').trim();
        final last = (GetUserDetailsCall.lastName(res.jsonBody) ?? '').trim();
        final mobile =
        (GetUserDetailsCall.mobileNumber(res.jsonBody) ?? '').trim();
        final email = (GetUserDetailsCall.email(res.jsonBody) ?? '').trim();
        final rawImg =
        (GetUserDetailsCall.profileImage(res.jsonBody) ?? '').trim();

        final fullName = [first, last].where((e) => e.isNotEmpty).join(' ');
        final imgUrl = rawImg.isNotEmpty
            ? (rawImg.startsWith('http')
            ? rawImg
            : '${AppConfig.baseApiUrl}/$rawImg')
            : '';

        final refBy = GetUserDetailsCall.referredByUserId(res.jsonBody);
        final usedCode =
            (GetUserDetailsCall.usedReferralCodeField(res.jsonBody) ?? '')
                .trim();
        if (mounted) {
          setState(() {
            _nameController.text = fullName.isNotEmpty ? fullName : 'User';
            _phoneController.text = mobile;
            _emailController.text = email;
            _profileImageUrl = imgUrl;
            _referralLocked =
                (refBy != null && refBy > 0) || usedCode.isNotEmpty;
            _linkedReferralCode = usedCode.isNotEmpty ? usedCode : null;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Load profile error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  /// ✅ FIX: Don’t request `Permission.storage` for gallery picking.
  /// `image_picker` uses the system picker/scoped storage on modern Android.
  Future<void> _pickProfileImage() async {
    if (_saving) return;

    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (file == null) {
        // ignore: avoid_print
        print('❌ Image picker cancelled by user');
        return;
      }

      // ignore: avoid_print
      print('✅ Selected image: ${file.name}, size: ${await file.length()} bytes');

      final Uint8List bytes = await file.readAsBytes();
      if (!mounted) return;

      setState(() {
        _pickedProfileImage = FFUploadedFile(
          name: file.name,
          bytes: bytes,
        );
        _profileImageUrl = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Image selected successfully'),
            ],
          ),
          backgroundColor: Colors.green.shade500,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // ignore: avoid_print
      print('❌ Image picker error: $e');
      if (!mounted) return;

      _showError('Image selection failed: ${e.toString().split('\n')[0]}');
      _showFallbackDialog();
    }
  }

  void _showFallbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Image Selection Failed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_not_supported,
                size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            const Text('Gallery access failed. Try camera instead?'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _tryCamera(),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Use Camera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FlutterFlowTheme.of(context).primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _tryCamera() async {
    Navigator.pop(context);

    try {
      final camStatus = await Permission.camera.status;
      if (!camStatus.isGranted) {
        final result = await Permission.camera.request();
        if (!result.isGranted) {
          if (result.isPermanentlyDenied) {
            _showError('Camera permission permanently denied. Enable in settings.');
            await openAppSettings();
          } else {
            _showError('Camera permission required');
          }
          return;
        }
      }

      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      setState(() {
        _pickedProfileImage = FFUploadedFile(
          name: file.name,
          bytes: bytes,
        );
        _profileImageUrl = '';
      });

      _showSuccess('Photo taken successfully!');
    } catch (e) {
      // ignore: avoid_print
      print('❌ Camera error: $e');
      _showError('Camera access failed');
    }
  }

  (String firstName, String lastName) _splitName(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return ('', '');
    if (parts.length == 1) return (parts.first, '');
    return (parts.first, parts.sublist(1).join(' '));
  }

  Future<void> _saveProfile() async {
    if (_saving) return;

    final userId = FFAppState().userid;
    final token = FFAppState().accessToken;

    if (userId == 0 || token.isEmpty) {
      _showError('Please login to update your profile');
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty) {
      _showError('Name cannot be empty');
      return;
    }

    final (firstName, lastName) = _splitName(name);

    setState(() => _saving = true);

    try {
      // ignore: avoid_print
      print('🔄 Updating profile...');

      final updateRes = await UpdateUserByIdCall.call(
        userId: userId,
        token: token,
        firstName: firstName,
        lastName: lastName,
        email: email,
      );

      if (!updateRes.succeeded) {
        // ignore: avoid_print
        print('❌ Profile update failed');
        if (mounted) {
          setState(() => _saving = false);
          _showError('Failed to update profile');
        }
        return;
      }

      if (_pickedProfileImage != null) {
        // ignore: avoid_print
        print('📤 Uploading image...');
        final imgRes = await UpdateProfileImageCall.call(
          userId: userId,
          token: token,
          profileImage: _pickedProfileImage!,
        );

        if (!imgRes.succeeded) {
          // ignore: avoid_print
          print('❌ Image upload failed');
          if (mounted) {
            setState(() => _saving = false);
            _showError('Profile image upload failed');
          }
          return;
        }
      }

      // ignore: avoid_print
      print('✅ Refreshing profile...');
      await _loadProfile();

      if (mounted) {
        setState(() {
          _pickedProfileImage = null;
          _saving = false;
        });

        _showSuccess('Profile updated successfully!');
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Save error: $e');
      if (mounted) {
        setState(() => _saving = false);
        _showError('Save failed. Please try again.');
      }
    }
  }

  Future<void> _applyReferralCode() async {
    final code = _referralCodeController.text.trim();
    if (code.isEmpty) {
      _showError('Please enter a referral code');
      return;
    }

    final userId = FFAppState().userid;
    final token = FFAppState().accessToken;

    if (userId == 0 || token.isEmpty) {
      _showError('Please login to apply code');
      return;
    }

    setState(() => _saving = true);

    try {
      final res = await ApplyReferralCodeCall.call(
        userId: userId,
        referralCode: code,
        token: token,
      );

      if (res.succeeded) {
        _showSuccess(
          ApplyReferralCodeCall.message(res.jsonBody) ??
              'Referral linked. Your friend earns when you take Pro rides.',
        );
        _referralCodeController.clear();
        await _loadProfile();
      } else {
        final msg = ApplyReferralCodeCall.message(res.jsonBody) ??
            'Could not apply this code. Check spelling or ask your friend for their code in Refer & Earn.';
        _showError(msg);
      }
    } catch (e) {
      _showError('An error occurred');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle,
                color: Colors.white, semanticLabel: 'Success'),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _profileImageSection() {
    return GestureDetector(
      onTap: _saving ? null : _pickProfileImage,
      onLongPress: _saving ? null : _pickProfileImage,
      child: SizedBox(
        width: 110,
        height: 110,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(55),
            onTap: _saving ? null : _pickProfileImage,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              FlutterFlowTheme.of(context)
                                  .primary
                                  .withValues(alpha:0.15),
                              FlutterFlowTheme.of(context)
                                  .secondary
                                  .withValues(alpha:0.15),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha:0.12),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                ClipOval(
                  child: Container(
                    width: 96,
                    height: 96,
                    color: Colors.white,
                    child: _loading
                        ? Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          FlutterFlowTheme.of(context).primary,
                        ),
                      ),
                    )
                        : _pickedProfileImage?.bytes != null
                        ? Image.memory(
                      _pickedProfileImage!.bytes!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                        : _profileImageUrl.isNotEmpty
                        ? Image.network(
                      _profileImageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                            AlwaysStoppedAnimation<Color>(
                              FlutterFlowTheme.of(context).primary,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[100],
                          child: const Icon(
                            Icons.person,
                            size: 48,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                        : Container(
                      color: Colors.grey[100],
                      child: const Icon(
                        Icons.person,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -5,
                  right: -5,
                  child: GestureDetector(
                    onTap: _saving ? null : _pickProfileImage,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _pickedProfileImage != null ? Icons.edit : Icons.camera_alt,
                        size: 22,
                        color: FlutterFlowTheme.of(context).primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    TextInputType? keyboardType,
    IconData? icon,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 20,
                color: FlutterFlowTheme.of(context).primary,
              ),
            if (icon != null) const SizedBox(width: 8),
            Text(
              label,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: FlutterFlowTheme.of(context).primaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboardType,
            enabled: !_saving,
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              prefixIcon: icon != null && readOnly
                  ? Icon(icon, size: 20, color: Colors.grey.shade400)
                  : null,
            ),
            style: FlutterFlowTheme.of(context).bodyMedium.override(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  FlutterFlowTheme.of(context).primary,
                  FlutterFlowTheme.of(context).primary.withValues(alpha:0.9),
                ],
              ),
            ),
          ),
          leading: FlutterFlowIconButton(
            borderRadius: 20,
            buttonSize: 44,
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: FlutterFlowTheme.of(context).secondaryBackground,
              size: 20,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Profile Settings',
            style: FlutterFlowTheme.of(context).titleLarge.override(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: FlutterFlowTheme.of(context).secondaryBackground,
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: _loading
              ? const Center(
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
              : SingleChildScrollView(
            child: Column(
              children: [
                _profileImageSection().animate().fadeIn(
                  duration: 600.ms,
                  delay: 200.ms,
                ),
                const SizedBox(height: 40),
                _inputField(
                  label: 'Full Name',
                  controller: _nameController,
                  icon: Icons.person_outline,
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 24),
                _inputField(
                  label: 'Phone Number',
                  controller: _phoneController,
                  readOnly: true,
                  keyboardType: TextInputType.phone,
                  icon: Icons.phone_outlined,
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 24),
                _inputField(
                  label: 'Email Address',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  icon: Icons.email_outlined,
                ).animate().fadeIn(delay: 600.ms),
                const SizedBox(height: 24),
                if (_referralLocked)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Referral code',
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: FlutterFlowTheme.of(context).primary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _linkedReferralCode ?? 'Linked at signup',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'A friend\'s code is already linked. For security, referral codes can\'t be changed later.',
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      fontSize: 12,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 650.ms)
                else ...[
                  _inputField(
                    label: 'Friend\'s referral code (optional)',
                    controller: _referralCodeController,
                    icon: Icons.card_giftcard_outlined,
                    hintText: 'From Refer & Earn in their app',
                  ).animate().fadeIn(delay: 650.ms),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _saving ? null : _applyReferralCode,
                      icon: Icon(Icons.check_circle_outline,
                          size: 18,
                          color: FlutterFlowTheme.of(context).primary),
                      label: Text(
                        'Apply code',
                        style: TextStyle(
                          color: FlutterFlowTheme.of(context).primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 670.ms),
                ],
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      FlutterFlowTheme.of(context).primary,
                      foregroundColor: Colors.white,
                      elevation: _saving ? 0 : 8,
                      shadowColor: Colors.black.withValues(alpha:0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _saving
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                            AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Saving...',
                          style: FlutterFlowTheme.of(context)
                              .titleSmall
                              .override(color: Colors.white),
                        ),
                      ],
                    )
                        : Text(
                      'Save Changes',
                      style: FlutterFlowTheme.of(context)
                          .titleSmall
                          .override(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 700.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
