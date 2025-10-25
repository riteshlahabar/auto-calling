class CallStats {
  final int total;
  final int connected;
  int get pending => total - connected;
  double get progress => total == 0 ? 0 : connected / total;

  const CallStats({required this.total, required this.connected});
}