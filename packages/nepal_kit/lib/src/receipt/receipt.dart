import 'dart:typed_data';

import '../l10n/strings.dart';
import '../number/npr.dart';
import '../number/vat.dart';

/// What kind of document a [ReceiptDocument] prints as.
enum ReceiptKind {
  /// रसिद: proof of a payment.
  receipt,

  /// बिल: a bill asking for payment.
  invoice,

  /// कर बिजक: a VAT invoice from a VAT-registered business.
  taxInvoice,

  /// अनुमानित बिल: a quotation.
  estimate,
}

/// The stamp a document carries.
enum ReceiptStatus {
  /// No stamp.
  issued,

  /// A "PAID" stamp.
  paid,

  /// A "CANCELLED" stamp.
  cancelled,
}

/// A business or customer as printed.
class ReceiptParty {
  /// A party; only [name] is required.
  const ReceiptParty({
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.pan,
    this.vatNumber,
  });

  /// Name.
  final String name;

  /// Address, one or more lines.
  final String? address;

  /// Phone, as it should print.
  final String? phone;

  /// Email.
  final String? email;

  /// PAN (स्थायी लेखा नम्बर), nine digits.
  final String? pan;

  /// VAT registration number, when it differs from the PAN. In Nepal the
  /// VAT number is normally the PAN itself.
  final String? vatNumber;
}

/// One line of a bill.
class ReceiptLine {
  /// [quantity] whole units at [rate] each.
  ReceiptLine(this.description, this.rate, {int quantity = 1, this.unit})
    : quantityMilli = quantity * 1000;

  /// A fractional quantity in thousandths: `quantityMilli: 1500` is 1.5
  /// (kg, hours, ...).
  ReceiptLine.fractional(
    this.description,
    this.rate, {
    required this.quantityMilli,
    this.unit,
  });

  /// What was sold.
  final String description;

  /// Price per unit.
  final Npr rate;

  /// Quantity in thousandths.
  final int quantityMilli;

  /// Unit label (`kg`, `pcs`, `महिना`).
  final String? unit;

  /// [rate] × quantity, rounded to the paisa.
  Npr get amount => rate.times(quantityMilli, 1000);

  /// `1`, `1.5`, `0.25`.
  String get quantityText {
    final whole = quantityMilli ~/ 1000,
        frac = quantityMilli.remainder(1000).abs();
    if (frac == 0) return '$whole';
    return '$whole.${frac.toString().padLeft(3, '0').replaceFirst(RegExp(r'0+$'), '')}';
  }
}

/// The money on a document, worked out once for printing and display.
class ReceiptTotals {
  /// Totals; normally from [ReceiptDocument.totals].
  const ReceiptTotals({
    required this.subtotal,
    required this.discount,
    required this.taxable,
    required this.vat,
    required this.total,
    required this.paid,
  });

  /// Sum of the lines.
  final Npr subtotal;

  /// Discount taken off the subtotal.
  final Npr discount;

  /// Amount VAT is charged on (after discount, before VAT).
  final Npr taxable;

  /// VAT.
  final Npr vat;

  /// What the customer owes in all.
  final Npr total;

  /// Already paid.
  final Npr paid;

  /// Still owed (never below zero).
  Npr get balance => (total - paid).max(Npr.zero);
}

/// Everything printed on a receipt or invoice.
class ReceiptDocument {
  /// A document.
  const ReceiptDocument({
    required this.kind,
    required this.number,
    required this.issuedAt,
    required this.business,
    required this.lines,
    this.customer,
    this.dueAt,
    this.logo,
    this.discount = Npr.zero,
    this.vat = VatRule.none,
    this.paid = Npr.zero,
    this.status = ReceiptStatus.issued,
    this.notes,
    this.footer,
    this.language = NepalKitLanguage.en,
    this.showBsDate = true,
    this.showAdDate = true,
    this.showAmountInWords = true,
    this.signatureLine = true,
  });

  /// Receipt, invoice, tax invoice or estimate.
  final ReceiptKind kind;

  /// Document number (`INV-0042`).
  final String number;

  /// Issue date (its calendar fields; printed in BS and/or AD).
  final DateTime issuedAt;

  /// Due date for an invoice, valid-until for an estimate.
  final DateTime? dueAt;

  /// Seller.
  final ReceiptParty business;

  /// Buyer.
  final ReceiptParty? customer;

  /// PNG or JPEG bytes of the business logo.
  final Uint8List? logo;

  /// Lines.
  final List<ReceiptLine> lines;

  /// Discount on the subtotal.
  final Npr discount;

  /// VAT rule. With [VatRule.inclusive], line rates already include VAT.
  final VatRule vat;

  /// Amount already paid.
  final Npr paid;

  /// Stamp.
  final ReceiptStatus status;

  /// Notes printed under the totals.
  final String? notes;

  /// A closing line (thanks, bank details).
  final String? footer;

  /// Label language. Item text prints as given.
  final NepalKitLanguage language;

  /// Print the BS date.
  final bool showBsDate;

  /// Print the AD date.
  final bool showAdDate;

  /// Print the total in words.
  final bool showAmountInWords;

  /// Print a signature line.
  final bool signatureLine;

  /// The money on this document.
  ReceiptTotals get totals {
    final subtotal = sumNpr(lines.map((l) => l.amount));
    final discount = this.discount.min(subtotal).max(Npr.zero);
    final afterDiscount = subtotal - discount;
    final split = applyVat(afterDiscount, vat);
    return ReceiptTotals(
      subtotal: subtotal,
      discount: discount,
      taxable: split.taxable,
      vat: split.vat,
      total: split.total,
      paid: paid,
    );
  }
}
