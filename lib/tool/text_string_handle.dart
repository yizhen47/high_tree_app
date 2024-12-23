String hideText(String text) {
  int maxLen = 15;
  return text.length > maxLen ? '${text.substring(0, maxLen - 2)}...' : text;
}
