import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

/// Inline filter field used above lists.
class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.hint, required this.onChanged});

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return M3ETextField(
      placeholder: hint,
      leading: const Icon(Icons.search_rounded),
      showClearButton: true,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
    );
  }
}
