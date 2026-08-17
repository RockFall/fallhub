import 'package:flutter/material.dart';

abstract final class KnowledgeAreaIcons {
  static IconData of(String? key) {
    return switch (key) {
      'translate' => Icons.translate,
      'functions' => Icons.functions,
      'biotech' => Icons.biotech_outlined,
      'terminal' => Icons.terminal,
      'menu_book' => Icons.menu_book_outlined,
      'piano' => Icons.piano,
      'account_balance' => Icons.account_balance_outlined,
      'cottage' => Icons.cottage_outlined,
      'precision_manufacturing' => Icons.precision_manufacturing_outlined,
      _ => Icons.account_tree_outlined,
    };
  }
}
