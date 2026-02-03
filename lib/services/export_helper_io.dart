Future<void> downloadBytes(List<int> bytes, String filename) async {
  // noop on non-web platforms; export_service will handle file writes
  return;
}
