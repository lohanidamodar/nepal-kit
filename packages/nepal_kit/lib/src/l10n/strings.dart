// ne/en strings for every nepal_kit component, as plain Dart so servers
// and Flutter share one source. nepal_kit_flutter exposes them through a
// LocalizationsDelegate.
library;

/// A language nepal_kit can write.
enum NepalKitLanguage {
  /// English.
  en,

  /// Nepali.
  ne;

  /// The language for a locale code such as `ne`, `ne_NP` or `en-US`;
  /// English for anything other than Nepali.
  static NepalKitLanguage fromCode(String code) =>
      code.toLowerCase().startsWith('ne') ? ne : en;
}

/// The strings of one language. Get them with [NepalKitStrings.of].
class NepalKitStrings {
  const NepalKitStrings._({
    required this.language,
    required this.bsMonths,
    required this.bsMonthsShort,
    required this.adMonths,
    required this.adMonthsShort,
    required this.weekdays,
    required this.weekdaysShort,
    required this.weekdaysNarrow,
    required this.bsEra,
    required this.adEra,
    required this.today,
    required this.cancel,
    required this.ok,
    required this.selectDate,
    required this.previousMonth,
    required this.nextMonth,
    required this.phoneErrors,
    required this.receipt,
  });

  /// Strings for [language].
  static NepalKitStrings of(NepalKitLanguage language) =>
      language == NepalKitLanguage.ne ? ne : en;

  /// The language of these strings.
  final NepalKitLanguage language;

  /// Whether these are the Nepali strings.
  bool get isNepali => language == NepalKitLanguage.ne;

  /// BS month names, Baishakh first.
  final List<String> bsMonths;

  /// Short BS month names.
  final List<String> bsMonthsShort;

  /// AD month names, January first.
  final List<String> adMonths;

  /// Short AD month names.
  final List<String> adMonthsShort;

  /// Weekday names in [DateTime.weekday] order: Monday first.
  final List<String> weekdays;

  /// Short weekday names, Monday first.
  final List<String> weekdaysShort;

  /// One- or two-letter weekday names for calendar headers, Monday first.
  final List<String> weekdaysNarrow;

  /// `BS` / `वि.सं.`
  final String bsEra;

  /// `AD` / `ई.सं.`
  final String adEra;

  /// Date-picker labels.
  final String today, cancel, ok, selectDate, previousMonth, nextMonth;

  /// Messages for each phone validation error, keyed by the enum name in
  /// `PhoneError` (`empty`, `wrongLength`, ...).
  final Map<String, String> phoneErrors;

  /// Receipt and invoice labels.
  final ReceiptStrings receipt;

  /// English.
  static const NepalKitStrings en = NepalKitStrings._(
    language: NepalKitLanguage.en,
    bsMonths: [
      'Baishakh', 'Jestha', 'Asar', 'Shrawan', 'Bhadra', 'Ashwin', //
      'Kartik', 'Mangsir', 'Poush', 'Magh', 'Falgun', 'Chaitra',
    ],
    bsMonthsShort: [
      'Bai', 'Jes', 'Asa', 'Shr', 'Bha', 'Ash', //
      'Kar', 'Man', 'Pou', 'Mag', 'Fal', 'Cha',
    ],
    adMonths: [
      'January', 'February', 'March', 'April', 'May', 'June', //
      'July', 'August', 'September', 'October', 'November', 'December',
    ],
    adMonthsShort: [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ],
    weekdays: [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', //
      'Sunday',
    ],
    weekdaysShort: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    weekdaysNarrow: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
    bsEra: 'BS',
    adEra: 'AD',
    today: 'Today',
    cancel: 'Cancel',
    ok: 'OK',
    selectDate: 'Select date',
    previousMonth: 'Previous month',
    nextMonth: 'Next month',
    phoneErrors: {
      'empty': 'Enter a phone number',
      'invalidCharacters': 'Use digits only',
      'notNepal': 'Enter a Nepali number (+977)',
      'wrongLength': 'A mobile number has 10 digits',
      'unknownPrefix': 'This is not a Nepali mobile number',
      'inactiveCarrier': 'This network no longer operates',
      'landlineNotAllowed': 'Enter a mobile number',
    },
    receipt: ReceiptStrings.en,
  );

