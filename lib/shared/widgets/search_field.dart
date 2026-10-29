import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/semantic_colors.dart';

/// Inline filter field used above lists: a quiet pill on the page canvas.
class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.hint, required this.onChanged});

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return M3ETextField(
      placeholder: hint,
      leading: const Icon(Icons.search_rounded),
      showClearButton: true,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      theme: M3ETextFieldTheme(
        containerHeight: 52,
        filledShape: BorderRadius.circular(26),
        colors: M3ETextFieldColorTheme(
          containerColor: WidgetStatePropertyAll(scheme.card),
          // No underline: the pill shape is the whole field.
          activeIndicatorColor: const WidgetStatePropertyAll(
            Colors.transparent,
          ),
        ),
      ),
    );
  }
}
