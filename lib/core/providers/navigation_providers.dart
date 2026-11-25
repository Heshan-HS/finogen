import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainNavIndex extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

final mainNavIndexProvider = NotifierProvider<MainNavIndex, int>(() => MainNavIndex());