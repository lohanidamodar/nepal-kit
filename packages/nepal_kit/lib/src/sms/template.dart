// `{placeholder}` templates, lifted unchanged in behaviour from Sandesh
// (packages/sandesh_api/lib/src/template.dart) so a template previewed here
// renders the same as a Sandesh bulk job renders it on the phone.
library;

/// Result of filling a template: [text] with every known placeholder replaced,
/// and [missing] holding the (lower-cased) names that had no value. A missing
/// placeholder stays in [text] exactly as written.
class TemplateResult {
  /// A result; normally made by [renderTemplate].
  const TemplateResult(this.text, this.missing);

  /// The filled-in text.
  final String text;

  /// Placeholders with no value, lower-cased.
  final Set<String> missing;

  @override
  String toString() => 'TemplateResult("$text", missing $missing)';
}

/// Placeholder names used by [template], lower-cased. `{{` and `}}` are
/// literal braces and do not count.
Set<String> placeholdersIn(String template) {
  final names = <String>{};
  _scan(template, (_) {}, (raw, name) => names.add(name));
  return names;
}

/// Replaces `{column}` placeholders with values from [fields]. Lookup ignores
/// case; `{{` and `}}` render as `{` and `}`.
TemplateResult renderTemplate(String template, Map<String, String> fields) {
  final lookup = {
    for (final e in fields.entries) e.key.trim().toLowerCase(): e.value,
  };
  final out = StringBuffer();
  final missing = <String>{};
  _scan(template, out.write, (raw, name) {
    final value = lookup[name];
    if (value == null) {
      missing.add(name);
      out.write(raw);
    } else {
      out.write(value);
    }
  });
  return TemplateResult(out.toString(), missing);
}

/// Walks [template] left to right, emitting literal text (with `{{`/`}}`
/// already unescaped) and placeholders. A `{` that does not open a
/// well-formed `{name}` is literal.
void _scan(
  String template,
  void Function(String literal) onLiteral,
  void Function(String raw, String name) onPlaceholder,
) {
  final buf = StringBuffer();
  void flush() {
    if (buf.isNotEmpty) {
      onLiteral(buf.toString());
      buf.clear();
    }
  }

  var i = 0;
  while (i < template.length) {
    final c = template[i];
    final next = i + 1 < template.length ? template[i + 1] : '';
    if (c == '{' && next == '{') {
      buf.write('{');
      i += 2;
    } else if (c == '}' && next == '}') {
      buf.write('}');
      i += 2;
    } else if (c == '{') {
      final end = template.indexOf('}', i + 1);
      final inner = end < 0 ? '' : template.substring(i + 1, end);
      final name = inner.trim().toLowerCase();
      if (end < 0 || name.isEmpty || inner.contains('{')) {
        buf.write(c);
        i++;
      } else {
        flush();
        onPlaceholder(template.substring(i, end + 1), name);
        i = end + 1;
      }
    } else {
      buf.write(c);
      i++;
    }
  }
  flush();
}
