String normalizeSearch(String value) {
  const accented = 'áàãâäéèêëíìîïóòõôöúùûüç';
  const plain = 'aaaaaeeeeiiiiooooouuuuc';
  var normalized = value.toLowerCase().trim();
  for (var index = 0; index < accented.length; index++) {
    normalized = normalized.replaceAll(accented[index], plain[index]);
  }
  return normalized.replaceAll(RegExp(r'\s+'), ' ');
}
