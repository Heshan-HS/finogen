import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/goal_model.dart';
import '../repositories/goal_repository.dart';

final goalsStreamProvider = StreamProvider<List<GoalModel>>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return repository.getUserGoals();
});
