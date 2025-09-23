import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/merchant_repository.dart';
import '../../core/models/merchant.dart';
import '../../app/themes/app_theme.dart';
import '../../core/utils/responsive_utils.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(merchantRepositoryProvider);
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          'Welcome to InvoiceApp',
          style: TextStyle(
            fontSize: context.responsiveFontSize(17),
            fontWeight: FontWeight.w600,
            color: AppTheme.getTextPrimaryColor(context),
          ),
        ),
        backgroundColor: AppTheme.getCardSurfaceColor(context),
        elevation: 0,
        iconTheme: IconThemeData(
          color: AppTheme.getTextPrimaryColor(context),
        ),
      ),
      body: SafeArea(
        child: FormBuilder(
          key: _formKey,
          child: SingleChildScrollView(
            padding: context.responsivePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Header
                Container(
                  width: double.infinity,
                  padding: context.responsivePadding,
                  decoration: BoxDecoration(
                    color: AppTheme.getCardSurfaceColor(context),
                    borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/logo/applogo.png',
                        width: context.responsiveIconSize(mobile: 32, tablet: 40, desktop: 48),
                        height: context.responsiveIconSize(mobile: 32, tablet: 40, desktop: 48),
                        color: AppTheme.getTextPrimaryColor(context),
                      ),
                      SizedBox(height: context.responsiveHeight(1.5)),
                      Text(
                        'Let\'s set up your business',
                        style: TextStyle(
                          fontSize: context.responsiveFontSize(24),
                          fontWeight: FontWeight.w700,
                          color: AppTheme.getTextPrimaryColor(context),
                        ),
                      ),
                      SizedBox(height: context.responsiveHeight(0.5)),
                      Text(
                        'You can change these anytime in Settings',
                        style: TextStyle(
                          fontSize: context.responsiveFontSize(15),
                          color: AppTheme.getTextSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.responsiveHeight(3)),

                // Business Information Section
                _OnboardingGroup(
                  title: 'Business Information',
                  children: [
                    FormBuilderTextField(
                      name: 'businessName',
                      decoration: InputDecoration(
                        labelText: 'Business Name',
                        labelStyle: TextStyle(
                          color: AppTheme.getTextSecondaryColor(context),
                          fontSize: context.responsiveFontSize(15),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
                          borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
                          borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
                          borderSide: BorderSide(color: AppTheme.getTextPrimaryColor(context)),
                        ),
                        filled: true,
                        fillColor: AppTheme.getCardSurfaceColor(context),
                      ),
                      style: TextStyle(
                        color: AppTheme.getTextPrimaryColor(context),
                        fontSize: context.responsiveFontSize(17),
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.minLength(2),
                      ]),
                    ),
                    SizedBox(height: context.responsiveHeight(2)),
                    FormBuilderTextField(
                      name: 'email',
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(
                          color: AppTheme.getTextSecondaryColor(context),
                          fontSize: context.responsiveFontSize(15),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
                          borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
                          borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
                          borderSide: BorderSide(color: AppTheme.getTextPrimaryColor(context)),
                        ),
                        filled: true,
                        fillColor: AppTheme.getCardSurfaceColor(context),
                      ),
                      style: TextStyle(
                        color: AppTheme.getTextPrimaryColor(context),
                        fontSize: context.responsiveFontSize(17),
                      ),
                      validator: FormBuilderValidators.email(),
                    ),
                    SizedBox(height: context.responsiveHeight(2)),
                    FormBuilderTextField(
                      name: 'phone',
                      decoration: InputDecoration(
                        labelText: 'Phone',
                        labelStyle: TextStyle(
                          color: AppTheme.getTextSecondaryColor(context),
                          fontSize: context.responsiveFontSize(15),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
                          borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
                          borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
                          borderSide: BorderSide(color: AppTheme.getTextPrimaryColor(context)),
                        ),
                        filled: true,
                        fillColor: AppTheme.getCardSurfaceColor(context),
                      ),
                      style: TextStyle(
                        color: AppTheme.getTextPrimaryColor(context),
                        fontSize: context.responsiveFontSize(17),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: context.responsiveHeight(3)),

                // Additional Details Section
                _OnboardingGroup(
                  title: 'Additional Details',
                  children: [
                    FormBuilderTextField(
                      name: 'address',
                      decoration: InputDecoration(
                        labelText: 'Address',
                        labelStyle: TextStyle(
                          color: AppTheme.getTextSecondaryColor(context),
                          fontSize: context.responsiveFontSize(15),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
                          borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
                          borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
                          borderSide: BorderSide(color: AppTheme.getTextPrimaryColor(context)),
                        ),
                        filled: true,
                        fillColor: AppTheme.getCardSurfaceColor(context),
                      ),
                      style: TextStyle(
                        color: AppTheme.getTextPrimaryColor(context),
                        fontSize: context.responsiveFontSize(17),
                      ),
                    ),
                    SizedBox(height: context.responsiveHeight(2)),
                    FormBuilderTextField(
                      name: 'website',
                      decoration: InputDecoration(
                        labelText: 'Website',
                        labelStyle: TextStyle(
                          color: AppTheme.getTextSecondaryColor(context),
                          fontSize: context.responsiveFontSize(15),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
                          borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
                          borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
                          borderSide: BorderSide(color: AppTheme.getTextPrimaryColor(context)),
                        ),
                        filled: true,
                        fillColor: AppTheme.getCardSurfaceColor(context),
                      ),
                      style: TextStyle(
                        color: AppTheme.getTextPrimaryColor(context),
                        fontSize: context.responsiveFontSize(17),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: context.responsiveHeight(3)),

                // Invoice Settings Section
                _OnboardingGroup(
                  title: 'Invoice Settings',
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'invoicePrefix',
                            initialValue: 'INV',
                            decoration: InputDecoration(
                              labelText: 'Invoice Prefix',
                              labelStyle: TextStyle(
                                color: AppTheme.getTextSecondaryColor(context),
                                fontSize: context.responsiveFontSize(15),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
                                borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
                                borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
                                borderSide: BorderSide(color: AppTheme.getTextPrimaryColor(context)),
                              ),
                              filled: true,
                              fillColor: AppTheme.getCardSurfaceColor(context),
                            ),
                            style: TextStyle(
                              color: AppTheme.getTextPrimaryColor(context),
                              fontSize: context.responsiveFontSize(17),
                            ),
                          ),
                        ),
                        SizedBox(width: context.responsiveWidth(3)),
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'nextInvoiceNumber',
                            initialValue: '1',
                            decoration: InputDecoration(
                              labelText: 'Starting Number',
                              labelStyle: TextStyle(
                                color: AppTheme.getTextSecondaryColor(context),
                                fontSize: context.responsiveFontSize(15),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
                                borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
                                borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
                                borderSide: BorderSide(color: AppTheme.getTextPrimaryColor(context)),
                              ),
                              filled: true,
                              fillColor: AppTheme.getCardSurfaceColor(context),
                            ),
                            style: TextStyle(
                              color: AppTheme.getTextPrimaryColor(context),
                              fontSize: context.responsiveFontSize(17),
                            ),
                            validator: FormBuilderValidators.integer(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: context.responsiveHeight(4)),

                // Continue Button
                Container(
                  width: double.infinity,
                  padding: context.responsivePadding,
                  child: ElevatedButton(
                    onPressed: () async {
                      final valid = _formKey.currentState?.saveAndValidate() ?? false;
                      if (!valid) return;
                      final v = _formKey.currentState!.value;
                      final profile = MerchantProfile(
                        businessName: v['businessName'],
                        email: v['email'],
                        phone: v['phone'],
                        address: v['address'],
                        website: v['website'],
                        taxId: v['taxId'] ?? '',
                        bankDetails: v['bankDetails'] ?? '',
                        invoicePrefix: v['invoicePrefix'] ?? 'INV',
                        nextInvoiceNumber: int.tryParse(v['nextInvoiceNumber'] ?? '1') ?? 1,
                      );
                      await repo.saveProfile(profile);
                      if (!mounted) return;
                      if (!context.mounted) return;
                      context.go('/dashboard');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.getTextPrimaryColor(context),
                      foregroundColor: AppTheme.getCardSurfaceColor(context),
                      padding: EdgeInsets.symmetric(vertical: context.responsiveHeight(1.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save & Continue',
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(17),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: context.responsiveHeight(4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Onboarding group widget - matches the settings page design
class _OnboardingGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _OnboardingGroup({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.getCardSurfaceColor(context),
        borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
      ),
      padding: context.responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: context.responsiveFontSize(22),
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextPrimaryColor(context),
            ),
          ),
          SizedBox(height: context.responsiveHeight(2)),
          ...children,
        ],
      ),
    );
  }
}


