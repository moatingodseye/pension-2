
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared/models/account.dart';
import 'package:shared/models/account_type.dart';
import 'package:shared/models/income.dart';
import 'package:shared/models/outgoing.dart';
import 'package:shared/models/transfer.dart';

class CsvService {
  
  String exportAccounts(List<Account> accounts) {
    final buffer = StringBuffer();
    buffer.writeln('id,name,amount,type,date,rate');
    for (var a in accounts) {
      buffer.writeln('${a.id},"${a.name}",${a.amount},${a.type.index},${a.amountAt.toIso8601String().split('T')[0]},${a.rate}');
    }
    return buffer.toString();
  }

  String exportIncomes(List<Income> incomes) {
    final buffer = StringBuffer();
    buffer.writeln('id,name,amount,startAt,endAt,intoAccount,rate');
    for (var i in incomes) {
      buffer.writeln('${i.id},"${i.name}",${i.amount},${i.startAt},${i.endAt ?? ''},${i.intoAccount ?? ''},${i.rate}');
    }
    return buffer.toString();
  }

  String exportOutgoings(List<Outgoing> outgoings) {
    final buffer = StringBuffer();
    buffer.writeln('id,name,amount,startAt,endAt,fromAccount,rate');
    for (var o in outgoings) {
      buffer.writeln('${o.id},"${o.name}",${o.amount},${o.startAt},${o.endAt ?? ''},${o.fromAccount ?? ''},${o.rate}');
    }
    return buffer.toString();
  }

  String exportTransfers(List<Transfer> transfers) {
    final buffer = StringBuffer();
    buffer.writeln('id,name,amount,startAt,endAt,fromAccount,intoAccount');
    for (var t in transfers) {
      buffer.writeln('${t.id},"${t.name}",${t.amount},${t.startAt},${t.endAt ?? ''},${t.fromAccount},${t.intoAccount}');
    }
    return buffer.toString();
  }

  static String exportSimulation(dynamic result) {
    // result is SimulationResult, assume dynamic to avoid circular import if needed, 
    // or import SimulationResult. It is safe to import.
    final buffer = StringBuffer();
    buffer.writeln('Age,Pension Value,Income,Monte Carlo Min,Monte Carlo Max');
    
    // Check if result has lists
    if (result != null) {
      final sunValues = result.sum;
      final incomeValues = result.income;
      final mcMin = result.monteMin;
      final mcMax = result.monteMax;
      final ageList = result.ageList;
      
      int count = ageList.length;
      if (sunValues.length < count) count = sunValues.length;
      
      for (int i = 0; i < count; i++) {
        buffer.writeln('${ageList[i].toStringAsFixed(1)},${sunValues[i].toStringAsFixed(2)},${incomeValues[i].toStringAsFixed(2)},${mcMin.isNotEmpty ? mcMin[i].toStringAsFixed(2) : ""},${mcMax.isNotEmpty ? mcMax[i].toStringAsFixed(2) : ""}');
      }
    }
    
    return buffer.toString();
  }

