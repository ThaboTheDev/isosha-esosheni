/// Only relative same-app paths are honoured for ?next= redirects.
String safeNext(String? next, {String fallback = '/home'}) {
  if (next == null) return fallback;
  final v = next.trim();
  if (!v.startsWith('/')) return fallback;
  if (v.startsWith('//')) return fallback;
  if (v.contains('\\')) return fallback;
  // Disallow scheme-carrying values like "/https://..."
  final after = v.substring(1);
  if (RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(after)) return fallback;
  return v;
}
