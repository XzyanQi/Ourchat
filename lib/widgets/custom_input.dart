import 'package:flutter/material.dart';

class CustomInput extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final bool isObscure;
  final RegExp? validationRegExp;
  final Function(String?)? onSaved;
  final Function(String)? onChanged;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final String? label;
  final Iterable<String>? autofillHints;

  const CustomInput({
    Key? key,
    this.controller,
    required this.hintText,
    this.isObscure = false,
    this.validationRegExp,
    this.onSaved,
    this.onChanged,
    this.prefixIcon,
    this.keyboardType,
    this.label,
    this.autofillHints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
            child: Text(
              label!,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        TextFormField(
          controller: controller,
          obscureText: isObscure,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          onSaved: onSaved,
          onChanged: onChanged,
          cursorColor: Colors.white,
          style: const TextStyle(color: Colors.white),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Field ini tidak boleh kosong';
            }
            if (validationRegExp != null &&
                !validationRegExp!.hasMatch(value)) {
              return 'Format tidak valid';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.white54),
            fillColor: const Color.fromRGBO(30, 29, 37, 1.0),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(
                color: Color(0xFF6C5CE7),
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: Colors.red, width: 2.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: Colors.red, width: 2.0),
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: Colors.white54)
                : null,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14.0,
              horizontal: 16.0,
            ),
          ),
        ),
      ],
    );
  }
}
