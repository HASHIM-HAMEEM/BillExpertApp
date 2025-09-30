import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../app/themes/app_theme.dart';
import '../../core/config/app_config.dart';
import '../../core/models/merchant.dart';
import '../../core/models/currency.dart';
import '../../core/models/fx_rates.dart';
import '../../core/services/merchant_repository.dart';
import '../../core/services/currency_service.dart';
import '../../core/services/theme_controller.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:flutter/services.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchantRepo = ref.watch(merchantRepositoryProvider);
    final currencyService = ref.watch(currencyServiceProvider);
    final themeController = ref.watch(themeControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(
        context,
      ), // Theme-aware background
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: context.responsiveFontSize(17),
            fontWeight: FontWeight.w600,
            color: AppTheme.getTextPrimaryColor(context),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: context.responsivePadding,
        child: Column(
          children: [
            // Settings Section
            _SettingsGroup(
              title: 'Settings',
              children: [
                _SettingItem(
                  icon: Icons.person_outline,
                  title: 'Profile',
                  onTap: () => _showProfileSheet(context, merchantRepo),
                ),
                _SettingItem(
                  icon: Icons.receipt_outlined,
                  title: 'Invoice Preferences',
                  onTap: () =>
                      _showInvoicePreferencesSheet(context, merchantRepo),
                ),
                _SettingItem(
                  icon: Icons.palette_outlined,
                  title: 'Appearance',
                  onTap: () => _showAppearanceSheet(context, themeController),
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final displayCurrencyAsync = ref.watch(
                      displayCurrencyFutureProvider,
                    );
                    return _SettingItem(
                      icon: Icons.currency_exchange_outlined,
                      title: 'Currency',
                      subtitle: displayCurrencyAsync.maybeWhen(
                        data: (currency) => currency,
                        orElse: () => 'USD',
                      ),
                      onTap: () => _showCurrencySheet(
                        context,
                        merchantRepo,
                        currencyService,
                        ref,
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // More Section
            _SettingsGroup(
              title: 'More',
              children: [
                _SettingItem(
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () => _showAboutSheet(context),
                ),
                _SettingItem(
                  icon: Icons.help_outline,
                  title: 'Help',
                  onTap: () => _showHelpSheet(context),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Palestine Support Message
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.getCardSurfaceColor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.getBorderColor(context),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🇵🇸', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    'Palestine ❤️ ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextPrimaryColor(context),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showProfileSheet(BuildContext context, MerchantRepository repo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProfileSheet(repository: repo),
    );
  }

  void _showInvoicePreferencesSheet(
    BuildContext context,
    MerchantRepository repo,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _InvoicePreferencesSheet(repository: repo),
    );
  }

  void _showAppearanceSheet(BuildContext context, AppThemeMode themeMode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AppearanceSheet(themeMode: themeMode),
    );
  }

  void _showCurrencySheet(
    BuildContext context,
    MerchantRepository repo,
    dynamic currencyService,
    WidgetRef ref,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CurrencySheet(
        repository: repo,
        currencyService: currencyService,
        ref: ref,
      ),
    );
  }

  void _showAboutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AboutSheet(),
    );
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _HelpSheet(),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PrimaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: context.responsiveWidth(4),
            bottom: context.responsiveHeight(1),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: context.responsiveFontSize(22),
              fontWeight: FontWeight.w700,
              color: AppTheme.getTextPrimaryColor(context),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.getCardSurfaceColor(context),
            borderRadius: BorderRadius.circular(
              context.responsiveBorderRadius(),
            ),
            border: Border.all(color: AppTheme.getBorderColor(context)),
          ),
          child: Column(
            children: children.asMap().entries.map((entry) {
              final index = entry.key;
              final child = entry.value;
              return Column(
                children: [
                  child,
                  if (index < children.length - 1)
                    Divider(
                      height: 1,
                      indent: 52,
                      color: AppTheme.getDividerColor(context),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
        child: Padding(
          padding: context.responsivePadding,
          child: Row(
            children: [
              Icon(
                icon,
                size: context.responsiveIconSize(),
                color: AppTheme.getTextPrimaryColor(context),
              ),
              SizedBox(width: context.responsiveWidth(4)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(17),
                        fontWeight: FontWeight.w400,
                        color: AppTheme.getTextPrimaryColor(context),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: context.responsiveFontSize(14),
                          color: AppTheme.getTextSecondaryColor(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: context.responsiveIconSize(
                  mobile: 18,
                  tablet: 20,
                  desktop: 22,
                ),
                color: AppTheme.getTextSecondaryColor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreferenceField extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String name;
  final String? initialValue;
  final String? placeholder;
  final TextInputType? keyboardType;
  final int? maxLines;
  final FormFieldValidator<String>? validator;

  const _PreferenceField({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.name,
    this.initialValue,
    this.placeholder,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon and Title Row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.getTextSecondaryColor(
                  context,
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: AppTheme.getTextSecondaryColor(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextPrimaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.getTextSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Input Field
        _SheetInputField(
          name: name,
          label: '',
          initialValue: initialValue,
          placeholder: placeholder,
          keyboardType: keyboardType,
          maxLines: maxLines ?? 1,
          validator: validator,
        ),
      ],
    );
  }
}

// Profile Sheet
class _ProfileSheet extends StatefulWidget {
  final MerchantRepository repository;

  const _ProfileSheet({required this.repository});

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  final _formKey = GlobalKey<FormBuilderState>();
  MerchantProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await widget.repository.getProfile();
    setState(() => _profile = profile);
  }

  @override
  Widget build(BuildContext context) {
    if (_profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardSurfaceColor(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.getBorderColor(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getTextPrimaryColor(context),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: AppTheme.getTextPrimaryColor(context),
                      size: 24,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Profile Section
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _SettingsGroup(
                        title: 'Business Information',
                        children: [
                          Container(
                            padding: context.responsivePadding,
                            child: FormBuilder(
                              key: _formKey,
                              child: Column(
                                children: [
                                  _SheetInputField(
                                    name: 'businessName',
                                    label: 'Business Name',
                                    initialValue: _profile!.businessName,
                                    validator: FormBuilderValidators.required(),
                                  ),
                                  SizedBox(height: context.responsiveHeight(2)),
                                  _SheetInputField(
                                    name: 'email',
                                    label: 'Email',
                                    initialValue: _profile!.email,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: FormBuilderValidators.email(),
                                  ),
                                  SizedBox(height: context.responsiveHeight(2)),
                                  _SheetInputField(
                                    name: 'phone',
                                    label: 'Phone',
                                    initialValue: _profile!.phone,
                                    keyboardType: TextInputType.phone,
                                  ),
                                  SizedBox(height: context.responsiveHeight(2)),
                                  _SheetInputField(
                                    name: 'address',
                                    label: 'Address',
                                    initialValue: _profile!.address,
                                    maxLines: 3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: _PrimaryButton(
                          label: 'Save Changes',
                          onPressed: _saveProfile,
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final ok = _formKey.currentState?.saveAndValidate() ?? false;
    if (!ok) return;

    final v = _formKey.currentState!.value;
    final updatedProfile = _profile!.copyWith(
      businessName: v['businessName'],
      email: v['email'],
      phone: v['phone'],
      address: v['address'],
    );

    await widget.repository.updateProfile(updatedProfile);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

// Invoice Preferences Sheet
class _InvoicePreferencesSheet extends StatefulWidget {
  final MerchantRepository repository;

  const _InvoicePreferencesSheet({required this.repository});

  @override
  State<_InvoicePreferencesSheet> createState() =>
      _InvoicePreferencesSheetState();
}

class _InvoicePreferencesSheetState extends State<_InvoicePreferencesSheet> {
  final _formKey = GlobalKey<FormBuilderState>();
  MerchantProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await widget.repository.getProfile();
    setState(() => _profile = profile);
  }

  @override
  Widget build(BuildContext context) {
    if (_profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardSurfaceColor(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.getBorderColor(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Invoice Preferences',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getTextPrimaryColor(context),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: AppTheme.getTextPrimaryColor(context),
                      size: 24,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Subtitle
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'Customize your invoice defaults and settings',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.getTextSecondaryColor(context),
                  ),
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Invoice Numbering Section
                      _SettingsGroup(
                        title: 'Invoice Numbering',
                        children: [
                          Container(
                            padding: context.responsivePadding,
                            child: FormBuilder(
                              key: _formKey,
                              child: Column(
                                children: [
                                  _PreferenceField(
                                    icon: Icons.tag,
                                    title: 'Invoice Prefix',
                                    subtitle:
                                        'Prefix for all invoice numbers (e.g., INV)',
                                    name: 'invoicePrefix',
                                    initialValue: _profile!.invoicePrefix,
                                    placeholder: 'INV',
                                  ),
                                  SizedBox(height: context.responsiveHeight(2)),
                                  _PreferenceField(
                                    icon: Icons.attach_money,
                                    title: 'Default Currency',
                                    subtitle: 'Currency used for new invoices',
                                    name: 'currencyCode',
                                    initialValue: _profile!.currencyCode,
                                    placeholder: 'USD',
                                    validator: FormBuilderValidators.required(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Payment Terms Section
                      _SettingsGroup(
                        title: 'Payment Terms',
                        children: [
                          Container(
                            padding: context.responsivePadding,
                            child: _PreferenceField(
                              icon: Icons.schedule,
                              title: 'Default Due Days',
                              subtitle:
                                  'Number of days until invoice is due (e.g., 30)',
                              name: 'defaultDueDays',
                              initialValue: _profile!.defaultDueDays
                                  ?.toString(),
                              placeholder: '30',
                              keyboardType: TextInputType.number,
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.numeric(),
                                FormBuilderValidators.min(1),
                                FormBuilderValidators.max(365),
                              ]),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Content Templates Section
                      _SettingsGroup(
                        title: 'Content Templates',
                        children: [
                          Container(
                            padding: context.responsivePadding,
                            child: Column(
                              children: [
                                _PreferenceField(
                                  icon: Icons.description,
                                  title: 'Default Terms & Conditions',
                                  subtitle: 'Terms that appear on all invoices',
                                  name: 'defaultTerms',
                                  initialValue: _profile!.defaultTerms,
                                  maxLines: 4,
                                  placeholder:
                                      'Payment due within 30 days. Late fees may apply.',
                                ),
                                const SizedBox(height: 20),
                                _PreferenceField(
                                  icon: Icons.note,
                                  title: 'Default Notes',
                                  subtitle: 'Additional notes or instructions',
                                  name: 'defaultNotes',
                                  initialValue: _profile!.defaultNotes,
                                  maxLines: 4,
                                  placeholder: 'Thank you for your business!',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: _PrimaryButton(
                          label: 'Save Preferences',
                          onPressed: _savePreferences,
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePreferences() async {
    final ok = _formKey.currentState?.saveAndValidate() ?? false;
    if (!ok) return;

    final v = _formKey.currentState!.value;
    final updatedProfile = _profile!.copyWith(
      invoicePrefix: v['invoicePrefix'],
      currencyCode: v['currencyCode'],
      defaultDueDays: int.tryParse(v['defaultDueDays'] ?? ''),
      defaultTerms: v['defaultTerms'],
      defaultNotes: v['defaultNotes'],
    );

    await widget.repository.updateProfile(updatedProfile);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences updated'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

// Appearance Sheet
class _AppearanceSheet extends StatelessWidget {
  final AppThemeMode themeMode;

  const _AppearanceSheet({required this.themeMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardSurfaceColor(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.getBorderColor(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Appearance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getTextPrimaryColor(context),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: AppTheme.getTextPrimaryColor(context),
                      size: 24,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Theme Section
              _SettingsGroup(
                title: 'Theme',
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final currentTheme = ref.watch(themeControllerProvider);

                      return Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _ThemeOption(
                              title: 'System',
                              subtitle: 'Follow device settings',
                              isSelected: currentTheme == AppThemeMode.system,
                              onTap: () => ref
                                  .read(themeControllerProvider.notifier)
                                  .setTheme(AppThemeMode.system),
                            ),
                            const SizedBox(height: 12),
                            _ThemeOption(
                              title: 'Light',
                              subtitle: 'Always light theme',
                              isSelected: currentTheme == AppThemeMode.light,
                              onTap: () => ref
                                  .read(themeControllerProvider.notifier)
                                  .setTheme(AppThemeMode.light),
                            ),
                            const SizedBox(height: 12),
                            _ThemeOption(
                              title: 'Dark',
                              subtitle: 'Always dark theme',
                              isSelected: currentTheme == AppThemeMode.dark,
                              onTap: () => ref
                                  .read(themeControllerProvider.notifier)
                                  .setTheme(AppThemeMode.dark),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.getBackgroundColor(context),
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.getTextSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppTheme.getTextPrimaryColor(context),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// FX Rates Sheet
class _CurrencySheet extends StatefulWidget {
  final MerchantRepository repository;
  final dynamic currencyService;
  final WidgetRef ref;

  const _CurrencySheet({
    required this.repository,
    required this.currencyService,
    required this.ref,
  });

  @override
  State<_CurrencySheet> createState() => _CurrencySheetState();
}

class _CurrencySheetState extends State<_CurrencySheet> {
  final _formKey = GlobalKey<FormBuilderState>();
  MerchantProfile? _profile;
  Currency? _selectedCurrency;
  bool _isRefreshingRates = false;
  String? _lastUpdated;
  final ValueNotifier<FxRates?> _currentRatesNotifier = ValueNotifier<FxRates?>(
    null,
  );
  final List<String> _debugLines = [];

  void _addDebug(String message) {
    final ts = DateTime.now().toIso8601String();
    final line = '[$ts] $message';
    debugPrint('SettingsCurrency: $line');
    setState(() {
      _debugLines.insert(0, line);
      if (_debugLines.length > 20) _debugLines.removeLast();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadLastUpdated();
    _loadCurrentRates();
    _addDebug('Currency sheet opened');
  }

  @override
  void dispose() {
    _currentRatesNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await widget.repository.getProfile();
    if (profile != null) {
      setState(() {
        _profile = profile;
        _selectedCurrency =
            Currency.findByCode(
              profile.displayCurrencyCode ?? profile.currencyCode,
            ) ??
            Currency.defaultCurrency;
      });
    }
  }

  Future<void> _loadLastUpdated() async {
    final lastUpdated = await widget.currencyService.getLastUpdated();
    if (lastUpdated != null) {
      setState(() {
        _lastUpdated = _formatLastUpdated(lastUpdated);
      });
      _addDebug('Last updated: $lastUpdated');
    }
  }

  Future<void> _loadCurrentRates() async {
    final rates = await widget.currencyService.getCurrentRates();
    _currentRatesNotifier.value = rates;
    if (rates != null) {
      _addDebug(
        'Current rates base=${rates.baseCurrency} fetchedAt=${rates.fetchedAt.toIso8601String()} count=${rates.rates.length}',
      );
    } else {
      _addDebug('No cached rates available');
    }
  }

  Future<void> _refreshRates() async {
    setState(() => _isRefreshingRates = true);

    try {
      _addDebug('Refresh tapped');
      final hasInternet = await widget.currencyService.hasInternetConnection();
      _addDebug('Internet available=$hasInternet');

      if (!hasInternet) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No internet connection. Please check your network and try again.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isRefreshingRates = false);
        return;
      }

      final before = await widget.currencyService.getCurrentRates();
      if (before != null) {
        _addDebug(
          'Before refresh base=${before.baseCurrency} fetchedAt=${before.fetchedAt.toIso8601String()} count=${before.rates.length}',
        );
      }

      final success = await widget.currencyService.refreshExchangeRates();
      _addDebug('Refresh result success=$success');

      if (success) {
        await _loadLastUpdated();
        await _loadCurrentRates();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Exchange rates updated successfully'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to update exchange rates. The service might be temporarily unavailable.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        await _loadCurrentRates();
        final diags = await widget.currencyService.getLastFetchDiagnostics();
        if (diags.isNotEmpty) {
          _addDebug('Diagnostics: ${diags.toString()}');
        }
      }

      final after = await widget.currencyService.getCurrentRates();
      if (after != null) {
        _addDebug(
          'After refresh base=${after.baseCurrency} fetchedAt=${after.fetchedAt.toIso8601String()} count=${after.rates.length}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'An error occurred while updating rates. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      await _loadCurrentRates();
      _addDebug('Refresh exception: $e');
    } finally {
      if (mounted) {
        setState(() => _isRefreshingRates = false);
      }
    }
  }

  String _formatLastUpdated(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Future<void> _saveCurrency() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;
      final currencyCode = formData['currency'] as String;

      try {
        final success = await widget.currencyService.setDisplayCurrency(
          currencyCode,
        );

        if (success) {
          // Refresh the display currency state
          widget.ref.invalidate(displayCurrencyFutureProvider);

          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Display currency changed to ${Currency.findByCode(currencyCode)?.name ?? currencyCode}. All amounts will now be shown in this currency.',
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to update display currency'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('An error occurred while updating currency'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardSurfaceColor(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.getBorderColor(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Display Currency',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getTextPrimaryColor(context),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: AppTheme.getTextPrimaryColor(context),
                      size: 24,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your preferred currency for displaying amounts. Exchange rates will be applied automatically.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.getTextSecondaryColor(context),
                ),
              ),
              const SizedBox(height: 24),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _SettingsGroup(
                        title: 'Currency Preference',
                        children: [
                          Container(
                            padding: context.responsivePadding,
                            child: FormBuilder(
                              key: _formKey,
                              child: Column(
                                children: [
                                  FormBuilderDropdown<String>(
                                    name: 'currency',
                                    initialValue:
                                        _profile?.currencyCode ?? 'USD',
                                    key: ValueKey(
                                      _profile?.currencyCode ?? 'USD',
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Display Currency',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: FormBuilderValidators.required(),
                                    items: Currency.allCurrencies.map((
                                      currency,
                                    ) {
                                      return DropdownMenuItem<String>(
                                        value: currency.code,
                                        child: Row(
                                          children: [
                                            Text(
                                              currency.flag,
                                              style: TextStyle(fontSize: 20),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              '${currency.name} (${currency.code})',
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedCurrency = Currency.findByCode(
                                          value ?? 'USD',
                                        );
                                      });
                                    },
                                  ),
                                  if (_selectedCurrency != null) ...[
                                    SizedBox(
                                      height: context.responsiveHeight(2),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            _selectedCurrency!.flag,
                                            style: TextStyle(fontSize: 24),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _selectedCurrency!.name,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppTheme.getTextPrimaryColor(
                                                          context,
                                                        ),
                                                  ),
                                                ),
                                                Text(
                                                  'Symbol: ${_selectedCurrency!.symbol}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        AppTheme.getTextSecondaryColor(
                                                          context,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Exchange Rates Section
                      _SettingsGroup(
                        title: 'Exchange Rates',
                        children: [
                          Container(
                            padding: context.responsivePadding,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Latest Rates',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.getTextPrimaryColor(
                                          context,
                                        ),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: _isRefreshingRates
                                          ? null
                                          : _refreshRates,
                                      icon: _isRefreshingRates
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Icon(
                                              Icons.refresh,
                                              size: 16,
                                              color:
                                                  AppTheme.getTextSecondaryColor(
                                                    context,
                                                  ),
                                            ),
                                      label: Text(
                                        _isRefreshingRates
                                            ? 'Updating...'
                                            : 'Refresh',
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            AppTheme.getTextSecondaryColor(
                                              context,
                                            ),
                                        textStyle: TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_lastUpdated != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Last updated: $_lastUpdated',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.getTextSecondaryColor(
                                        context,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                ValueListenableBuilder<FxRates?>(
                                  valueListenable: _currentRatesNotifier,
                                  builder: (context, fxRates, _) {
                                    if (fxRates == null) {
                                      return Text(
                                        'Exchange rates are automatically fetched and cached for offline use.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.getTextSecondaryColor(
                                            context,
                                          ),
                                        ),
                                      );
                                    }

                                    final sampleRates = fxRates.rates.entries
                                        .where(
                                          (entry) =>
                                              entry.key != fxRates.baseCurrency,
                                        )
                                        .take(4)
                                        .toList();

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.currency_exchange,
                                              size: 14,
                                              color:
                                                  AppTheme.getTextSecondaryColor(
                                                    context,
                                                  ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Live rates',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    AppTheme.getTextPrimaryColor(
                                                      context,
                                                    ),
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '${sampleRates.length} of ${fxRates.rates.length}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color:
                                                    AppTheme.getTextSecondaryColor(
                                                      context,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: sampleRates.map((entry) {
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    AppTheme.getCardSurfaceColor(
                                                      context,
                                                    ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color:
                                                      AppTheme.getBorderColor(
                                                        context,
                                                      ),
                                                  width: 0.5,
                                                ),
                                              ),
                                              child: RichText(
                                                text: TextSpan(
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                        AppTheme.getTextSecondaryColor(
                                                          context,
                                                        ),
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text: entry.key,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            AppTheme.getTextPrimaryColor(
                                                              context,
                                                            ),
                                                      ),
                                                    ),
                                                    const TextSpan(text: ' '),
                                                    TextSpan(
                                                      text: entry.value
                                                          .toStringAsFixed(3),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                        if (sampleRates.isEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.orange
                                                    .withValues(alpha: 0.3),
                                                width: 0.5,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.warning_amber_rounded,
                                                  size: 16,
                                                  color: Colors.orange,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'No rates available. Try refreshing.',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        Colors.orange.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        // Debug information only shown in debug mode
                                        if (_debugLines.isNotEmpty && !AppConfig.isProduction) ...[
                                          const SizedBox(height: 12),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color:
                                                  AppTheme.getCardSurfaceColor(
                                                    context,
                                                  ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: AppTheme.getBorderColor(
                                                  context,
                                                ),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Debug',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppTheme.getTextPrimaryColor(
                                                          context,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                for (final line
                                                    in _debugLines.take(6))
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 2,
                                                        ),
                                                    child: Text(
                                                      line,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            AppTheme.getTextSecondaryColor(
                                                              context,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: AppTheme.getBorderColor(context),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 17,
                          color: AppTheme.getTextSecondaryColor(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _PrimaryButton(
                      label: 'Save',
                      onPressed: _saveCurrency,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetInputField extends StatelessWidget {
  final String name;
  final String label;
  final String? initialValue;
  final String? placeholder;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final int maxLines;

  const _SheetInputField({
    required this.name,
    required this.label,
    this.initialValue,
    this.placeholder,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: name,
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label.isEmpty ? null : label,
        hintText: placeholder,
        hintStyle: TextStyle(
          color: AppTheme.getTextSecondaryColor(context).withValues(alpha: 0.6),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.getBackgroundColor(context),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }
}

class _AboutSheet extends StatelessWidget {
  const _AboutSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardSurfaceColor(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.getBorderColor(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'About',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getTextPrimaryColor(context),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: AppTheme.getTextPrimaryColor(context),
                      size: 24,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // About Content
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // App Information Section
                      _SettingsGroup(
                        title: 'App Information',
                        children: [
                          _SettingItem(
                            icon: Icons.person_outline,
                            title: 'Developer',
                            subtitle: 'Hashim Hameem',
                            onTap: () {},
                          ),
                          _SettingItem(
                            icon: Icons.info_outline,
                            title: 'Version',
                            subtitle: '1.0.0',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpSheet extends StatelessWidget {
  const _HelpSheet();

  Future<void> _launchEmail(BuildContext context) async {
    const String email = 'scnz141@gmail.com';
    const String subject = 'Invoice App Support';
    const String body = 'Hi Hashim,\n\nI need help with the Invoice App...\n\n';

    try {
      // Create the mailto URI
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: email,
        queryParameters: {'subject': subject, 'body': body},
      );

      // Try to launch the email URI with error handling
      try {
        if (await launcher.canLaunchUrl(emailUri)) {
          await launcher.launchUrl(
            emailUri,
            mode: launcher.LaunchMode.externalApplication,
          );
          return;
        }
      } catch (e) {
        // If mailto fails, continue to fallback
        debugPrint('Mailto launch failed: $e');
      }

      // Fallback: Try Gmail web interface
      try {
        final Uri gmailUri = Uri.parse(
          'https://mail.google.com/mail/?view=cm&to=$email&su=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
        );
        if (await launcher.canLaunchUrl(gmailUri)) {
          await launcher.launchUrl(
            gmailUri,
            mode: launcher.LaunchMode.externalApplication,
          );
          return;
        }
      } catch (e) {
        // If Gmail web fails, continue to clipboard fallback
        debugPrint('Gmail web launch failed: $e');
      }

      // Final fallback: Copy email to clipboard
      await Clipboard.setData(const ClipboardData(text: email));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Email address copied to clipboard: scnz141@gmail.com',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Last resort: Show manual email instruction
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please email scnz141@gmail.com manually'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardSurfaceColor(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.getBorderColor(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Help & Support',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getTextPrimaryColor(context),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: AppTheme.getTextPrimaryColor(context),
                      size: 24,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Help Content
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Contact Support Section
                      _SettingsGroup(
                        title: 'Contact Support',
                        children: [
                          _SettingItem(
                            icon: Icons.email_outlined,
                            title: 'Email Support',
                            subtitle: 'scnz141@gmail.com',
                            onTap: () => _launchEmail(context),
                          ),
                          _SettingItem(
                            icon: Icons.access_time_outlined,
                            title: 'Response Time',
                            subtitle: 'Usually within 24 hours',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
