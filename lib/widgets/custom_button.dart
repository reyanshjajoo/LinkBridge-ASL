import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class CustomButton extends StatelessWidget {
	final String text;
	final VoidCallback? onPressed;
	final bool isLoading;
	final Color? backgroundColor;
	final Color foregroundColor;
	final IconData? icon;

	const CustomButton({
		super.key,
		required this.text,
		required this.onPressed,
		this.isLoading = false,
		this.backgroundColor,
		this.foregroundColor = Colors.white,
		this.icon,
	});

	@override
	Widget build(BuildContext context) {
		return ElevatedButton.icon(
			onPressed: isLoading ? null : onPressed,
			icon: isLoading
					? const SizedBox(
							width: 18,
							height: 18,
							child: CircularProgressIndicator(strokeWidth: 2),
						)
					: Icon(icon ?? Icons.check),
			style: ElevatedButton.styleFrom(
				minimumSize: const Size(double.infinity, 50),
				backgroundColor: backgroundColor ?? AppColors.richBrown,
				foregroundColor: foregroundColor,
				disabledBackgroundColor: const Color(0xFFB8956A),
				shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
			),
			label: Text(
				text,
				style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
			),
		);
	}
}
