import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/merchant_repository.dart';
import '../../core/models/merchant.dart';

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
      appBar: AppBar(title: const Text('Business Setup')),
      body: SafeArea(
        child: FormBuilder(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Let’s set up your business', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('You can change these anytime in Settings', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              FormBuilderTextField(
                name: 'businessName',
                decoration: const InputDecoration(labelText: 'Business name'),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.minLength(2),
                ]),
              ),
              const SizedBox(height: 12),
              FormBuilderTextField(name: 'email', decoration: const InputDecoration(labelText: 'Email'), validator: FormBuilderValidators.email()),
              const SizedBox(height: 12),
              FormBuilderTextField(name: 'phone', decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 12),
              FormBuilderTextField(name: 'address', decoration: const InputDecoration(labelText: 'Address')),
              const SizedBox(height: 12),
              FormBuilderTextField(name: 'website', decoration: const InputDecoration(labelText: 'Website')),
              const SizedBox(height: 12),
              FormBuilderTextField(name: 'taxId', decoration: const InputDecoration(labelText: 'Tax ID')),
              const SizedBox(height: 12),
              FormBuilderTextField(name: 'bankDetails', decoration: const InputDecoration(labelText: 'Bank details')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FormBuilderTextField(name: 'invoicePrefix', initialValue: 'INV', decoration: const InputDecoration(labelText: 'Invoice prefix')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FormBuilderTextField(
                      name: 'nextInvoiceNumber',
                      initialValue: '1',
                      decoration: const InputDecoration(labelText: 'Starting number'),
                      validator: FormBuilderValidators.integer(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
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
                    taxId: v['taxId'],
                    bankDetails: v['bankDetails'],
                    invoicePrefix: v['invoicePrefix'] ?? 'INV',
                    nextInvoiceNumber: int.tryParse(v['nextInvoiceNumber'] ?? '1') ?? 1,
                  );
                  await repo.saveProfile(profile);
                  if (!mounted) return;
                  context.go('/dashboard');
                },
                child: const Text('Save & Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


