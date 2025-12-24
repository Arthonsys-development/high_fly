// Stub file for web platform - File operations are not available on web
// This file is only used when compiling for web

class File {
  final String path;
  
  File(this.path);
  
  Future<bool> exists() async => false;
}

