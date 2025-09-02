import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/book.dart';
import '../models/reading_entry.dart';

class IsarDb {
  IsarDb._();

  static Isar? _isar;

  static Future<Isar> open() async {
    if (_isar != null) return _isar!;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [BookSchema, ReadingEntrySchema],
      directory: dir.path,
      inspector: true,
    );
    return _isar!;
  }
}
