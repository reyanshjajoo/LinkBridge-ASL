import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:asl_app/constants/app_colors.dart';
import 'package:asl_app/constants/education_content.dart';
import 'package:asl_app/widgets/education_widgets.dart';

class EducationScreen extends StatefulWidget {
	const EducationScreen({super.key});

	@override
	State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen>
		with TickerProviderStateMixin {
	late final AnimationController _headerController;
	late final Animation<double> _headerFadeAnimation;

	@override
	void initState() {
		super.initState();
		_headerController = AnimationController(
			duration: const Duration(milliseconds: 1000),
			vsync: this,
		);

		_headerFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
			CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
		);

		_headerController.forward();
	}

	@override
	void dispose() {
		_headerController.dispose();
		super.dispose();
	}

	Future<void> _launchUrl(String url) async {
		final uri = Uri.parse(url);
		if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
			throw Exception('Could not launch $url');
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: AppColors.warmGold,
			body: SafeArea(
				child: SingleChildScrollView(
					padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.stretch,
						children: <Widget>[
							FadeTransition(
								opacity: _headerFadeAnimation,
								child: Container(
									padding: const EdgeInsets.all(22),
									decoration: BoxDecoration(
										color: AppColors.richBrown,
										borderRadius: BorderRadius.circular(18),
										boxShadow: const <BoxShadow>[
											BoxShadow(
												blurRadius: 18,
												color: Colors.black26,
												offset: Offset(0, 10),
											),
										],
									),
									child: const Column(
										children: <Widget>[
											Text(
												'DEAF AWARENESS & ASL',
												textAlign: TextAlign.center,
												style: TextStyle(
													color: Colors.white,
													fontWeight: FontWeight.w800,
													fontSize: 20,
													letterSpacing: 0.8,
												),
											),
											SizedBox(height: 8),
											Text(
												'Learn key facts, history, and ways to be an ally.',
												textAlign: TextAlign.center,
												style: TextStyle(
													color: Colors.white70,
													fontSize: 14,
													height: 1.4,
												),
											),
										],
									),
								),
							),
							const SizedBox(height: 18),
							const SectionTitle(title: 'The Global Population'),
							const InteractivePopulationVisual(),
							const SizedBox(height: 4),
							const BodyTextBlock(educationIntroText),
							const SizedBox(height: 8),
							const DividerLine(),
							const SectionTitle(title: 'Test Your Knowledge'),
							const TriviaWidget(),
							const SizedBox(height: 8),
							const DividerLine(),
							const SectionTitle(title: 'History of Deafness'),
							...historyFacts.map(
								(fact) => HistoryItem(
									icon: fact.icon,
									title: fact.title,
									description: fact.description,
								),
							),
							const SizedBox(height: 8),
							const DividerLine(),
							const SectionTitle(title: 'How to Be an Ally'),
							...allyTips.map((tip) => AllyTipCard(text: tip)),
							const SizedBox(height: 8),
							const DividerLine(),
							const SectionTitle(title: 'Ways to Support'),
							...supportLinks.map(
								(link) => SupportButtonTile(
									title: link.title,
									url: link.urlText,
									onPressed: () => _launchUrl(link.url),
								),
							),
							const SizedBox(height: 32),
						],
					),
				),
			),
		);
	}
}
