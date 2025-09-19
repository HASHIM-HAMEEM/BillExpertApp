import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../core/models/merchant.dart';
import '../../core/models/fx_rates.dart';
import '../../core/services/merchant_repository.dart';
import '../../core/services/fx_rates_repository.dart';
import '../../core/services/theme_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _scrollController = ScrollController();
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final merchantRepo = ref.watch(merchantRepositoryProvider);
    final fxRepo = ref.watch(fxRatesRepositoryProvider);
    final themeController = ref.watch(themeControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // iOS-style background
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Premium Banner (matching the image)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Premium Membership',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Upgrade for more features',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

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
                  onTap: () => _showInvoicePreferencesSheet(context, merchantRepo),
                ),
                _SettingItem(
                  icon: Icons.palette_outlined,
                  title: 'Appearance',
                  onTap: () => _showAppearanceSheet(context, themeController),
                ),
                _SettingItem(
                  icon: Icons.currency_exchange_outlined,
                  title: 'Exchange Rates',
                  onTap: () => _showFxRatesSheet(context, fxRepo),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // More Section
            _SettingsGroup(
              title: 'More',
              children: [
                _SettingItem(
                  icon: Icons.star_outline,
                  title: 'Rate & Review',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Rate & Review coming soon')),
                    );
                  },
                ),
                _SettingItem(
                  icon: Icons.help_outline,
                  title: 'Help',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help coming soon')),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 80),
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

  void _showInvoicePreferencesSheet(BuildContext context, MerchantRepository repo) {
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

  void _showFxRatesSheet(BuildContext context, FxRatesRepository repo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FxRatesSheet(repository: repo),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: children.asMap().entries.map((entry) {
              final index = entry.key;
              final child = entry.value;
              return Column(
                children: [
                  child,
                  if (index < children.length - 1)
                    const Divider(
                      height: 1,
                      indent: 52,
                      color: Color(0xFFE5E5E7),
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
  final VoidCallback onTap;

  const _SettingItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: Colors.black87,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: Color(0xFF8E8E93),
              ),
            ],
          ),
        ),
      ),
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
      decoration: const BoxDecoration(
        color: Colors.white,
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
                  color: const Color(0xFFE5E5E7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 24),

              // Form
              Flexible(
                child: SingleChildScrollView(
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
                        const SizedBox(height: 16),
                        _SheetInputField(
                          name: 'email',
                          label: 'Email',
                          initialValue: _profile!.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: FormBuilderValidators.email(),
                        ),
                        const SizedBox(height: 16),
                        _SheetInputField(
                          name: 'phone',
                          label: 'Phone',
                          initialValue: _profile!.phone,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        _SheetInputField(
                          name: 'address',
                          label: 'Address',
                          initialValue: _profile!.address,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
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
  State<_InvoicePreferencesSheet> createState() => _InvoicePreferencesSheetState();
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
      decoration: const BoxDecoration(
        color: Colors.white,
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
                  color: const Color(0xFFE5E5E7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              const Text(
                'Invoice Preferences',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 24),

              // Form
              Flexible(
                child: SingleChildScrollView(
                  child: FormBuilder(
                    key: _formKey,
                    child: Column(
                      children: [
                        _SheetInputField(
                          name: 'invoicePrefix',
                          label: 'Invoice Number Prefix',
                          initialValue: _profile!.invoicePrefix,
                        ),
                        const SizedBox(height: 16),
                        _SheetInputField(
                          name: 'currencyCode',
                          label: 'Default Currency',
                          initialValue: _profile!.currencyCode,
                          validator: FormBuilderValidators.required(),
                        ),
                        const SizedBox(height: 16),
                        _SheetInputField(
                          name: 'defaultDueDays',
                          label: 'Default Due Days',
                          initialValue: _profile!.defaultDueDays?.toString(),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        _SheetInputField(
                          name: 'defaultTerms',
                          label: 'Default Terms',
                          initialValue: _profile!.defaultTerms,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        _SheetInputField(
                          name: 'defaultNotes',
                          label: 'Default Notes',
                          initialValue: _profile!.defaultNotes,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _savePreferences,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5E7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              const Text(
                'Appearance',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 24),

              // Theme options
              Consumer(
                builder: (context, ref, child) {
                  final currentTheme = ref.watch(themeControllerProvider);
                  
                  return Column(
                    children: [
                      _ThemeOption(
                        title: 'System',
                        subtitle: 'Follow device settings',
                        isSelected: currentTheme == AppThemeMode.system,
                        onTap: () => ref.read(themeControllerProvider.notifier).setTheme(AppThemeMode.system),
                      ),
                      const SizedBox(height: 12),
                      _ThemeOption(
                        title: 'Light',
                        subtitle: 'Always light theme',
                        isSelected: currentTheme == AppThemeMode.light,
                        onTap: () => ref.read(themeControllerProvider.notifier).setTheme(AppThemeMode.light),
                      ),
                      const SizedBox(height: 12),
                      _ThemeOption(
                        title: 'Dark',
                        subtitle: 'Always dark theme',
                        isSelected: currentTheme == AppThemeMode.dark,
                        onTap: () => ref.read(themeControllerProvider.notifier).setTheme(AppThemeMode.dark),
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 20),
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
            color: const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(12),
            border: isSelected 
              ? Border.all(color: const Color(0xFF6366F1), width: 2)
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
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF6366F1),
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
class _FxRatesSheet extends StatefulWidget {
  final FxRatesRepository repository;

  const _FxRatesSheet({required this.repository});

  @override
  State<_FxRatesSheet> createState() => _FxRatesSheetState();
}

class _FxRatesSheetState extends State<_FxRatesSheet> {
  final _formKey = GlobalKey<FormBuilderState>();
  FxRates? _fxRates;

  @override
  void initState() {
    super.initState();
    _loadFxRates();
  }

  Future<void> _loadFxRates() async {
    final rates = await widget.repository.getFxRates();
    setState(() => _fxRates = rates);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
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
                  color: const Color(0xFFE5E5E7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              const Text(
                'Exchange Rates',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 24),

              // Form
              Flexible(
                child: SingleChildScrollView(
                  child: FormBuilder(
                    key: _formKey,
                    child: Column(
                      children: [
                        _SheetInputField(
                          name: 'baseCurrency',
                          label: 'Base Currency',
                          initialValue: _fxRates?.baseCurrency ?? 'USD',
                          validator: FormBuilderValidators.required(),
                        ),
                        const SizedBox(height: 16),
                        _SheetInputField(
                          name: 'eurRate',
                          label: 'EUR Rate',
                          initialValue: _fxRates?.rates['EUR']?.toString() ?? '0.85',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        _SheetInputField(
                          name: 'gbpRate',
                          label: 'GBP Rate',
                          initialValue: _fxRates?.rates['GBP']?.toString() ?? '0.75',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveFxRates,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Future<void> _saveFxRates() async {
    final ok = _formKey.currentState?.saveAndValidate() ?? false;
    if (!ok) return;

    final v = _formKey.currentState!.value;
    final rates = FxRates(
      baseCurrency: v['baseCurrency'],
      rates: {
        'EUR': double.tryParse(v['eurRate'] ?? '0') ?? 0.0,
        'GBP': double.tryParse(v['gbpRate'] ?? '0') ?? 0.0,
      },
    );

    await widget.repository.saveFxRates(rates);
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exchange rates updated'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

class _SheetInputField extends StatelessWidget {
  final String name;
  final String label;
  final String? initialValue;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final int maxLines;

  const _SheetInputField({
    required this.name,
    required this.label,
    this.initialValue,
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
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E5E7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E5E7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF5F5F7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }
}
