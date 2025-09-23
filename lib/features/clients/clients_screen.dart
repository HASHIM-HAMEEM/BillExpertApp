import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'dart:math';

import '../../app/themes/app_theme.dart';
import '../../core/services/client_repository.dart';
import '../../core/models/client.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/widgets/enhanced_ad_widget.dart';

// Shared widgets from settings page design
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
          padding: EdgeInsets.only(left: context.responsiveWidth(4), bottom: context.responsiveHeight(1)),
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
            borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
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
          padding: EdgeInsets.symmetric(vertical: context.responsiveHeight(1.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: context.responsiveFontSize(17),
            fontWeight: FontWeight.w600,
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
          borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.getTextPrimaryColor(context), width: 2),
        ),
        filled: true,
        fillColor: AppTheme.getBackgroundColor(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }
}

class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  List<Widget> _buildClientListWithAds(BuildContext context, List<Client> clients, ClientRepository repo) {
    final List<Widget> widgets = [];
    const int adInterval = 3; // Show ad after every 3 clients

    for (int i = 0; i < clients.length; i++) {
      // Add client item
      widgets.add(
        _ClientItem(
          client: clients[i],
          onEdit: () => _showClientForm(context, repo, existing: clients[i]),
          onDelete: () => _showDeleteDialog(context, clients[i], repo),
        ),
      );

      // Add native ad after every adInterval clients (but not after the last one)
      if ((i + 1) % adInterval == 0 && i < clients.length - 1) {
        widgets.add(const AdSeparator());
        widgets.add(const EnhancedNativeAdWidget());
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(clientRepositoryProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context), // iOS-style background
      appBar: AppBar(
        title: Text(
          'Clients',
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.getTextPrimaryColor(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => _showClientForm(context, repo),
                icon: Icon(
                  Icons.add,
                  color: AppTheme.getCardSurfaceColor(context),
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Client>>(
        stream: repo.watchAll(),
        builder: (context, snapshot) {
          final clients = snapshot.data ?? const <Client>[];

          if (clients.isEmpty) {
            return _EmptyState(
              onAddClient: () => _showClientForm(context, repo),
            );
          }

          return SingleChildScrollView(
            padding: context.responsivePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Card
                Container(
                  width: double.infinity,
                  padding: context.responsivePadding,
                  decoration: BoxDecoration(
                    color: AppTheme.getCardSurfaceColor(context),
                    borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
                    border: Border.all(
                      color: AppTheme.getBorderColor(context),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        color: AppTheme.getTextSecondaryColor(context),
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${clients.length}',
                            style: TextStyle(
                              color: AppTheme.getTextPrimaryColor(context),
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            clients.length == 1 ? 'Client' : 'Clients',
                            style: TextStyle(
                              color: AppTheme.getTextSecondaryColor(context),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Clients List
                _SettingsGroup(
                  title: 'All Clients',
                  children: _buildClientListWithAds(context, clients, repo),
                ),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showClientForm(BuildContext context, ClientRepository repo, {Client? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AnimatedPadding(
        padding: MediaQuery.of(ctx).viewInsets + const EdgeInsets.only(top: 12),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: FractionallySizedBox(
          heightFactor: 0.92,
          child: _ClientFormSheet(
            repository: repo,
            existing: existing,
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Client client, ClientRepository repo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Client',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${client.name}?',
          style: TextStyle(fontSize: 17),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 17,
                color: AppTheme.getTextPrimaryColor(context),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await repo.delete(client.id);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Client deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete client: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(
                fontSize: 17,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddClient;

  const _EmptyState({required this.onAddClient});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.responsiveWidth(10)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(context.responsiveWidth(6)),
            decoration: BoxDecoration(
              color: AppTheme.getCardSurfaceColor(context),
              borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
              border: Border.all(
                color: AppTheme.getBorderColor(context),
              ),
            ),
            child: Image.asset(
              'assets/logo/applogo.png',
              width: context.responsiveIconSize(mobile: 36, tablet: 48, desktop: 60),
              height: context.responsiveIconSize(mobile: 36, tablet: 48, desktop: 60),
              color: AppTheme.getTextSecondaryColor(context),
            ),
          ),
          SizedBox(height: context.responsiveHeight(3)),
          Text(
            'No clients yet',
            style: TextStyle(
              fontSize: context.responsiveFontSize(24),
              fontWeight: FontWeight.w700,
              color: AppTheme.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first client to start creating invoices',
            style: TextStyle(
              fontSize: context.responsiveFontSize(17),
              color: AppTheme.getTextSecondaryColor(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: _PrimaryButton(
              label: 'Add Your First Client',
              onPressed: onAddClient,
            ),
          ),
        ],
      ),
    );
  }
}


class _ClientItem extends StatelessWidget {
  final Client client;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClientItem({
    required this.client,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
        child: Padding(
          padding: context.responsivePadding,
          child: Row(
            children: [
              // Icon
              Icon(
                Icons.person_outline_rounded,
                size: context.responsiveIconSize(),
                color: AppTheme.getTextSecondaryColor(context),
              ),

              SizedBox(width: context.responsiveWidth(4)),

              // Client info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(17),
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextPrimaryColor(context),
                      ),
                    ),
                    if (client.company != null && client.company!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        client.company!,
                        style: TextStyle(
                          fontSize: context.responsiveFontSize(15),
                          color: AppTheme.getTextSecondaryColor(context),
                        ),
                      ),
                    ],
                    if (client.email != null && client.email!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        client.email!,
                        style: TextStyle(
                          fontSize: context.responsiveFontSize(15),
                          color: AppTheme.getTextSecondaryColor(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // More button
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 20, color: AppTheme.getTextSecondaryColor(context)),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_forever_rounded, size: 20, color: const Color(0xFFEF4444)),
                        SizedBox(width: 12),
                        Text('Delete', style: TextStyle(color: const Color(0xFFEF4444))),
                      ],
                    ),
                  ),
                ],
                icon: Icon(
                  Icons.more_horiz,
                  color: AppTheme.getTextSecondaryColor(context),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientFormSheet extends StatefulWidget {
  final ClientRepository repository;
  final Client? existing;

  const _ClientFormSheet({
    required this.repository,
    this.existing,
  });

  @override
  State<_ClientFormSheet> createState() => _ClientFormSheetState();
}

class _ClientFormSheetState extends State<_ClientFormSheet> {
  // Simple ID generator to replace uuid package
  String _generateId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        16, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

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
                    isEditing ? 'Edit Client' : 'Add Client',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getTextPrimaryColor(context),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppTheme.getTextSecondaryColor(context), size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Form Content
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Client Information Section
                      _SettingsGroup(
                        title: 'Client Information',
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: FormBuilder(
                              key: _formKey,
                              child: Column(
                                children: [
                                  _SheetInputField(
                                    name: 'name',
                                    label: 'Full Name',
                                    initialValue: widget.existing?.name,
                                    validator: FormBuilderValidators.required(),
                                  ),
                                  const SizedBox(height: 16),
                                  _SheetInputField(
                                    name: 'email',
                                    label: 'Email Address',
                                    initialValue: widget.existing?.email,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: FormBuilderValidators.email(),
                                  ),
                                  const SizedBox(height: 16),
                                  _SheetInputField(
                                    name: 'phone',
                                    label: 'Phone Number',
                                    initialValue: widget.existing?.phone,
                                    keyboardType: TextInputType.phone,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Business Details Section
                      _SettingsGroup(
                        title: 'Business Details',
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _SheetInputField(
                                  name: 'company',
                                  label: 'Company Name',
                                  initialValue: widget.existing?.company,
                                ),
                                const SizedBox(height: 16),
                                _SheetInputField(
                                  name: 'address',
                                  label: 'Address',
                                  initialValue: widget.existing?.address,
                                  maxLines: 3,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: _PrimaryButton(
                          label: isEditing ? 'Update Client' : 'Add Client',
                          onPressed: _saveClient,
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

  Future<void> _saveClient() async {
    final ok = _formKey.currentState?.saveAndValidate() ?? false;
    if (!ok) return;

    final v = _formKey.currentState!.value;
    final id = widget.existing?.id ?? _generateId();

    final client = Client(
      id: id,
      name: v['name'],
      company: v['company']?.toString().trim().isEmpty == true ? null : v['company'],
      email: v['email']?.toString().trim().isEmpty == true ? null : v['email'],
      phone: v['phone']?.toString().trim().isEmpty == true ? null : v['phone'],
      address: v['address']?.toString().trim().isEmpty == true ? null : v['address'],
    );

    await widget.repository.upsert(client);
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existing != null ? 'Client updated' : 'Client added'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}
