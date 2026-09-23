import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../di/service_locator.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/order.dart';
import '../bloc/create_order_bloc.dart';
import '../bloc/create_order_event.dart';
import '../bloc/create_order_state.dart';

class CreateOrderPage extends StatelessWidget {
  const CreateOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CreateOrderBloc>(),
      child: const _CreateOrderView(),
    );
  }
}

class _CreateOrderView extends StatefulWidget {
  const _CreateOrderView();

  @override
  State<_CreateOrderView> createState() => _CreateOrderViewState();
}

class _CreateOrderViewState extends State<_CreateOrderView> {
  final _formKey = GlobalKey<FormState>();
  final _scroll = ScrollController();

  // Section anchors for scroll-to-error
  final _senderKey = GlobalKey();
  final _receiverKey = GlobalKey();
  final _itemsKey = GlobalKey();
  final _paymentKey = GlobalKey();

  // Sender
  late final TextEditingController _senderName;
  late final TextEditingController _senderPhone;
  late final TextEditingController _senderAddress;

  // Receiver
  late final TextEditingController _receiverName;
  late final TextEditingController _receiverPhone;
  late final TextEditingController _receiverAddress;

  // Items
  final List<_ItemForm> _items = [_ItemForm()];

  // Payment
  String _paymentParty = 'SENDER';
  final _codAmount = TextEditingController(text: '0');
  bool _sendReceiverLink = false;

  bool _dirty = false;
  bool _submitted = false; // ← guard so PopScope doesn't double-pop after success

  @override
  void initState() {
    super.initState();

    final auth = sl<AuthBloc>().state;
    final account = auth is AuthAuthenticated ? auth.account : null;

    _senderName = TextEditingController(text: account?.name ?? '');
    _senderPhone = TextEditingController(text: account?.phone ?? '');
    _senderAddress =
        TextEditingController(text: account?.defaultAddress ?? '');

    _receiverName = TextEditingController();
    _receiverPhone = TextEditingController();
    _receiverAddress = TextEditingController();

    for (final c in [
      _receiverName,
      _receiverPhone,
      _receiverAddress,
      _codAmount,
    ]) {
      c.addListener(_markDirty);
    }
  }

  void _markDirty() {
    if (!_dirty && !_submitted) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _senderName.dispose();
    _senderPhone.dispose();
    _senderAddress.dispose();
    _receiverName.dispose();
    _receiverPhone.dispose();
    _receiverAddress.dispose();
    // FIX #3: iterate a copy so removeAt(i) inside a loop doesn't skip
    for (final item in List<_ItemForm>.from(_items)) {
      item.dispose();
    }
    _items.clear();
    _codAmount.dispose();
    super.dispose();
  }

  static final _phoneRe = RegExp(r'^(\+?251|0)?[79]\d{8}$');

  // ── Live price estimate ──
  double get _estimatedWeight => _items.fold(0.0, (sum, i) {
        final q = int.tryParse(i.quantity.text.trim()) ?? 1;
        final w = double.tryParse(i.weightKg.text.trim()) ?? 0;
        return sum + (w * q);
      });

  double get _estimatedFee {
    final w = _estimatedWeight;
    if (w <= 0) return 0;
    const base = 60.0;
    final perKg = w > 5 ? 15.0 : 20.0;
    return base + (w * perKg);
  }

  // FIX #5 + #8: scroll the first invalid field into view
  Future<void> _scrollToFirstError() async {
    final ctx = _senderKey.currentContext ??
        _receiverKey.currentContext ??
        _itemsKey.currentContext ??
        _paymentKey.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Please fix the highlighted fields'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      // FIX #8 — actually tell the user
      _scrollToFirstError();
      HapticFeedback.mediumImpact();
      return;
    }
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();

