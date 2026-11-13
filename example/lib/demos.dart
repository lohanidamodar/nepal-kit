import 'package:material_ui/material_ui.dart';
import 'package:nepal_kit_flutter/nepal_kit_flutter.dart';

/// Padding and a max width for each demo page.
class _Page extends StatelessWidget {
  const _Page({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: ListView(padding: const EdgeInsets.all(16), children: children),
    ),
  );
}

Widget _label(BuildContext context, String text) => Padding(
  padding: const EdgeInsets.only(top: 16, bottom: 6),
  child: Text(text, style: Theme.of(context).textTheme.titleSmall),
);

NepalKitLanguage _lang(BuildContext context) =>
    NepalKitLocalizations.languageOf(context);

// ── Dates ───────────────────────────────────────────────────────────────

class DatesDemo extends StatefulWidget {
  const DatesDemo({super.key});

  @override
  State<DatesDemo> createState() => _DatesDemoState();
}

class _DatesDemoState extends State<DatesDemo> {
  BsDate _picked = BsDate.today();
  late BsDate _month = _picked.firstOfMonth;
  final _ad = TextEditingController(text: '2025-04-14');

  @override
  Widget build(BuildContext context) {
    final lang = _lang(context);
    final adText = _ad.text.trim();
    String converted;
    try {
      converted = NepaliDateFormat.full(
        lang,
      ).formatAdAsBs(DateTime.parse(adText));
    } catch (_) {
      converted = '—';
    }
    return _Page(
      children: [
        _label(context, 'Today in Nepal'),
        Text(
          NepaliDateFormat.full(lang).formatBs(BsDate.today()),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        _label(context, 'Month calendar (BsMonthCalendar)'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: BsMonthCalendar(
              month: _month,
              selected: _picked,
              markedDates: {BsDate.today().addDays(3)},
              onMonthChanged: (m) => setState(() => _month = m),
              onDateSelected: (d) => setState(() => _picked = d),
            ),
          ),
        ),
        _label(context, 'Date picker (showBsDatePicker)'),
        FilledButton(
          onPressed: () async {
            final d = await showBsDatePicker(
              context: context,
              initialDate: _picked,
            );
            if (d != null) {
              setState(() {
                _picked = d;
                _month = d.firstOfMonth;
              });
            }
          },
          child: Text(NepaliDateFormat.long(lang).formatBs(_picked)),
        ),
        Text(
          'AD: ${NepaliDateFormat('EEEE d MMMM yyyy', language: lang).formatAd(_picked.toAd())}',
        ),
        _label(context, 'AD → BS'),
        TextField(
          controller: _ad,
          decoration: const InputDecoration(labelText: 'AD date (yyyy-mm-dd)'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Text(converted),
      ],
    );
  }
}

// ── Money ───────────────────────────────────────────────────────────────

class MoneyDemo extends StatefulWidget {
  const MoneyDemo({super.key});

  @override
  State<MoneyDemo> createState() => _MoneyDemoState();
}

class _MoneyDemoState extends State<MoneyDemo> {
  final _amount = TextEditingController(text: '125000.50');

  @override
  Widget build(BuildContext context) {
    final npr = Npr.tryParse(_amount.text);
    final vat = npr == null ? null : applyVat(npr, VatRule.nepalStandard);
    return _Page(
      children: [
        TextField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount (Rs.)',
            helperText: 'Western or Devanagari digits',
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (npr == null)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('Not an amount'),
          )
        else ...[
          _label(context, 'Formats'),
          Text('Stored as ${npr.paisa} paisa'),
          Text(npr.format()),
          Text(npr.format(symbol: NprSymbol.rupee, devanagari: true)),
          Text(
            npr.format(
              symbol: NprSymbol.code,
              paisaDisplay: PaisaDisplay.always,
            ),
          ),
          _label(context, 'In words'),
          Text(npr.inWords()),
          Text(npr.inWords(language: AmountWordsLanguage.ne)),
          _label(context, 'With 13% VAT on top'),
          Text('VAT ${vat!.vat.format()} · total ${vat.total.format()}'),
          _label(context, 'Split across 3 months'),
          Text(npr.split(3).map((p) => p.format()).join('  +  ')),
        ],
      ],
    );
  }
}

// ── Phone ───────────────────────────────────────────────────────────────

class PhoneDemo extends StatefulWidget {
  const PhoneDemo({super.key});

  @override
  State<PhoneDemo> createState() => _PhoneDemoState();
}

class _PhoneDemoState extends State<PhoneDemo> {
  final _phone = TextEditingController(text: '+977 984-1234567');

