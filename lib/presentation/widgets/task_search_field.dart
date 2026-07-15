import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/task_providers.dart';

/// Search box that drives [searchQueryProvider].
///
/// Keeps a local [TextEditingController] for the input while the provider holds
/// the source-of-truth query. A clear button resets both.
class TaskSearchField extends ConsumerStatefulWidget {
  const TaskSearchField({super.key});

  @override
  ConsumerState<TaskSearchField> createState() => _TaskSearchFieldState();
}

class _TaskSearchFieldState extends ConsumerState<TaskSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reflect programmatic clears (e.g. via provider) in the input.
    final query = ref.watch(searchQueryProvider);
    if (query.isEmpty && _controller.text.isNotEmpty) {
      _controller.clear();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        key: const ValueKey('search-field'),
        controller: _controller,
        textInputAction: TextInputAction.search,
        onChanged: (value) =>
            ref.read(searchQueryProvider.notifier).update(value),
        decoration: InputDecoration(
          hintText: 'Search tasks',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Clear search',
                  onPressed: () {
                    _controller.clear();
                    ref.read(searchQueryProvider.notifier).clear();
                    FocusScope.of(context).unfocus();
                  },
                ),
        ),
      ),
    );
  }
}
