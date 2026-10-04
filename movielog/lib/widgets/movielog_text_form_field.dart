import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MovieLogTextFormField extends StatefulWidget {
  const MovieLogTextFormField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    required this.validator,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onFieldSubmitted,
    this.isPassword = false,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool isPassword;

  @override
  State<MovieLogTextFormField> createState() => _MovieLogTextFormFieldState();
}

class _MovieLogTextFormFieldState extends State<MovieLogTextFormField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final hasError = text.isNotEmpty && widget.validator(text) != null;
    final isValid = text.isNotEmpty && !hasError;

    Widget? suffixIcon;
    if (widget.isPassword) {
      suffixIcon = IconButton(
        icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    } else if (hasError) {
      suffixIcon = const Icon(Icons.error_outline, color: AppColors.red);
    } else if (isValid) {
      suffixIcon = const Icon(Icons.check_circle, color: AppColors.violet);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: widget.isPassword && _obscureText,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onFieldSubmitted,
          decoration: InputDecoration(
            hintText: widget.hintText,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 9,
              horizontal: 16,
            ),
            filled: true,
            fillColor: hasError ? AppColors.lightRed : AppColors.lightGray,
            suffixIcon: suffixIcon,
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.lavenderGray),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.violet, width: 2),
            ),
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.red),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