  @override
  Widget build(BuildContext context) {
    final s = NepalKitLocalizations.of(context);
    final v = NepaliPhone.validate(_phone.text);
    final p = v.phone;
    return _Page(
      children: [
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone',
            errorText: v.isValid ? null : s.phoneErrors[v.error!.name],
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (p != null) ...[
          _label(context, 'Parsed'),
          Text('E.164: ${p.e164}'),
          Text('Display: ${p.format()}  ·  ${p.format(international: true)}'),
          Text('Carrier: ${s.isNepali ? p.carrier.nameNe : p.carrier.nameEn}'),
          Text('Links: ${p.telUri}  ${p.whatsAppUri}'),
        ],
      ],
    );
  }
}

// ── Address ─────────────────────────────────────────────────────────────

class AddressDemo extends StatefulWidget {
  const AddressDemo({super.key});

  @override
  State<AddressDemo> createState() => _AddressDemoState();
}

class _AddressDemoState extends State<AddressDemo> {
  Province? _province;
  District? _district;
  LocalLevel? _local;
  int? _ward;

  @override
  Widget build(BuildContext context) {
    final ne = NepalKitLocalizations.of(context).isNepali;
    return _Page(
      children: [
        DropdownButtonFormField<Province>(
          initialValue: _province,
          decoration: const InputDecoration(labelText: 'Province'),
          items: [
            for (final p in NepalAddress.provinces)
              DropdownMenuItem(
                value: p,
                child: Text(p.name(nepali: ne)),
              ),
          ],
          onChanged: (p) => setState(() {
            _province = p;
            _district = null;
            _local = null;
            _ward = null;
          }),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<District>(
          key: ValueKey(_province),
          initialValue: _district,
          decoration: const InputDecoration(labelText: 'District'),
          items: [
            for (final d in _province?.districts ?? const <District>[])
              DropdownMenuItem(
                value: d,
                child: Text(d.name(nepali: ne)),
              ),
          ],
          onChanged: (d) => setState(() {
            _district = d;
            _local = null;
            _ward = null;
          }),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<LocalLevel>(
          key: ValueKey(_district),
          initialValue: _local,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Municipality / rural municipality',
          ),
          items: [
            for (final l in _district?.localLevels ?? const <LocalLevel>[])
              DropdownMenuItem(
                value: l,
                child: Text(l.name(nepali: ne, withType: true)),
              ),
          ],
          onChanged: (l) => setState(() {
            _local = l;
            _ward = null;
          }),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          key: ValueKey(_local),
          initialValue: _ward,
          decoration: const InputDecoration(labelText: 'Ward'),
          items: [
            for (var w = 1; w <= (_local?.wards ?? 0); w++)
              DropdownMenuItem(
                value: w,
                child: Text(ne ? toDevanagariDigits('$w') : '$w'),
              ),
          ],
          onChanged: (w) => setState(() => _ward = w),
        ),
        _label(context, 'Formatted'),
        Text(
          NepaliAddress(
            province: _province,
            district: _district,
            localLevel: _local,
            ward: _ward,
          ).format(nepali: ne),
        ),
        _label(context, 'Search "pokhara"'),
        for (final l in NepalAddress.searchLocalLevels('pokhara', limit: 3))
          Text(
            '${l.name(withType: true, nepali: ne)}, ${l.district.name(nepali: ne)}',
          ),
      ],
    );
  }
}

// ── Receipt ─────────────────────────────────────────────────────────────

ReceiptDocument sampleReceipt(NepalKitLanguage language) => ReceiptDocument(
  kind: ReceiptKind.taxInvoice,
  number: 'INV-2081-0042',
  issuedAt: DateTime.now(),
  dueAt: DateTime.now().add(const Duration(days: 15)),
  business: const ReceiptParty(
    name: 'हिमाल हार्डवेयर (Himal Hardware)',
    address: 'Baneshwor, Kathmandu',
    phone: '01-4123456',
    pan: '301234567',
  ),
  customer: const ReceiptParty(
    name: 'राम श्रेष्ठ',
    phone: '984-1234567',
    pan: '609876543',
  ),
  lines: [
    ReceiptLine('इमल्सन पेन्ट (४ लिटर)', const Npr.rupees(2450), quantity: 2),
    ReceiptLine.fractional(
      'Wall putty',
      const Npr.rupees(120, 50),
      quantityMilli: 1500,
      unit: 'kg',
    ),
    ReceiptLine('ब्रस (४ इन्च)', const Npr.rupees(185)),
  ],
  discount: const Npr.rupees(100),
  vat: VatRule.nepalStandard,
  paid: const Npr.rupees(3000),
  notes: 'सामान फिर्ता ७ दिनभित्र मात्र। Goods return within 7 days only.',
  footer: language == NepalKitLanguage.ne ? 'धन्यवाद!' : 'Thank you!',
  language: language,
);

class ReceiptDemo extends StatefulWidget {
  const ReceiptDemo({super.key});

