import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_semantic_colors.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final int? maxLines;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.keyboardType,
    this.validator,
    this.obscureText = false,
    this.maxLines = 1,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      onChanged: onChanged,
      keyboardType: keyboardType,
      validator: validator,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: semantic.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: semantic.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}