  /// Nepali.
  static const NepalKitStrings ne = NepalKitStrings._(
    language: NepalKitLanguage.ne,
    bsMonths: [
      'बैशाख', 'जेठ', 'असार', 'साउन', 'भदौ', 'असोज', //
      'कात्तिक', 'मंसिर', 'पुस', 'माघ', 'फागुन', 'चैत',
    ],
    bsMonthsShort: [
      'बै', 'जे', 'अ', 'सा', 'भ', 'असो', //
      'का', 'मं', 'पु', 'मा', 'फा', 'चै',
    ],
    adMonths: [
      'जनवरी', 'फेब्रुअरी', 'मार्च', 'अप्रिल', 'मे', 'जुन', //
      'जुलाई', 'अगस्ट', 'सेप्टेम्बर', 'अक्टोबर', 'नोभेम्बर', 'डिसेम्बर',
    ],
    adMonthsShort: [
      'जन', 'फेब', 'मार्च', 'अप्रि', 'मे', 'जुन', //
      'जुला', 'अग', 'सेप', 'अक्टो', 'नोभ', 'डिस',
    ],
    weekdays: [
      'सोमबार', 'मङ्गलबार', 'बुधबार', 'बिहीबार', 'शुक्रबार', 'शनिबार', //
      'आइतबार',
    ],
    weekdaysShort: ['सोम', 'मङ्गल', 'बुध', 'बिही', 'शुक्र', 'शनि', 'आइत'],
    weekdaysNarrow: ['सो', 'म', 'बु', 'बि', 'शु', 'श', 'आ'],
    bsEra: 'वि.सं.',
    adEra: 'ई.सं.',
    today: 'आज',
    cancel: 'रद्द',
    ok: 'ठीक छ',
    selectDate: 'मिति छान्नुहोस्',
    previousMonth: 'अघिल्लो महिना',
    nextMonth: 'अर्को महिना',
    phoneErrors: {
      'empty': 'फोन नम्बर लेख्नुहोस्',
      'invalidCharacters': 'अङ्क मात्र लेख्नुहोस्',
      'notNepal': 'नेपालको नम्बर (+९७७) लेख्नुहोस्',
      'wrongLength': 'मोबाइल नम्बरमा १० अङ्क हुन्छन्',
      'unknownPrefix': 'यो नेपालको मोबाइल नम्बर होइन',
      'inactiveCarrier': 'यो नेटवर्क अब सञ्चालनमा छैन',
      'landlineNotAllowed': 'मोबाइल नम्बर लेख्नुहोस्',
    },
    receipt: ReceiptStrings.ne,
  );
}

/// Labels printed on receipts and invoices.
class ReceiptStrings {
  const ReceiptStrings._({
    required this.receipt,
    required this.invoice,
    required this.taxInvoice,
    required this.estimate,
    required this.number,
    required this.date,
    required this.dueDate,
    required this.billTo,
    required this.from,
    required this.pan,
    required this.vatNo,
    required this.phone,
    required this.serialNo,
    required this.description,
    required this.quantity,
    required this.rate,
    required this.amount,
    required this.subtotal,
    required this.discount,
    required this.taxable,
    required this.vat,
    required this.total,
    required this.paid,
    required this.balance,
    required this.inWords,
    required this.notes,
    required this.paidStamp,
    required this.cancelledStamp,
    required this.signature,
    required this.thankYou,
    required this.page,
  });

  /// Document titles.
  final String receipt, invoice, taxInvoice, estimate;

  /// Header fields.
  final String number, date, dueDate, billTo, from, pan, vatNo, phone;

  /// Line table columns.
  final String serialNo, description, quantity, rate, amount;

  /// Totals.
  final String subtotal, discount, taxable, vat, total, paid, balance;

  /// Footer.
  final String inWords, notes, paidStamp, cancelledStamp, signature, thankYou;

  /// `Page` / `पृष्ठ`
  final String page;

  /// English.
  static const ReceiptStrings en = ReceiptStrings._(
    receipt: 'Receipt',
    invoice: 'Invoice',
    taxInvoice: 'Tax Invoice',
    estimate: 'Estimate',
    number: 'No.',
    date: 'Date',
    dueDate: 'Due date',
    billTo: 'Bill to',
    from: 'From',
    pan: 'PAN',
    vatNo: 'VAT No.',
    phone: 'Phone',
    serialNo: 'S.N.',
    description: 'Description',
    quantity: 'Qty',
    rate: 'Rate',
    amount: 'Amount',
    subtotal: 'Subtotal',
    discount: 'Discount',
    taxable: 'Taxable amount',
    vat: 'VAT',
    total: 'Total',
    paid: 'Paid',
    balance: 'Balance due',
    inWords: 'In words',
    notes: 'Notes',
    paidStamp: 'PAID',
    cancelledStamp: 'CANCELLED',
    signature: 'Authorised signature',
    thankYou: 'Thank you!',
    page: 'Page',
  );

  /// Nepali.
  static const ReceiptStrings ne = ReceiptStrings._(
    receipt: 'रसिद',
    invoice: 'बिल',
    taxInvoice: 'कर बिजक',
    estimate: 'अनुमानित बिल',
    number: 'नं.',
    date: 'मिति',
    dueDate: 'भुक्तानी मिति',
    billTo: 'ग्राहक',
    from: 'विक्रेता',
    pan: 'प्यान',
    vatNo: 'भ्याट नं.',
    phone: 'फोन',
    serialNo: 'क्र.सं.',
    description: 'विवरण',
    quantity: 'परिमाण',
    rate: 'दर',
    amount: 'रकम',
    subtotal: 'जम्मा',
    discount: 'छुट',
    taxable: 'करयोग्य रकम',
    vat: 'मू.अ.कर',
    total: 'कुल जम्मा',
    paid: 'भुक्तानी',
    balance: 'बाँकी',
    inWords: 'अक्षरमा',
    notes: 'कैफियत',
    paidStamp: 'भुक्तानी भयो',
    cancelledStamp: 'रद्द',
    signature: 'अधिकृत दस्तखत',
    thankYou: 'धन्यवाद!',
    page: 'पृष्ठ',
  );
}
