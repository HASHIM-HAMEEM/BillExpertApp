import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/client.dart';
import '../../core/models/invoice.dart';
import '../../core/services/client_repository.dart';
import '../../core/services/invoice_repository.dart';
import '../../core/services/merchant_repository.dart';

class InvoiceWizardSheet extends ConsumerStatefulWidget {
  const InvoiceWizardSheet({super.key, this.existing});
  final Invoice? existing;

  @override
  ConsumerState<InvoiceWizardSheet> createState() => _InvoiceWizardSheetState();
}

class _InvoiceWizardSheetState extends ConsumerState<InvoiceWizardSheet> {
  final _formKey = GlobalKey<FormBuilderState>();
  int _step = 0;
  double _runningTotal = 0;
  final List<InvoiceItemData> _items = [InvoiceItemData()];

  void _recomputeTotals() {
    double total = 0;
    for (final item in _items) {
      final qty = item.quantity;
      final rate = item.rate;
      final disc = item.discountValue;
      final discPct = item.discountIsPercent;
      final tax = item.taxPercent;
      
      final subtotal = qty * rate;
      final discount = discPct ? subtotal * (disc / 100) : disc;
      final taxable = (subtotal - discount).clamp(0, double.infinity);
      final taxAmount = taxable * (tax / 100);
      total += (taxable + taxAmount);
    }
    setState(() => _runningTotal = total);
  }

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _items.clear();
      _items.addAll(widget.existing!.items.map((item) => InvoiceItemData.fromInvoiceItem(item)));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _recomputeTotals());
  }

  @override
  Widget build(BuildContext context) {
    final invRepo = ref.watch(invoiceRepositoryProvider);
    final merchRepo = ref.watch(merchantRepositoryProvider);
    final clientsRepo = ref.watch(clientRepositoryProvider);

    return FutureBuilder(
      future: Future.wait([
        merchRepo.getProfile(),
        clientsRepo.getAll(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 200,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        
        final profile = snapshot.data![0];
        final clients = snapshot.data![1] as List<Client>;

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                _buildHeader(),
                
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FormBuilder(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (_step == 0) _buildClientStep(clients),
                          if (_step == 1) _buildItemsStep(),
                          if (_step == 2) _buildNotesStep(),
                          
                          const SizedBox(height: 32),
                          
                          // Navigation Buttons
                          _buildNavigationButtons(invRepo, profile, clients),
                          
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Live Total Bar
                _buildTotalBar(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E5E7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  widget.existing != null ? Icons.edit_rounded : Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.existing != null ? 'Edit Invoice' : 'Create New Invoice',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Step ${_step + 1} of 3',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Color(0xFF8E8E93)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E5E7),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (_step + 1) / 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientStep(List<Client> clients) {
    return Column(
      children: [
        _FormSection(
          title: 'Client & Invoice Details',
          subtitle: 'Select client and set invoice information',
          children: [
            _FormField(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Client', style: TextStyle(fontSize: 14, color: Color(0xFF374151))),
                  const SizedBox(height: 8),
                  FormBuilderDropdown<String>(
                    name: 'clientId',
                    initialValue: widget.existing?.client.id,
                    decoration: const InputDecoration(
                      hintText: 'Select a client',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    items: clients.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    )).toList(),
                    validator: FormBuilderValidators.required(),
                  ),
                ],
              ),
            ),
            _FormField(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Invoice Date', style: TextStyle(fontSize: 14, color: Color(0xFF374151))),
                        const SizedBox(height: 8),
                        FormBuilderDateTimePicker(
                          name: 'date',
                          initialValue: widget.existing?.date ?? DateTime.now(),
                          inputType: InputType.date,
                          decoration: const InputDecoration(
                            hintText: 'Select date',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          validator: FormBuilderValidators.required(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Due Date', style: TextStyle(fontSize: 14, color: Color(0xFF374151))),
                        const SizedBox(height: 8),
                        FormBuilderDateTimePicker(
                          name: 'dueDate',
                          initialValue: widget.existing?.dueDate ?? DateTime.now().add(const Duration(days: 30)),
                          inputType: InputType.date,
                          decoration: const InputDecoration(
                            hintText: 'Select due date',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          validator: FormBuilderValidators.required(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _FormField(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Currency', style: TextStyle(fontSize: 14, color: Color(0xFF374151))),
                  const SizedBox(height: 8),
                  FormBuilderTextField(
                    name: 'currencyCode',
                    initialValue: widget.existing?.currencyCode ?? 'USD',
                    decoration: const InputDecoration(
                      hintText: 'Enter currency code (e.g., USD, EUR)',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              isLast: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemsStep() {
    return Column(
      children: [
        _FormSection(
          title: 'Invoice Items',
          subtitle: 'Add products or services to this invoice',
          children: [
            // Items List
            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _ItemCard(
                key: ValueKey('item_$index'),
                index: index,
                item: item,
                onChanged: _recomputeTotals,
                onRemove: _items.length > 1 ? () {
                  setState(() => _items.removeAt(index));
                  _recomputeTotals();
                } : null,
              );
            }),
            
            // Add Item Button
            Container(
              margin: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() => _items.add(InvoiceItemData()));
                  _recomputeTotals();
                },
                icon: const Icon(Icons.add, color: Color(0xFF6366F1)),
                label: const Text(
                  'Add Another Item',
                  style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF6366F1)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesStep() {
    return Column(
      children: [
        _FormSection(
          title: 'Additional Information',
          subtitle: 'Add notes and terms for this invoice',
          children: [
            _FormField(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notes', style: TextStyle(fontSize: 14, color: Color(0xFF374151))),
                  const SizedBox(height: 8),
                  FormBuilderTextField(
                    name: 'notes',
                    initialValue: widget.existing?.notes,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Additional notes for the client',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            _FormField(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Terms & Conditions', style: TextStyle(fontSize: 14, color: Color(0xFF374151))),
                  const SizedBox(height: 8),
                  FormBuilderTextField(
                    name: 'terms',
                    initialValue: widget.existing?.terms,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Payment terms and conditions',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              isLast: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(InvoiceRepository invRepo, profile, List<Client> clients) {
    return Row(
      children: [
        if (_step > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _step--),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFFE5E5E7)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Back',
                style: TextStyle(fontSize: 17, color: Color(0xFF8E8E93)),
              ),
            ),
          ),
        if (_step > 0) const SizedBox(width: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B7ED8)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => _handleNext(invRepo, profile, clients),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _step < 2 ? 'Continue' : (widget.existing != null ? 'Update Invoice' : 'Create Invoice'),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E5E7))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Amount',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          Text(
            '\$${_runningTotal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF6366F1),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNext(InvoiceRepository invRepo, profile, List<Client> clients) async {
    if (_step < 2) {
      setState(() => _step++);
      return;
    }

    // Create invoice
    final ok = _formKey.currentState?.saveAndValidate() ?? false;
    if (!ok) return;

    final v = _formKey.currentState!.value;
    final client = clients.firstWhere((c) => c.id == v['clientId']);
    
    final items = _items.map((item) => InvoiceItem(
      productId: '', // No product ID for manual entry
      description: item.description,
      quantity: item.quantity,
      rate: item.rate,
      taxPercent: item.taxPercent,
      discountValue: item.discountValue,
      discountIsPercent: item.discountIsPercent,
    )).toList();

    final merchantRepo = ref.read(merchantRepositoryProvider);
    final invoice = Invoice(
      id: widget.existing?.id ?? const Uuid().v4(),
      invoiceNumber: widget.existing?.invoiceNumber ?? await merchantRepo.generateNextInvoiceNumber(),
      date: v['date'] as DateTime,
      dueDate: v['dueDate'] as DateTime,
      client: client,
      items: items,
      status: widget.existing?.status ?? InvoiceStatus.draft,
      notes: v['notes'],
      terms: v['terms'],
      currencyCode: v['currencyCode']?.toString().trim().isEmpty == true ? null : v['currencyCode'],
    );

    await invRepo.upsert(invoice);
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existing != null ? 'Invoice updated' : 'Invoice created'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

// Form Section Widget
class _FormSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _FormSection({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

// Form Field Widget
class _FormField extends StatelessWidget {
  final Widget child;
  final bool isLast;

  const _FormField({
    required this.child,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: isLast ? null : const Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

// Item Card Widget
class _ItemCard extends StatefulWidget {
  final int index;
  final InvoiceItemData item;
  final VoidCallback onChanged;
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Item ${widget.index + 1}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              if (widget.onRemove != null)
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Description
          TextField(
            onChanged: (value) {
              widget.item.description = value;
              widget.onChanged();
            },
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Product or service description',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
            controller: TextEditingController(text: widget.item.description)
              ..selection = TextSelection.collapsed(offset: widget.item.description.length),
          ),
          const SizedBox(height: 12),
          // Quantity and Rate
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    widget.item.quantity = double.tryParse(value) ?? 1.0;
                    widget.onChanged();
                  },
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  controller: TextEditingController(text: widget.item.quantity.toString()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    widget.item.rate = double.tryParse(value) ?? 0.0;
                    widget.onChanged();
                  },
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Rate',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  controller: TextEditingController(text: widget.item.rate.toString()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Tax and Discount
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    widget.item.taxPercent = double.tryParse(value) ?? 0.0;
                    widget.onChanged();
                  },
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tax %',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  controller: TextEditingController(text: widget.item.taxPercent.toString()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    widget.item.discountValue = double.tryParse(value) ?? 0.0;
                    widget.onChanged();
                  },
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Discount',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  controller: TextEditingController(text: widget.item.discountValue.toString()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Line Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Line Total:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                '\$${widget.item.lineTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6366F1),
                ),
              ),
            ],
          ),
        ],
      ),
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