  @override
  State<ReceiptDemo> createState() => _ReceiptDemoState();
}

class _ReceiptDemoState extends State<ReceiptDemo> {
  bool _roll = false;
  ReceiptDocument? _doc;
  NepalKitLanguage? _docLang;

  @override
  Widget build(BuildContext context) {
    final lang = _lang(context);
    if (_docLang != lang) {
      _doc = sampleReceipt(lang);
      _docLang = lang;
    }
    final format = _roll ? PdfPageFormat.roll80 : PdfPageFormat.a4;
    final t = _doc!.totals;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilterChip(
                label: const Text('80 mm roll'),
                selected: _roll,
                onSelected: (v) => setState(() => _roll = v),
              ),
              FilledButton.tonal(
                onPressed: () => printReceipt(_doc!, pageFormat: format),
                child: const Text('Print'),
              ),
              FilledButton.tonal(
                onPressed: () => shareReceipt(_doc!, pageFormat: format),
                child: const Text('Share'),
              ),
              Text('Total ${t.total.format()} · due ${t.balance.format()}'),
            ],
          ),
        ),
        Expanded(
          child: ReceiptPreview(
            key: ValueKey('$lang$_roll'),
            doc: _doc!,
            pageFormat: format,
          ),
        ),
      ],
    );
  }
}

// ── SMS ─────────────────────────────────────────────────────────────────

class SmsDemo extends StatefulWidget {
  const SmsDemo({super.key});

  @override
  State<SmsDemo> createState() => _SmsDemoState();
}

class _SmsDemoState extends State<SmsDemo> {
  // Swap in SandeshSmsGateway(baseUrl: ..., apiKey: ...) for real sends.
  final _gateway = MockSmsGateway();
  late final _scheduler = ReminderScheduler(gateway: _gateway);
  ReminderKind _kind = ReminderKind.rentDue;
  String _log = '';

  @override
  Widget build(BuildContext context) {
    final lang = _lang(context);
    final ne = lang == NepalKitLanguage.ne;
    final text = ReminderTemplates.render(
      _kind,
      language: lang,
      name: ne ? 'हरि' : 'Hari',
      business: ne ? 'सजिलो रेन्ट' : 'Sajilo Rent',
      amount: const Npr.rupees(15000),
      date: BsDate.today().addDays(5),
      time: '10:00',
      place: ne ? 'शोरुम' : 'the showroom',
    );
    return _Page(
      children: [
        SegmentedButton<ReminderKind>(
          segments: const [
            ButtonSegment(value: ReminderKind.rentDue, label: Text('Rent')),
            ButtonSegment(value: ReminderKind.udhaaro, label: Text('Udhaaro')),
            ButtonSegment(
              value: ReminderKind.appointment,
              label: Text('Visit'),
            ),
          ],
          selected: {_kind},
          onSelectionChanged: (s) => setState(() => _kind = s.first),
        ),
        _label(context, 'Message'),
        Text(text),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            FilledButton(
              onPressed: () async {
                final r = await _gateway.send('9841234567', text);
                setState(
                  () => _log =
                      'Sent now: ${r.id} → ${r.to} (${r.status.name})\n$_log',
                );
              },
              child: const Text('Send now (mock)'),
            ),
            OutlinedButton(
              onPressed: () async {
                await _scheduler.schedule(
                  Reminder(
                    id: 'r${DateTime.now().microsecondsSinceEpoch}',
                    to: '9801234567',
                    body: text,
                    sendAt: DateTime.now().add(const Duration(seconds: 5)),
                  ),
                );
                setState(() => _log = 'Scheduled for 5 s from now\n$_log');
              },
              child: const Text('Schedule in 5 s'),
            ),
            OutlinedButton(
              onPressed: () async {
                final r = await _scheduler.dispatchDue();
                setState(
                  () => _log =
                      'Dispatch: ${r.sent.length} sent, '
                      '${r.retrying.length} retrying\n$_log',
                );
              },
              child: const Text('Dispatch due'),
            ),
          ],
        ),
        _label(context, 'Log'),
        Text(_log.isEmpty ? '—' : _log),
      ],
    );
  }
}