    final sender = OrderParty(
      name: _senderName.text.trim(),
      phone: _senderPhone.text.trim(),
      address: _senderAddress.text.trim().isEmpty
          ? null
          : _senderAddress.text.trim(),
    );
    final receiver = OrderParty(
      name: _receiverName.text.trim().isEmpty
          ? null
          : _receiverName.text.trim(),
      phone: _receiverPhone.text.trim(),
      address: _receiverAddress.text.trim().isEmpty
          ? null
          : _receiverAddress.text.trim(),
    );

    final items = _items.map((i) => i.toOrderItem()).toList();
    final cod = double.tryParse(_codAmount.text.trim()) ?? 0;

    context.read<CreateOrderBloc>().add(SubmitOrderEvent(
          sender: sender,
          receiver: receiver,
          items: items,
          paymentParty: _paymentParty,
          codAmount: cod,
          sendReceiverLink: _sendReceiverLink,
        ));
  }

  Future<bool> _confirmExit() async {
    if (!_dirty || _submitted) return true;
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Discard this order?'),
            content: const Text(
              'You have unsaved changes. If you leave, they will be lost.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep editing'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreateOrderBloc, CreateOrderState>(
      listener: (context, state) {
        if (state is CreateOrderSuccess) {
          // FIX #2: mark as submitted so PopScope won't intercept this pop
          _submitted = true;
          Navigator.of(context).pop(state.order.id);
        } else if (state is CreateOrderError) {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                content: Text(state.message),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
        }
      },
      builder: (context, state) {
        final submitting = state is CreateOrderSubmitting;
        return PopScope(
          canPop: !_dirty || _submitted,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final ok = await _confirmExit();
            if (ok && context.mounted) Navigator.of(context).pop();
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('New order'),
              actions: [
                if (!submitting)
                  IconButton(
                    tooltip: 'Discard',
                    icon: const Icon(Icons.close),
                    onPressed: () async {
                      final ok = await _confirmExit();
                      if (ok && context.mounted) Navigator.pop(context);
                    },
                  ),
              ],
            ),
            body: SafeArea(
              bottom: false, // we draw our own bottom bar
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: _scroll,
                  // FIX #6: reserve room for the sticky bar
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    160 + MediaQuery.of(context).padding.bottom,
                  ),
                  children: [
                    _Section(
                      key: _senderKey,
                      icon: Icons.person_pin_circle_outlined,
                      title: 'Sender',
                      subtitle: 'Who is sending the package',
                      child: _partyFields(
                        name: _senderName,
                        phone: _senderPhone,
                        address: _senderAddress,
                        nameLabel: 'Sender name *',
                        enabled: !submitting,
                        onChanged: _markDirty,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _Section(
                      key: _receiverKey,
                      icon: Icons.person_pin_outlined,
                      title: 'Receiver',
                      subtitle: 'Where the package is going',
                      child: _partyFields(
                        name: _receiverName,
                        phone: _receiverPhone,
                        address: _receiverAddress,
                        nameLabel: 'Receiver name (optional)',
                        nameRequired: false,
                        enabled: !submitting,
                        onChanged: _markDirty,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _Section(
                      key: _itemsKey,
                      icon: Icons.inventory_2_outlined,
                      title: 'Items',
                      subtitle: _items.length == 1
                          ? '1 item'
                          : '${_items.length} items',
                      trailing: TextButton.icon(
                        onPressed: submitting
                            ? null
                            : () {
                                setState(() {
                                  _items.add(_ItemForm());
                                  _dirty = true;
                                });
                              },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < _items.length; i++)
                            _ItemCard(
                              key: ValueKey(_items[i]),
                              index: i,
                              form: _items[i],
                              canRemove: _items.length > 1,
                              enabled: !submitting,
                              onRemove: () {
                                setState(() {
                                  final removed = _items.removeAt(i);
                                  removed.dispose();
                                  _dirty = true;
                                });
                              },
                              onChanged: () {
                                _markDirty();
                                setState(() {});
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _Section(
                      key: _paymentKey,
                      icon: Icons.payments_outlined,
                      title: 'Payment',
                      subtitle: 'Who pays the delivery fee',
                      child: _paymentSelector(submitting),
                    ),
                    if (_paymentParty == 'RECEIVER' ||
                        _paymentParty == 'SPLIT') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _codAmount,
                        enabled: !submitting,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        // FIX #9: reject double dots
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'COD amount (ETB)',
                          prefixIcon: Icon(Icons.attach_money),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final d = double.tryParse(v?.trim() ?? '');
                          if (d == null || d < 0) {
                            return 'Enter a valid amount';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    _Section(
                      icon: Icons.tune,
                      title: 'Options',
                      child: SwitchListTile(
                        value: _sendReceiverLink,
                        onChanged: submitting
                            ? null
                            : (v) => setState(() {
                                  _sendReceiverLink = v;
                                  _dirty = true;
                                }),
                        title: const Text('Send receiver a location link'),
                        subtitle: const Text(
                          'The receiver confirms GPS before pickup',
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: _BottomBar(
              estimatedWeightKg: _estimatedWeight,
              estimatedFeeEtb: _estimatedFee,
              submitting: submitting,
              onSubmit: _submit,
            ),
          ),
        );
      },
    );
  }

  Widget _partyFields({
    required TextEditingController name,
    required TextEditingController phone,
    required TextEditingController address,
    required String nameLabel,
    bool nameRequired = true,
    required bool enabled,
    required VoidCallback onChanged,
  }) {
    return Column(
      children: [
        TextFormField(
          controller: name,
          enabled: enabled,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: nameLabel,
            prefixIcon: const Icon(Icons.person_outline),
            border: const OutlineInputBorder(),
          ),
          validator: nameRequired
              ? (v) =>
                  (v == null || v.trim().length < 2) ? 'Enter a name' : null
              : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: phone,
          enabled: enabled,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          onChanged: (_) => onChanged(),
          decoration: const InputDecoration(
            labelText: 'Phone *',
            hintText: '0911223344',
            prefixIcon: Icon(Icons.phone_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (v) {
            if (v == null || !_phoneRe.hasMatch(v.trim())) {
              return 'Enter a valid Ethiopian phone';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: address,
          enabled: enabled,
          textInputAction: TextInputAction.next,
          onChanged: (_) => onChanged(),
          decoration: const InputDecoration(
            labelText: 'Address (optional)',
            prefixIcon: Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _paymentSelector(bool disabled) {
    Widget tile(String value, String title, String subtitle) {
      return RadioListTile<String>(
        value: value,
        groupValue: _paymentParty,
        onChanged: disabled
            ? null
            : (v) => setState(() {
                  _paymentParty = v ?? 'SENDER';
                  _dirty = true;
                }),
        title: Text(title),
        subtitle: Text(subtitle),
        contentPadding: EdgeInsets.zero,
      );
    }

    return Column(
      children: [
        tile('SENDER', 'Sender pays', 'Delivery fee charged to the sender'),
        tile('RECEIVER', 'Receiver pays (COD)',
            'Receiver pays the fee on delivery'),
        tile('SPLIT', 'Split', 'Custom split between sender and receiver'),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Section wrapper
// ═══════════════════════════════════════════════════════════════
class _Section extends StatelessWidget {
  const _Section({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon,
                  size: 18, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  if ((subtitle ?? '').isNotEmpty)
                    Text(subtitle!,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Item card (FIX #7: drop the pointless _open state, use ExpansionTile
//          but with `maintainState: true` and `initiallyExpanded: true`)
// ═══════════════════════════════════════════════════════════════
class _ItemCard extends StatelessWidget {
  const _ItemCard({
    super.key,
    required this.index,
    required this.form,
    required this.canRemove,
    required this.enabled,
    required this.onRemove,
    required this.onChanged,
  });

  final int index;
  final _ItemForm form;
  final bool canRemove;
  final bool enabled;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey(form.hashCode),
            initiallyExpanded: true,
            maintainState: true,
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    form.description.text.trim().isEmpty
                        ? 'New item'
                        : form.description.text.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                if (canRemove)
                  IconButton(
                    onPressed: enabled ? onRemove : null,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: 'Remove item',
                  ),
              ],
            ),
            children: [
              TextFormField(
                controller: form.description,
                enabled: enabled,
                textInputAction: TextInputAction.next,
                onChanged: (_) => onChanged(),
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Books, documents, …',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Describe the item'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: form.quantity,
                      enabled: enabled,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (_) => onChanged(),
                      decoration: const InputDecoration(
                        labelText: 'Qty *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        return (n == null || n < 1) ? '≥ 1' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: form.weightKg,
                      enabled: enabled,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.next,
                      // FIX #9: proper decimal input
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      onChanged: (_) => onChanged(),
                      decoration: const InputDecoration(
                        labelText: 'Weight kg *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final d = double.tryParse(v ?? '');
                        return (d == null || d <= 0) ? '> 0' : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: form.type,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'PARCEL', child: Text('Parcel')),
                  DropdownMenuItem(
                      value: 'DOCUMENT', child: Text('Document')),
                  DropdownMenuItem(value: 'BOX', child: Text('Box')),
                  DropdownMenuItem(
                      value: 'ENVELOPE', child: Text('Envelope')),
                  DropdownMenuItem(value: 'FOOD', child: Text('Food')),
                  DropdownMenuItem(
                      value: 'ELECTRONICS', child: Text('Electronics')),
                  DropdownMenuItem(
                      value: 'CLOTHING', child: Text('Clothing')),
                  DropdownMenuItem(
                      value: 'MEDICINE', child: Text('Medicine')),
                  DropdownMenuItem(
                      value: 'FRAGILE_ITEM', child: Text('Fragile item')),
                  DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                ],
                onChanged: enabled
                    ? (v) {
                        if (v != null) {
                          form.type = v;
                          onChanged();
                        }
                      }
                    : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: form.isFragile,
                      onChanged: enabled
                          ? (v) {
                              form.isFragile = v ?? false;
                              onChanged();
                            }
                          : null,
                      title: const Text('Fragile'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                  Expanded(
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: form.isRefrigerated,
                      onChanged: enabled
                          ? (v) {
                              form.isRefrigerated = v ?? false;
                              onChanged();
                            }
                          : null,
                      title: const Text('Cold'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Sticky bottom bar — now uses bottomNavigationBar slot
// (FIX #6: no longer overlaps the last section)
// ═══════════════════════════════════════════════════════════════
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.estimatedWeightKg,
    required this.estimatedFeeEtb,
    required this.submitting,
    required this.onSubmit,
  });

  final double estimatedWeightKg;
  final double estimatedFeeEtb;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (estimatedWeightKg > 0)
                      Text(
                        '${estimatedWeightKg.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                    Text(
                      estimatedFeeEtb > 0
                          ? '~${estimatedFeeEtb.toStringAsFixed(0)} ETB'
                          : 'Fee calculated on submit',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: submitting ? null : onSubmit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(140, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// In-memory item form
// ═══════════════════════════════════════════════════════════════
class _ItemForm {
  final TextEditingController description = TextEditingController();
  final TextEditingController quantity = TextEditingController(text: '1');
  final TextEditingController weightKg = TextEditingController();
  String type = 'PARCEL';
  bool isFragile = false;
  bool isRefrigerated = false;

  OrderItem toOrderItem() => OrderItem(
        type: type,
        description: description.text.trim(),
        quantity: int.tryParse(quantity.text.trim()) ?? 1,
        weightKg: double.tryParse(weightKg.text.trim()) ?? 0,
        isFragile: isFragile,
        isRefrigerated: isRefrigerated,
      );

  void dispose() {
    description.dispose();
    quantity.dispose();
    weightKg.dispose();
  }
}