  static Future<void> copyToClipboard(context, String data) async {
      await Clipboard.setData(ClipboardData(text: data));
      if (context != null) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Data exported to Clipboard!')),
         );
      }
  }

  // --- File I/O ---

  static Future<void> saveAndExport(BuildContext context, String data, String fileName) async {
    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Please select an output file:',
        fileName: fileName,
      );

      if (outputFile == null) {
        // User canceled the picker
        return;
      }
      
      final file = File(outputFile);
      await file.writeAsString(data);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data saved to $outputFile')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving file: $e')),
        );
      }
    }
  }

  static Future<String?> pickAndRead(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        return await file.readAsString();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reading file: $e')),
        );
      }
    }
    return null;
  }

  // --- Parsing ---

  List<Account> parseAccounts(String csv) {
    List<Account> list = [];
    final lines = const LineSplitter().convert(csv);
    // Skip header if present (check first line)
    int start = 0;
    if (lines.isNotEmpty && lines[0].startsWith('id,name')) {
      start = 1;
    }

    for (int i = start; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      // Simple Split (does not handle quoted commas properly, MVP)
      // "id,name,amount,type,date,rate"
      // 1,"PensionPot",10000,0,2024-01-01,0.05
      
      // Remove quotes from name if robust parsing is needed, but for now simple split:
      // A better regex split or CSV parser package is recommended for production.
      // But let's look at how we export: "name" is quoted.
      // Let's implement a rudimentary parser
      
      try {
        final parts = _splitCsvLine(line);
        if (parts.length < 6) continue;

        // id,name,amount,type,date,rate
        // id is ignored on insert actually, but good to have
        
        list.add(Account(
          name: parts[1],
          amount: double.tryParse(parts[2]) ?? 0.0,
          type: AccountType.values[int.tryParse(parts[3]) ?? 0], 
          amountAt: DateTime.tryParse(parts[4]) ?? DateTime.now(),
          rate: double.tryParse(parts[5]) ?? 0.0,
          age: 0
        ));
      } catch (e) {
        debugPrint('Error parsing account line: $line -> $e');
      }
    }
    return list;
  }

  List<Income> parseIncomes(String csv) {
    List<Income> list = [];
    final lines = const LineSplitter().convert(csv);
    int start = 0;
    if (lines.isNotEmpty && lines[0].startsWith('id,name')) start = 1;

    for (int i = start; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        try {
            final parts = _splitCsvLine(line);
            // id,name,amount,startAt,endAt,intoAccount,rate
            if (parts.length < 7) continue;
            
            list.add(Income(
                name: parts[1],
                amount: double.tryParse(parts[2]) ?? 0.0,
                startAt: parts[3],
                endAt: parts[4].isEmpty ? null : parts[4],
                intoAccount: int.tryParse(parts[5]), // Will be ID, potentially invalid if IDs changed
                rate: double.tryParse(parts[6]) ?? 0.0,
            ));
        } catch (e) {
            debugPrint('Error parsing income line: $line -> $e');
        }
    }
    return list;
  }

  List<Outgoing> parseOutgoings(String csv) {
      List<Outgoing> list = [];
      final lines = const LineSplitter().convert(csv);
      int start = 0;
      if (lines.isNotEmpty && lines[0].startsWith('id,name')) start = 1;

      for (int i = start; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          try {
              final parts = _splitCsvLine(line);
              // id,name,amount,startAt,endAt,fromAccount,rate
              if (parts.length < 7) continue;
              
              list.add(Outgoing(
                  name: parts[1],
                  amount: double.tryParse(parts[2]) ?? 0.0,
                  startAt: parts[3],
                  endAt: parts[4].isEmpty ? null : parts[4],
                  fromAccount: int.tryParse(parts[5]),
                  rate: double.tryParse(parts[6]) ?? 0.0,
              ));
          } catch(e) {
               debugPrint('Error parsing outgoing line: $line -> $e');
          }
      }
      return list;
  }

  List<Transfer> parseTransfers(String csv) {
      List<Transfer> list = [];
      final lines = const LineSplitter().convert(csv);
      int start = 0;
      if (lines.isNotEmpty && lines[0].startsWith('id,name')) start = 1;

      for (int i = start; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          try {
              final parts = _splitCsvLine(line);
              // id,name,amount,startAt,endAt,fromAccount,intoAccount
              if (parts.length < 7) continue;
              
              list.add(Transfer(
                  name: parts[1],
                  amount: double.tryParse(parts[2]) ?? 0.0,
                  startAt: parts[3],
                  endAt: parts[4].isEmpty ? null : parts[4],
                  fromAccount: int.tryParse(parts[5]) ?? 0,
                  intoAccount: int.tryParse(parts[6]) ?? 0,
                  rate: 0.0
              ));
          } catch(e) {
               debugPrint('Error parsing transfer line: $line -> $e');
          }
      }
      return list;
  }

  List<String> _splitCsvLine(String line) {
    // Basic CSV split respecting quotes
    List<String> result = [];
    bool inQuote = false;
    StringBuffer field = StringBuffer();
    
    for (int i = 0; i < line.length; i++) {
      String char = line[i];
      if (char == '"') {
        inQuote = !inQuote;
      } else if (char == ',' && !inQuote) {
        result.add(_cleanField(field.toString()));
        field.clear();
      } else {
        field.write(char);
      }
    }
    result.add(_cleanField(field.toString()));
    return result;
  }
  
  String _cleanField(String field) {
      String s = field.trim();
      if (s.startsWith('"') && s.endsWith('"')) {
          s = s.substring(1, s.length - 1);
      }
      return s;
  }
}
