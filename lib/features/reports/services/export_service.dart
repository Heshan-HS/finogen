import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/models/transaction_model.dart';
import 'package:intl/intl.dart';

class ExportService {
  static Future<void> exportTransactionsToCsv(List<TransactionModel> transactions, String fileName) async {
    List<List<dynamic>> rows = [];
    
    // Header
    rows.add(['Date', 'Type', 'Category', 'Account', 'Amount', 'Note']);
    
    // Data
    for (var tx in transactions) {
      rows.add([
        DateFormat('yyyy-MM-dd').format(tx.date),
        tx.isIncome ? 'Income' : 'Expense',
        tx.categoryId,
        tx.accountId,
        tx.amount,
        tx.note ?? '',
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$fileName.csv';
    final file = File(path);
    
    await file.writeAsString(csv);
    
    await Share.shareXFiles([XFile(path)], text: 'Financial Report');
  }
}
