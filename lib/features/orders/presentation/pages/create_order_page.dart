import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../di/service_locator.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/order.dart';
import '../bloc/create_order_bloc.dart';
import '../bloc/create_order_event.dart';
import '../bloc/create_order_state.dart';
import 'order_detail_page.dart';

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

  // ── Sender ──
  late final TextEditingController _senderName;
  late final TextEditingController _senderPhone;
  late final TextEditingController _senderAddress;

  // ── Receiver ──
  late final TextEditingController _receiverName;
  late final TextEditingController _receiverPhone;
  late final TextEditingController _receiverAddress;

  // ── Items ──
  final List<_ItemForm> _items = [_ItemForm()];

  // ── Payment ──
  String _paymentParty = 'SENDER';
  final _codAmount = TextEditingController(text: '0');
  bool _sendReceiverLink = false;

  @override
  void initState() {
    super.initState();

    // Prefill sender from the logged-in account
    final auth = sl<AuthBloc>().state;
    final account = auth is AuthAuthenticated ? auth.account : null;

    _senderName = TextEditingController(text: account?.name ?? '');
    _senderPhone = TextEditingController(text: account?.phone ?? '');
    _senderAddress =
        TextEditingController(text: account?.defaultAddress ?? '');

    _receiverName = TextEditingController();
    _receiverPhone = TextEditingController();
    _receiverAddress = TextEditingController();
  }

  @override
  void dispose() {
    _senderName.dispose();
    _senderPhone.dispose();
    _senderAddress.dispose();
    _receiverName.dispose();
    _receiverPhone.dispose();
    _receiverAddress.dispose();
    for (final item in _items) {
      item.dispose();
    }
    _codAmount.dispose();
    super.dispose();
  }

  // ── Validation ──
  static final _phoneRe = RegExp(r'^(\+?251|0)?[79]\d{8}$');

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreateOrderBloc, CreateOrderState>(
      listener: (context, state) {
        if (state is CreateOrderSuccess) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => OrderDetailPage(id: state.order.id),
            ),
          );
        }
        if (state is CreateOrderError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final submitting = state is CreateOrderSubmitting;
        return Scaffold(
          appBar: AppBar(title: const Text('New order')),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SectionTitle('Sender'),
                  _partyFields(
                    name: _senderName,
                    phone: _senderPhone,
                    address: _senderAddress,
                    nameLabel: 'Sender name *',
                    enabled: !submitting,
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle('Receiver'),
                  _partyFields(
                    name: _receiverName,
                    phone: _receiverPhone,
                    address: _receiverAddress,
                    nameLabel: 'Receiver name (optional)',
                    nameRequired: false,
                    enabled: !submitting,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(child: _SectionTitle('Items')),
                      TextButton.icon(
                        onPressed: submitting
                            ? null
                            : () => setState(() => _items.add(_ItemForm())),
                        icon: const Icon(Icons.add),
                        label: const Text('Add item'),
                      ),
                    ],
                  ),
                  ..._items.asMap().entries.map((e) => _itemCard(e.key, e.value, submitting)),
                  const SizedBox(height: 24),
                  _SectionTitle('Payment'),
                  _paymentSelector(submitting),
                  if (_paymentParty == 'RECEIVER' ||
                      _paymentParty == 'SPLIT') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _codAmount,
                      enabled: !submitting,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'COD amount (ETB)',
                        prefixIcon: Icon(Icons.payments_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final d = double.tryParse(v?.trim() ?? '');
                        if (d == null || d < 0) return 'Enter a valid amount';
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: _sendReceiverLink,
                    onChanged: submitting
                        ? null
                        : (v) => setState(() => _sendReceiverLink = v),
                    title: const Text('Send receiver a location link'),
                    subtitle: const Text(
                        'Use this when the receiver must confirm their GPS location'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create order'),
                  ),
                ],
              ),
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
  }) {
    return Column(
      children: [
        TextFormField(
          controller: name,
          enabled: enabled,
          textCapitalization: TextCapitalization.words,
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
          decoration: const InputDecoration(
            labelText: 'Address (optional)',
            prefixIcon: Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _itemCard(int index, _ItemForm form, bool disabled) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Item ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                if (_items.length > 1)
                  IconButton(
                    onPressed: disabled
                        ? null
                        : () => setState(() {
                              _items.removeAt(index).dispose();
                            }),
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remove item',
                  ),
              ],
            ),
            TextFormField(
              controller: form.description,
              enabled: !disabled,
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
                    enabled: !disabled,
                    keyboardType: TextInputType.number,
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
                    enabled: !disabled,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
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
                DropdownMenuItem(value: 'DOCUMENT', child: Text('Document')),
                DropdownMenuItem(value: 'BOX', child: Text('Box')),
                DropdownMenuItem(value: 'ENVELOPE', child: Text('Envelope')),
                DropdownMenuItem(value: 'FOOD', child: Text('Food')),
                DropdownMenuItem(
                    value: 'ELECTRONICS', child: Text('Electronics')),
                DropdownMenuItem(value: 'CLOTHING', child: Text('Clothing')),
                DropdownMenuItem(value: 'MEDICINE', child: Text('Medicine')),
                DropdownMenuItem(
                    value: 'FRAGILE_ITEM', child: Text('Fragile item')),
                DropdownMenuItem(value: 'OTHER', child: Text('Other')),
              ],
              onChanged: disabled ? null : (v) {
                if (v != null) setState(() => form.type = v);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: form.isFragile,
                    onChanged: disabled
                        ? null
                        : (v) => setState(() => form.isFragile = v ?? false),
                    title: const Text('Fragile'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: form.isRefrigerated,
                    onChanged: disabled
                        ? null
                        : (v) =>
                            setState(() => form.isRefrigerated = v ?? false),
                    title: const Text('Cold'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentSelector(bool disabled) {
    return Column(
      children: [
        RadioListTile<String>(
          value: 'SENDER',
          groupValue: _paymentParty,
          onChanged: disabled
              ? null
              : (v) => setState(() => _paymentParty = v ?? 'SENDER'),
          title: const Text('Sender pays'),
          subtitle: const Text('Delivery fee charged to the sender'),
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<String>(
          value: 'RECEIVER',
          groupValue: _paymentParty,
          onChanged: disabled
              ? null
              : (v) => setState(() => _paymentParty = v ?? 'RECEIVER'),
          title: const Text('Receiver pays (COD)'),
          subtitle: const Text('Receiver pays the fee on delivery'),
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<String>(
          value: 'SPLIT',
          groupValue: _paymentParty,
          onChanged: disabled
              ? null
              : (v) => setState(() => _paymentParty = v ?? 'SPLIT'),
          title: const Text('Split'),
          subtitle: const Text('Custom split between sender and receiver'),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      );
}

/// In-memory item form state — converted to OrderItem on submit.
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
