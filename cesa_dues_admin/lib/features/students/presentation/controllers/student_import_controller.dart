import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xl;
import 'package:cesa_dues_core/cesa_dues_core.dart';
import 'student_list_controller.dart';

class StudentImportController extends StateNotifier<AsyncValue<int>> {
  StudentImportController(this._ref) : super(const AsyncData(0));

  final Ref _ref;
  final _firestore = FirebaseFirestore.instance;

  Future<void> importStudents() async {
    try {
      state = const AsyncLoading();

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        state = const AsyncData(0);
        return;
      }

      final file = result.files.first;
      final Uint8List? fileBytes = file.bytes;

      if (fileBytes == null || fileBytes.isEmpty) {
        throw Exception('Could not read file data. Please select another file.');
      }

      final studentsToImport = <Student>[];

      // Check if file is binary Excel (PKzip header 0x50 0x4B 0x03 0x04 or legacy XLS 0xD0 0xCF 0x11 0xE0)
      bool isExcel = false;
      if (fileBytes.length >= 4) {
        final b0 = fileBytes[0];
        final b1 = fileBytes[1];
        final b2 = fileBytes[2];
        final b3 = fileBytes[3];

        if ((b0 == 0x50 && b1 == 0x4B && b2 == 0x03 && b3 == 0x04) ||
            (b0 == 0xD0 && b1 == 0xCF && b2 == 0x11 && b3 == 0xE0)) {
          isExcel = true;
        }
      }

      final ext = file.extension?.toLowerCase() ?? '';
      if (ext == 'xlsx' || ext == 'xls') {
        isExcel = true;
      }

      if (isExcel) {
        try {
          final excel = xl.Excel.decodeBytes(fileBytes);
          for (final table in excel.tables.keys) {
            final sheet = excel.tables[table];
            if (sheet == null || sheet.rows.length < 2) continue;

            final headerRow = sheet.rows.first.map((c) => c?.value?.toString().toLowerCase().trim() ?? '').toList();

            int indexCol = headerRow.indexWhere((h) => h.contains('index') || h.contains('id') || h.contains('matric'));
            int nameCol = headerRow.indexWhere((h) => h.contains('name') || h.contains('student'));
            int levelCol = headerRow.indexWhere((h) => h.contains('level') || (h.contains('year') && !h.contains('academic')));
            int acadCol = headerRow.indexWhere((h) => h.contains('academic') || h.contains('session'));

            if (indexCol == -1) indexCol = 0;
            if (nameCol == -1) nameCol = 1;
            if (levelCol == -1 && headerRow.length > 2) levelCol = 2;
            if (acadCol == -1 && headerRow.length > 3) acadCol = 3;

            for (var i = 1; i < sheet.rows.length; i++) {
              final row = sheet.rows[i];
              if (row.isEmpty) continue;

              final indexNumber = (indexCol < row.length ? row[indexCol]?.value?.toString() : '')?.trim() ?? '';
              final fullName = (nameCol < row.length ? row[nameCol]?.value?.toString() : '')?.trim() ?? '';

              final levelRaw = (levelCol >= 0 && levelCol < row.length ? row[levelCol]?.value?.toString() : '100') ?? '100';
              final level = int.tryParse(levelRaw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 100;

              final academicYear = (acadCol >= 0 && acadCol < row.length ? row[acadCol]?.value?.toString() : '2023/2024')?.trim() ?? '2023/2024';

              if (indexNumber.isNotEmpty && fullName.isNotEmpty && !indexNumber.toLowerCase().contains('index')) {
                studentsToImport.add(Student(
                  indexNumber: indexNumber,
                  fullName: fullName,
                  programme: 'Civil Engineering',
                  level: level,
                  academicYear: academicYear.isNotEmpty ? academicYear : '2023/2024',
                ));
              }
            }
          }
        } catch (excelErr) {
          isExcel = false;
        }
      }

      // If not Excel or Excel parser found 0 records, try CSV parsing
      if (studentsToImport.isEmpty) {
        String csvString;
        try {
          csvString = utf8.decode(fileBytes, allowMalformed: true);
        } catch (_) {
          csvString = latin1.decode(fileBytes);
        }

        final List<List<dynamic>> rows = const CsvToListConverter().convert(csvString);

        if (rows.length >= 2) {
          final headerRow = rows.first.map((c) => c.toString().toLowerCase().trim()).toList();

          int indexCol = headerRow.indexWhere((h) => h.contains('index') || h.contains('id') || h.contains('matric'));
          int nameCol = headerRow.indexWhere((h) => h.contains('name') || h.contains('student'));
          int levelCol = headerRow.indexWhere((h) => h.contains('level'));
          int acadCol = headerRow.indexWhere((h) => h.contains('academic') || h.contains('session') || h.contains('year'));

          if (indexCol == -1) indexCol = 0;
          if (nameCol == -1) nameCol = 1;
          if (levelCol == -1 && rows.first.length > 2) levelCol = 2;
          if (acadCol == -1 && rows.first.length > 3) acadCol = 3;

          for (var i = 1; i < rows.length; i++) {
            final row = rows[i];
            if (row.isEmpty) continue;

            final indexNumber = (indexCol < row.length ? row[indexCol].toString() : '').trim();
            final fullName = (nameCol < row.length ? row[nameCol].toString() : '').trim();

            final levelRaw = levelCol >= 0 && levelCol < row.length ? row[levelCol].toString() : '100';
            final level = int.tryParse(levelRaw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 100;

            final academicYear = (acadCol >= 0 && acadCol < row.length ? row[acadCol].toString() : '2023/2024').trim();

            if (indexNumber.isNotEmpty && fullName.isNotEmpty && !indexNumber.toLowerCase().contains('index')) {
              studentsToImport.add(Student(
                indexNumber: indexNumber,
                fullName: fullName,
                programme: 'Civil Engineering',
                level: level,
                academicYear: academicYear.isNotEmpty ? academicYear : '2023/2024',
              ));
            }
          }
        }
      }

      if (studentsToImport.isEmpty) {
        throw Exception('No valid student rows found. Please check that your file has Index Number and Full Name columns.');
      }

      final chunks = <List<Student>>[];
      for (var i = 0; i < studentsToImport.length; i += 400) {
        chunks.add(studentsToImport.sublist(i, i + 400 > studentsToImport.length ? studentsToImport.length : i + 400));
      }

      for (final chunk in chunks) {
        final batch = _firestore.batch();
        for (final student in chunk) {
          final docRef = _firestore.collection('students').doc(student.indexNumber);
          batch.set(docRef, student.toFirestore(), SetOptions(merge: true));
        }
        await batch.commit();
      }

      _ref.read(studentListControllerProvider.notifier).loadStudents(isRefresh: true);
      state = AsyncData(studentsToImport.length);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final studentImportProvider = StateNotifierProvider.autoDispose<StudentImportController, AsyncValue<int>>((ref) {
  return StudentImportController(ref);
});
