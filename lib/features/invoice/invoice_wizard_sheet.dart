import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';

import '../../app/themes/app_theme.dart';
import '../../core/models/client.dart';
import '../../core/models/invoice.dart';
import '../../core/services/client_repository.dart';
import '../../core/services/invoice_repository.dart';
import '../../core/services/merchant_repository.dart';

// Invoice Creation Data Provider
final invoiceCreationProvider = NotifierProvider<InvoiceCreationNotifier, InvoiceCreationData>(() {
  return InvoiceCreationNotifier();
});

class InvoiceCreationData {
  final Invoice? existing;
  final String? clientId;
  final DateTime? date;
  final DateTime? dueDate;
  final String? currencyCode;
  final List<InvoiceItemData> items;
  final String? notes;
  final String? terms;

  InvoiceCreationData({
    this.existing,
    this.clientId,
    this.date,
    this.dueDate,
    this.currencyCode,
    List<InvoiceItemData>? items,
    this.notes,
    this.terms,
  }) : items = items ?? [InvoiceItemData()];

  InvoiceCreationData copyWith({
    Invoice? existing,
    String? clientId,
    DateTime? date,
    DateTime? dueDate,
    String? currencyCode,
    List<InvoiceItemData>? items,
    String? notes,
    String? terms,
  }) {
    return InvoiceCreationData(
      existing: existing ?? this.existing,
      clientId: clientId ?? this.clientId,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      currencyCode: currencyCode ?? this.currencyCode,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
    );
  }
}

class InvoiceCreationNotifier extends Notifier<InvoiceCreationData> {
  @override
  InvoiceCreationData build() {
    return InvoiceCreationData(
      date: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 30)),
      currencyCode: 'USD',
    );
  }

  void initialize(Invoice? existing) {
    if (existing != null) {
      state = InvoiceCreationData(
        existing: existing,
        clientId: existing.client.id,
        date: existing.date,
        dueDate: existing.dueDate,
        currencyCode: existing.currencyCode,
        items: existing.items.map((item) => InvoiceItemData.fromInvoiceItem(item)).toList(),
        notes: existing.notes,
        terms: existing.terms,
      );
    } else {
      state = InvoiceCreationData(
        date: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 30)),
        currencyCode: 'USD',
      );
    }
  }

  void updateClient(String clientId) {
    state = state.copyWith(clientId: clientId);
  }

  void updateDates(DateTime date, DateTime dueDate) {
    state = state.copyWith(date: date, dueDate: dueDate);
  }

  void updateCurrency(String currencyCode) {
    state = state.copyWith(currencyCode: currencyCode);
  }

  void updateItems(List<InvoiceItemData> items) {
    state = state.copyWith(items: items);
  }

  void updateNotes(String? notes, String? terms) {
    state = state.copyWith(notes: notes, terms: terms);
  }

  double getTotal() {
    double total = 0;
    for (final item in state.items) {
      total += item.lineTotal;
    }
    return total;
  }

  void reset() {
    state = InvoiceCreationData(
      date: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 30)),
      currencyCode: 'USD',
    );
  }
}

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
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.getTextPrimaryColor(context),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.getCardSurfaceColor(context),
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
                    Divider(
                      height: 1,
                      indent: 52,
                      color: AppTheme.getBorderColor(context),
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 17,
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
  final Function(String?)? onChanged;

  const _SheetInputField({
    required this.name,
    required this.label,
    this.initialValue,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
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
      onChanged: onChanged,
    );
  }
}

// Main Invoice Creation Screen
class InvoiceCreationScreen extends ConsumerStatefulWidget {
  const InvoiceCreationScreen({super.key, this.existing, this.existingId});

  final Invoice? existing;
  final String? existingId;

  @override
  ConsumerState<InvoiceCreationScreen> createState() => _InvoiceCreationScreenState();
}

