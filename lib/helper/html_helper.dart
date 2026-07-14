/// Admin-authored copy (item/service descriptions, store notes) comes back from the
/// API as HTML. Anywhere it is shown in a plain [Text] widget it must be flattened
/// first, or the markup leaks into the UI as literal `<p>` tags.
class HtmlHelper {
  HtmlHelper._();

  static String toPlainText(String? html) {
    if (html == null || html.isEmpty) return '';
    return html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
