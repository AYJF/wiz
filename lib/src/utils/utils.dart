//"""Convert hex 0-255 values to percent."""
int hexToPercent(int hex) {
  return ((hex / 255) * 100).round();
}

//"""Convert percent values 0-100 into hex 0-255."""
int percentToHex(int precent) {
  return ((precent / 100) * 255).round();
}
