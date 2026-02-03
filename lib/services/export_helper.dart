// Conditional export: use web implementation when dart:html is available
export 'export_helper_io.dart' if (dart.library.html) 'export_helper_web.dart';
