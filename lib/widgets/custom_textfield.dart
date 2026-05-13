import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
	final TextEditingController controller;
	final String label;
	final IconData icon;
	final bool obscureText;
	final Widget? suffixIcon;
	final TextInputType keyboardType;
	final TextInputAction textInputAction;
	final List<String>? autofillHints;
	final ValueChanged<String>? onSubmitted;

	const CustomTextField({
		super.key,
		required this.controller,
		required this.label,
		required this.icon,
		this.obscureText = false,
		this.suffixIcon,
		this.keyboardType = TextInputType.text,
		this.textInputAction = TextInputAction.next,
		this.autofillHints,
		this.onSubmitted,
	});

	@override
	Widget build(BuildContext context) {
		return TextField(
			controller: controller,
			keyboardType: keyboardType,
			textInputAction: textInputAction,
			autofillHints: autofillHints,
			obscureText: obscureText,
			onSubmitted: onSubmitted,
			style: const TextStyle(color: Colors.white),
			decoration: InputDecoration(
				labelText: label,
				labelStyle: const TextStyle(color: Colors.white),
				prefixIcon: Icon(icon, color: Colors.white),
				suffixIcon: suffixIcon,
				filled: true,
				fillColor: Colors.white.withValues(alpha: 0.1),
				enabledBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: const BorderSide(color: Colors.white70),
				),
				focusedBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: const BorderSide(color: Colors.white, width: 2),
				),
			),
		);
	}
}