class _InvoiceCreationScreenState extends ConsumerState<InvoiceCreationScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    // Initialize the creation data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.existing != null) {
        ref.read(invoiceCreationProvider.notifier).initialize(widget.existing);
      } else if (widget.existingId != null) {
        // Load invoice by ID
        final invRepo = ref.read(invoiceRepositoryProvider);
        final invoice = await invRepo.getById(widget.existingId!);
        if (invoice != null) {
          ref.read(invoiceCreationProvider.notifier).initialize(invoice);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientRepositoryProvider).getAll();

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          widget.existing != null ? 'Edit Invoice' : 'Create Invoice',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppTheme.getTextPrimaryColor(context),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppTheme.getTextPrimaryColor(context), size: 24),
          onPressed: () => context.go('/invoices'),
        ),
      ),
      body: FutureBuilder<List<Client>>(
        future: clientsAsync,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final clients = snapshot.data!;
          final creationData = ref.watch(invoiceCreationProvider);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
              children: [
                // Client & Invoice Details Section
                _SettingsGroup(
                  title: 'Invoice Details',
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: FormBuilder(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Client Selection
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.getCardSurfaceColor(context),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.getBorderColor(context)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Client',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.getBorderColor(context),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  FormBuilderDropdown<String>(
                                    name: 'clientId',
                                    initialValue: creationData.clientId,
                                    decoration: InputDecoration(
                                      hintText: 'Select a client',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    items: clients.map((c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(c.name),
                                    )).toList(),
                                    validator: FormBuilderValidators.required(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        ref.read(invoiceCreationProvider.notifier).updateClient(value);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Date Fields
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.getCardSurfaceColor(context),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppTheme.getBorderColor(context)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Invoice Date',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppTheme.getBorderColor(context),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        FormBuilderDateTimePicker(
                                          name: 'date',
                                          initialValue: creationData.date,
                                          inputType: InputType.date,
                                          decoration: InputDecoration(
                                            hintText: 'Select date',
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          validator: FormBuilderValidators.required(),
                                          onChanged: (value) {
                                            if (value != null && creationData.dueDate != null) {
                                              ref.read(invoiceCreationProvider.notifier).updateDates(value, creationData.dueDate!);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.getCardSurfaceColor(context),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppTheme.getBorderColor(context)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Due Date',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppTheme.getBorderColor(context),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        FormBuilderDateTimePicker(
                                          name: 'dueDate',
                                          initialValue: creationData.dueDate,
                                          inputType: InputType.date,
                                          decoration: InputDecoration(
                                            hintText: 'Select due date',
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          validator: FormBuilderValidators.required(),
                                          onChanged: (value) {
                                            if (value != null && creationData.date != null) {
                                              ref.read(invoiceCreationProvider.notifier).updateDates(creationData.date!, value);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Currency
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.getCardSurfaceColor(context),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.getBorderColor(context)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Currency',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.getBorderColor(context),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  FormBuilderTextField(
                                    name: 'currencyCode',
                                    initialValue: creationData.currencyCode,
                                    decoration: InputDecoration(
                                      hintText: 'Enter currency code (e.g., USD, EUR)',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onChanged: (value) {
                                      if (value != null) {
                                        ref.read(invoiceCreationProvider.notifier).updateCurrency(value);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Navigation Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).maybePop();
                          } else {
                            context.go('/invoices');
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: AppTheme.getBorderColor(context)),
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
                        label: 'Next: Add Items',
                        onPressed: () {
                          if (_formKey.currentState?.saveAndValidate() ?? false) {
                            context.go('/invoice/items');
                          }
                        },
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
        },
      ),
    );
  }
}

// Invoice Items Screen
class InvoiceItemsScreen extends ConsumerStatefulWidget {
  const InvoiceItemsScreen({super.key});

  @override
  ConsumerState<InvoiceItemsScreen> createState() => _InvoiceItemsScreenState();
}

class _InvoiceItemsScreenState extends ConsumerState<InvoiceItemsScreen> {
  @override
  Widget build(BuildContext context) {
    final creationData = ref.watch(invoiceCreationProvider);
    final notifier = ref.read(invoiceCreationProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          'Add Items',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppTheme.getTextPrimaryColor(context),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.getTextPrimaryColor(context), size: 24),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).maybePop();
            } else {
              context.go('/invoice/create');
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                children: [
                  // Items Section
                  _SettingsGroup(
                    title: 'Invoice Items',
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Items List
                            ...creationData.items.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return _ItemCard(
                                key: ValueKey('item_$index'),
                                index: index,
                                item: item,
                                onChanged: (updatedItem) {
                                  final updatedItems = List<InvoiceItemData>.from(creationData.items);
                                  updatedItems[index] = updatedItem;
                                  notifier.updateItems(updatedItems);
                                  setState(() {});
                                },
                                onRemove: creationData.items.length > 1 ? () {
                                  final updatedItems = List<InvoiceItemData>.from(creationData.items)..removeAt(index);
                                  notifier.updateItems(updatedItems);
                                  setState(() {});
                                } : null,
                              );
                            }),

                            // Add Item Button
                            Container(
                              margin: const EdgeInsets.only(top: 16),
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  final updatedItems = List<InvoiceItemData>.from(creationData.items)..add(InvoiceItemData());
                                  notifier.updateItems(updatedItems);
                                  setState(() {});
                                },
                                icon: Icon(Icons.add, color: AppTheme.getTextPrimaryColor(context)),
                                label: Text(
                                  'Add Another Item',
                                  style: TextStyle(color: AppTheme.getTextPrimaryColor(context), fontWeight: FontWeight.w600),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppTheme.getBorderColor(context)),
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Total Summary
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.getCardSurfaceColor(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.getBorderColor(context)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.getTextPrimaryColor(context),
                          ),
                        ),
                        Text(
                          '${creationData.currencyCode ?? 'USD'} ${ref.read(invoiceCreationProvider.notifier).getTotal().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.getTextPrimaryColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Navigation Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.go('/invoice/create'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: AppTheme.getBorderColor(context)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Back',
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
                          label: 'Next: Review',
                          onPressed: () {
                            if (creationData.items.isNotEmpty && creationData.items.any((item) => item.description.isNotEmpty)) {
                              context.go('/invoice/review');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please add at least one item with a description'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 80),
                ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Item Card Widget
class _ItemCard extends StatefulWidget {
  final int index;
  final InvoiceItemData item;
  final Function(InvoiceItemData) onChanged;
  final VoidCallback? onRemove;

  const _ItemCard({
    super.key,
    required this.index,
    required this.item,
    required this.onChanged,
    this.onRemove,
  });

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.getCardSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with item number and delete button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.getTextSecondaryColor(context).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: AppTheme.getTextSecondaryColor(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Item ${widget.index + 1}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextPrimaryColor(context),
                      ),
                    ),
                  ],
                ),
                if (widget.onRemove != null)
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444)),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.08),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Product/Service Description
            _SheetInputField(
              name: 'item${widget.index}_desc',
              label: 'Product/Service Description',
              initialValue: widget.item.description,
              validator: FormBuilderValidators.required(),
              onChanged: (value) {
                if (value != null) {
                  final updatedItem = InvoiceItemData()
                    ..description = value
                    ..quantity = widget.item.quantity
                    ..rate = widget.item.rate
                    ..taxPercent = widget.item.taxPercent
                    ..discountValue = widget.item.discountValue
                    ..discountIsPercent = widget.item.discountIsPercent;
                  widget.onChanged(updatedItem);
                }
              },
            ),

            const SizedBox(height: 16),

            // Quantity and Rate
            Row(
              children: [
                Expanded(
                  child: _SheetInputField(
                    name: 'item${widget.index}_qty',
                    label: 'Quantity',
                    initialValue: widget.item.quantity.toString(),
                    keyboardType: TextInputType.number,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      FormBuilderValidators.numeric(),
                    ]),
                        onChanged: (value) {
                          if (value != null) {
                            final updatedItem = InvoiceItemData()
                              ..description = widget.item.description
                              ..quantity = double.tryParse(value) ?? 1.0
                              ..rate = widget.item.rate
                              ..taxPercent = widget.item.taxPercent
                              ..discountValue = widget.item.discountValue
                              ..discountIsPercent = widget.item.discountIsPercent;
                            widget.onChanged(updatedItem);
                          }
                        },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SheetInputField(
                    name: 'item${widget.index}_rate',
                    label: 'Unit Price',
                    initialValue: widget.item.rate.toString(),
                    keyboardType: TextInputType.number,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      FormBuilderValidators.numeric(),
                    ]),
                        onChanged: (value) {
                          if (value != null) {
                            final updatedItem = InvoiceItemData()
                              ..description = widget.item.description
                              ..quantity = widget.item.quantity
                              ..rate = double.tryParse(value) ?? 0.0
                              ..taxPercent = widget.item.taxPercent
                              ..discountValue = widget.item.discountValue
                              ..discountIsPercent = widget.item.discountIsPercent;
                            widget.onChanged(updatedItem);
                          }
                        },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Tax and Discount
            Row(
              children: [
                Expanded(
                  child: _SheetInputField(
                    name: 'item${widget.index}_tax',
                    label: 'Tax Rate (%)',
                    initialValue: widget.item.taxPercent.toString(),
                    keyboardType: TextInputType.number,
                  onChanged: (value) {
                    if (value != null) {
                      final updatedItem = InvoiceItemData()
                        ..description = widget.item.description
                        ..quantity = widget.item.quantity
                        ..rate = widget.item.rate
                        ..taxPercent = double.tryParse(value) ?? 0.0
                        ..discountValue = widget.item.discountValue
                        ..discountIsPercent = widget.item.discountIsPercent;
                      widget.onChanged(updatedItem);
                    }
                  },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SheetInputField(
                    name: 'item${widget.index}_discount',
                    label: 'Discount',
                    initialValue: widget.item.discountValue.toString(),
                    keyboardType: TextInputType.number,
                        onChanged: (value) {
                          if (value != null) {
                            final updatedItem = InvoiceItemData()
                              ..description = widget.item.description
                              ..quantity = widget.item.quantity
                              ..rate = widget.item.rate
                              ..taxPercent = widget.item.taxPercent
                              ..discountValue = double.tryParse(value) ?? 0.0
                              ..discountIsPercent = widget.item.discountIsPercent;
                            widget.onChanged(updatedItem);
                          }
                        },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Discount type toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.getCardSurfaceColor(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    'Discount Type:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.getTextSecondaryColor(context),
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: widget.item.discountIsPercent,
                    onChanged: (value) {
                      final updatedItem = InvoiceItemData()
                        ..description = widget.item.description
                        ..quantity = widget.item.quantity
                        ..rate = widget.item.rate
                        ..taxPercent = widget.item.taxPercent
                        ..discountValue = widget.item.discountValue
                        ..discountIsPercent = value;
                      widget.onChanged(updatedItem);
                    },
                    activeThumbColor: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.item.discountIsPercent ? 'Percentage' : 'Fixed Amount',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.getTextSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Line Total
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.getCardSurfaceColor(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Line Total:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextPrimaryColor(context),
                    ),
                  ),
                  Text(
                    widget.item.lineTotal.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getTextPrimaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Invoice Review Screen
class InvoiceReviewScreen extends ConsumerStatefulWidget {
  const InvoiceReviewScreen({super.key});

  @override
  ConsumerState<InvoiceReviewScreen> createState() => _InvoiceReviewScreenState();
}

class _InvoiceReviewScreenState extends ConsumerState<InvoiceReviewScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  // Simple ID generator to replace uuid package
  String _generateId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        16, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  @override
  Widget build(BuildContext context) {
    final creationData = ref.watch(invoiceCreationProvider);
    final clientsAsync = ref.watch(clientRepositoryProvider).getAll();

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          'Review & Create',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppTheme.getTextPrimaryColor(context),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.getTextPrimaryColor(context), size: 24),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).maybePop();
            } else {
              context.go('/invoice/items');
            }
          },
        ),
      ),
      body: FutureBuilder<List<Client>>(
        future: clientsAsync,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final clients = snapshot.data!;
          final selectedClient = clients.firstWhere(
            (c) => c.id == creationData.clientId,
            orElse: () => Client(id: '', name: 'Unknown Client', email: null, phone: null, address: null, company: null),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
              children: [
                // Invoice Summary
                _SettingsGroup(
                  title: 'Invoice Summary',
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Invoice Number & Date
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Invoice #',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.getTextSecondaryColor(context),
                                ),
                              ),
                              Text(
                                creationData.existing?.invoiceNumber ?? 'Auto-generated',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.getTextPrimaryColor(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Date',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.getTextSecondaryColor(context),
                                ),
                              ),
                              Text(
                                '${creationData.date?.month}/${creationData.date?.day}/${creationData.date?.year}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.getTextPrimaryColor(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Due Date',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.getTextSecondaryColor(context),
                                ),
                              ),
                              Text(
                                '${creationData.dueDate?.month}/${creationData.dueDate?.day}/${creationData.dueDate?.year}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.getTextPrimaryColor(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Client Details
                _SettingsGroup(
                  title: 'Client Details',
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedClient.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getTextPrimaryColor(context),
                            ),
                          ),
                          if (selectedClient.company != null && selectedClient.company!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              selectedClient.company!,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.getTextSecondaryColor(context),
                              ),
                            ),
                          ],
                          if (selectedClient.email != null && selectedClient.email!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              selectedClient.email!,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.getTextSecondaryColor(context),
                              ),
                            ),
                          ],
                          if (selectedClient.phone != null && selectedClient.phone!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              selectedClient.phone!,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.getTextSecondaryColor(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Items Summary
                _SettingsGroup(
                  title: 'Items',
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: creationData.items.map((item) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.getCardSurfaceColor(context),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.description,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.getTextPrimaryColor(context),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Qty: ${item.quantity} × ${creationData.currencyCode ?? 'USD'} ${item.rate.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.getTextSecondaryColor(context),
                                      ),
                                    ),
                                    if (item.discountValue > 0) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Discount: ${item.discountValue}${item.discountIsPercent ? '%' : ' ${creationData.currencyCode ?? 'USD'}'}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.getTextSecondaryColor(context),
                                        ),
                                      ),
                                    ],
                                    if (item.taxPercent > 0) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Tax: ${item.taxPercent}%',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.getTextSecondaryColor(context),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Text(
                                '${creationData.currencyCode ?? 'USD'} ${item.lineTotal.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.getTextPrimaryColor(context),
                                  ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Notes & Terms
                _SettingsGroup(
                  title: 'Additional Information',
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: FormBuilder(
                        key: _formKey,
                        child: Column(
                          children: [
                            _SheetInputField(
                              name: 'notes',
                              label: 'Notes',
                              initialValue: creationData.notes,
                              maxLines: 3,
                              onChanged: (value) {
                                ref.read(invoiceCreationProvider.notifier).updateNotes(value, creationData.terms);
                              },
                            ),
                            const SizedBox(height: 16),
                            _SheetInputField(
                              name: 'terms',
                              label: 'Terms & Conditions',
                              initialValue: creationData.terms,
                              maxLines: 3,
                              onChanged: (value) {
                                ref.read(invoiceCreationProvider.notifier).updateNotes(creationData.notes, value);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Total Summary
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.getCardSurfaceColor(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.getBorderColor(context)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getTextPrimaryColor(context),
                        ),
                      ),
                      Text(
                        '${creationData.currencyCode ?? 'USD'} ${ref.read(invoiceCreationProvider.notifier).getTotal().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.getTextPrimaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Navigation Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.go('/invoice/items'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: AppTheme.getBorderColor(context)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Back',
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
                        label: creationData.existing != null ? 'Update Invoice' : 'Create Invoice',
                        onPressed: () => _createInvoice(context, ref, clients),
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
        },
      ),
    );
  }

  Future<void> _createInvoice(BuildContext context, WidgetRef ref, List<Client> clients) async {
    final creationData = ref.read(invoiceCreationProvider);
    final client = clients.firstWhere((c) => c.id == creationData.clientId);

    final invRepo = ref.read(invoiceRepositoryProvider);
    final merchRepo = ref.read(merchantRepositoryProvider);

    final items = creationData.items.map((item) => InvoiceItem(
      productId: '',
      description: item.description,
      quantity: item.quantity,
      rate: item.rate,
      taxPercent: item.taxPercent,
      discountValue: item.discountValue,
      discountIsPercent: item.discountIsPercent,
    )).toList();

    final invoice = Invoice(
      id: creationData.existing?.id ?? _generateId(),
      invoiceNumber: creationData.existing?.invoiceNumber ?? await merchRepo.generateNextInvoiceNumber(),
      date: creationData.date!,
      dueDate: creationData.dueDate!,
      client: client,
      items: items,
      status: creationData.existing?.status ?? InvoiceStatus.draft,
      notes: creationData.notes,
      terms: creationData.terms,
      currencyCode: creationData.currencyCode,
    );

    await invRepo.upsert(invoice);

    // Reset the creation data
    ref.read(invoiceCreationProvider.notifier).reset();

    if (!context.mounted) return;

    context.go('/invoices');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(creationData.existing != null ? 'Invoice updated successfully' : 'Invoice created successfully'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// Old Wizard Sheet - Keep for backwards compatibility
class InvoiceWizardSheet extends ConsumerStatefulWidget {
  const InvoiceWizardSheet({super.key, this.existing});
  final Invoice? existing;

  @override
  ConsumerState<InvoiceWizardSheet> createState() => _InvoiceWizardSheetState();
}

class _InvoiceWizardSheetState extends ConsumerState<InvoiceWizardSheet> {
  @override
  Widget build(BuildContext context) {
    // Redirect to new screen-based flow
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.existing != null) {
        context.go('/invoice/edit/${widget.existing!.id}');
      } else {
        context.go('/invoice/create');
      }
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

// Invoice Item Data Class
class InvoiceItemData {
  String description = '';
  double quantity = 1.0;
  double rate = 0.0;
  double taxPercent = 0.0;
  double discountValue = 0.0;
  bool discountIsPercent = true;

  InvoiceItemData();

  InvoiceItemData.fromInvoiceItem(InvoiceItem item) {
    description = item.description;
    quantity = item.quantity;
    rate = item.rate;
    taxPercent = item.taxPercent;
    discountValue = item.discountValue;
    discountIsPercent = item.discountIsPercent;
  }

  double get lineSubtotal => quantity * rate;
  double get discountAmount => discountIsPercent ? lineSubtotal * (discountValue / 100) : discountValue;
  double get taxable => (lineSubtotal - discountAmount).clamp(0, double.infinity);
  double get taxAmount => taxable * (taxPercent / 100);
  double get lineTotal => taxable + taxAmount;
}