import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:process_run/process_run.dart';
import 'package:flutter/services.dart' show rootBundle;

class Wmf2Png {
  static final String exePath =
      path.join(Directory.systemTemp.path, 'wmf2png.exe');

  Future<Uint8List> convert(Uint8List inputBytes, {
    String? width,
    String? height,
    int? dpi,
  }) async {
    if (!Platform.isWindows) {
      throw Exception('WMF conversion only works on the win32 platform');
    }

    // Extract wmf2png.exe to a fixed directory if it doesn't exist
    if (!await File(exePath).exists()) {
      final bytes = await rootBundle.load('bin/wmf2png.exe');
      await File(exePath).writeAsBytes(bytes.buffer.asUint8List());
    }

    // Create temporary input and output files
    final tempDir = await Directory.systemTemp.createTemp('wmf2png');
    final tempInputFile = File(path.join(tempDir.path, 'input.wmf'));
    final tempOutputFile = File(path.join(tempDir.path, 'output.png'));
    Uint8List res;

    try {
      await tempInputFile.writeAsBytes(inputBytes);

      // Prepare arguments for wmf2png.exe
      final args = [tempInputFile.path, tempOutputFile.path];
      if (width != null) {
        args.add('--width $width');
      }
      if (height != null) {
        args.add('--height $height');
      }
      if (dpi != null) {
        args.add('--dpi $dpi');
      }

      // Execute wmf2png.exe
      final result = await runExecutableArguments(
        exePath,
        args,
      );

      if (result.exitCode != 0) {
        throw Exception('WMF conversion failed: ${result.stderr}');
      }

      // Check if output file exists
      if (!await tempOutputFile.exists()) {
        throw Exception('Output file not found: ${tempOutputFile.path}');
      }
      // Read output from temporary file and write to output file
      res = await tempOutputFile.readAsBytes();
    } finally {
      // Clean up temporary files and directory
      await _deleteIfExists(tempInputFile);
      await _deleteIfExists(tempOutputFile);
      await tempDir.delete(recursive: true);
    }

    return res;
  }

  Future<void> _deleteIfExists(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  // Method to clean up wmf2png.exe when the application ends
  Future<void> cleanup() async {
    if (await File(exePath).exists()) {
      await File(exePath).delete();
    }
  }
}