import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bill_model.dart';
import '../repositories/bill_repository.dart';

final billsStreamProvider = StreamProvider<List<BillModel>>((ref) {
  final repository = ref.watch(billRepositoryProvider);
  return repository.getUserBills();
});
