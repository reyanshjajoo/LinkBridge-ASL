import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:asl_app/constants/app_colors.dart';
import 'package:asl_app/controllers/captioning_controller.dart';
import 'package:asl_app/models/speaker_profile.dart';
import 'package:asl_app/providers/captioning_provider.dart';
import 'package:asl_app/widgets/caption_tile.dart';
import 'caption_review_screen.dart';
import 'speaker_setup_screen.dart';

class GroupCaptioningScreen extends StatefulWidget {
	final List<SpeakerProfile>? speakers;
	final String? conversationId;
	final WebSocketChannel? channel;
	final Stream? broadcastStream;

	const GroupCaptioningScreen({
		super.key,
		this.speakers,
		this.conversationId,
		this.channel,
		this.broadcastStream,
	});

	@override
	State<GroupCaptioningScreen> createState() => _GroupCaptioningScreenState();
}

class _GroupCaptioningScreenState extends State<GroupCaptioningScreen> {
	late final CaptioningController _controller;
	final ScrollController _scrollController = ScrollController();
	String? _lastShownError;

	@override
	void initState() {
		super.initState();
		_controller = CaptioningController(
			speakers: widget.speakers,
			conversationId: widget.conversationId,
			channel: widget.channel,
			broadcastStream: widget.broadcastStream,
		);
		_controller.addListener(_onControllerUpdated);
		WidgetsBinding.instance.addPostFrameCallback((_) {
			_controller.initialize();
		});
	}

	@override
	void dispose() {
		_controller.removeListener(_onControllerUpdated);
		_controller.dispose();
		_scrollController.dispose();
		super.dispose();
	}

	void _onControllerUpdated() {
		if (!mounted) {
			return;
		}

		if (_controller.captions.isNotEmpty && _scrollController.hasClients) {
			WidgetsBinding.instance.addPostFrameCallback((_) {
				if (_scrollController.hasClients) {
					_scrollController.animateTo(
						_scrollController.position.maxScrollExtent,
						duration: const Duration(milliseconds: 300),
						curve: Curves.easeOut,
					);
				}
			});
		}

		final error = _controller.errorMessage;
		if (error != null && error != _lastShownError) {
			_lastShownError = error;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(error), backgroundColor: Colors.red),
			);
		}
	}

	Future<int?> _showSpeakerCountDialog() {
		return showDialog<int>(
			context: context,
			barrierDismissible: false,
			builder: (ctx) {
				Widget countButton(int count) {
					return SizedBox(
						height: 54,
						child: ElevatedButton(
							onPressed: () => Navigator.of(ctx).pop(count),
							style: ElevatedButton.styleFrom(
								backgroundColor: AppColors.accent,
								foregroundColor: Colors.white,
								shape: RoundedRectangleBorder(
									borderRadius: BorderRadius.circular(12),
								),
							),
							child: Text(
								'$count',
								style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
							),
						),
					);
				}

				return AlertDialog(
					backgroundColor: AppColors.softSurface,
					title: const Text(
						'How many people?',
						style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700),
					),
					content: Column(
						mainAxisSize: MainAxisSize.min,
						children: <Widget>[
							const Text(
								'Choose the number of speakers for this session.',
								style: TextStyle(color: AppColors.textMuted),
							),
							const SizedBox(height: 14),
							Row(
								children: <Widget>[
									Expanded(child: countButton(2)),
									const SizedBox(width: 8),
									Expanded(child: countButton(3)),
									const SizedBox(width: 8),
									Expanded(child: countButton(4)),
									const SizedBox(width: 8),
									Expanded(child: countButton(5)),
								],
							),
							const SizedBox(height: 8),
							Row(
								children: <Widget>[
									Expanded(child: countButton(6)),
									const SizedBox(width: 8),
									Expanded(
										child: SizedBox(
											height: 54,
											child: OutlinedButton(
												onPressed: () => Navigator.of(ctx).pop(),
												style: OutlinedButton.styleFrom(
													foregroundColor: AppColors.accent,
													side: const BorderSide(color: AppColors.accent),
													shape: RoundedRectangleBorder(
														borderRadius: BorderRadius.circular(12),
													),
												),
												child: const Text('Cancel'),
											),
										),
									),
								],
							),
						],
					),
				);
			},
		);
	}

	Color _speakerColor(String speaker) {
		final hash = speaker.hashCode;
		return AppColors.speakerPalette[hash.abs() % AppColors.speakerPalette.length];
	}

	@override
	Widget build(BuildContext context) {
		return CaptioningProvider(
			controller: _controller,
			child: AnimatedBuilder(
				animation: _controller,
				builder: (context, child) {
					return Scaffold(
						backgroundColor: AppColors.warmGold,
						body: Column(
							children: <Widget>[
								if (_controller.errorMessage != null)
									Container(
										width: double.infinity,
										padding: const EdgeInsets.all(16),
										margin: const EdgeInsets.all(16),
										decoration: BoxDecoration(
											color: Colors.red.shade100,
											border: Border.all(color: Colors.red.shade300),
											borderRadius: BorderRadius.circular(8),
										),
										child: Row(
											children: <Widget>[
												Icon(Icons.error, color: Colors.red.shade700),
												const SizedBox(width: 8),
												Expanded(
													child: Text(
														_controller.errorMessage!,
														style: TextStyle(color: Colors.red.shade700),
													),
												),
												IconButton(
													icon: const Icon(Icons.close),
													onPressed: _controller.clearError,
												),
											],
										),
									),
								if (!_controller.hasPreconnectedChannel &&
										!_controller.isRecording &&
										!_controller.isConnecting)
									Container(
										padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
										child: SizedBox(
											width: double.infinity,
											child: OutlinedButton.icon(
												onPressed: () {
													Navigator.push(
														context,
														MaterialPageRoute(builder: (_) => const SpeakerSetupScreen()),
													);
												},
												icon: const Icon(Icons.people),
												style: OutlinedButton.styleFrom(
													minimumSize: const Size(double.infinity, 46),
													foregroundColor: AppColors.accent,
													side: const BorderSide(color: AppColors.accent),
													shape: RoundedRectangleBorder(
														borderRadius: BorderRadius.circular(12),
													),
												),
												label: const Text('New Session with Named Speakers'),
											),
										),
									),
								Container(
									padding: const EdgeInsets.all(16),
									child: Row(
										children: <Widget>[
											Expanded(
												child: ElevatedButton.icon(
													onPressed: (_controller.isRecording || _controller.isConnecting)
															? null
															: () => _controller.startSession(
																		selectSpeakerCount: _showSpeakerCountDialog,
																	),
													icon: _controller.isConnecting
															? const SizedBox(
																	width: 20,
																	height: 20,
																	child: CircularProgressIndicator(strokeWidth: 2),
																)
															: Icon(
																	_controller.isRecording
																			? Icons.stop
																			: Icons.play_arrow,
																),
													style: ElevatedButton.styleFrom(
														minimumSize: const Size(double.infinity, 50),
														backgroundColor: _controller.isRecording
																? Colors.red
																: AppColors.richBrown,
														foregroundColor: Colors.white,
													),
													label: Text(
														_controller.isConnecting
																? 'Connecting...'
																: _controller.isRecording
																? 'Session Active'
																: 'Start Captioning',
													),
												),
											),
											const SizedBox(width: 16),
											ElevatedButton.icon(
												onPressed: _controller.isRecording
														? () => _controller.endSession()
														: null,
												icon: const Icon(Icons.stop),
												style: ElevatedButton.styleFrom(
													backgroundColor: Colors.red,
													foregroundColor: Colors.white,
												),
												label: const Text('End'),
											),
										],
									),
								),
								Expanded(
									child: Container(
										margin: const EdgeInsets.all(16),
										padding: const EdgeInsets.all(16),
										decoration: BoxDecoration(
											color: AppColors.softSurface,
											borderRadius: BorderRadius.circular(16),
											boxShadow: const <BoxShadow>[
												BoxShadow(
													blurRadius: 10,
													color: Colors.black12,
													offset: Offset(0, 4),
												),
											],
										),
										child: _controller.captions.isEmpty
												? const Center(
														child: Text(
															'No captions yet. Start a session to begin.',
															style: TextStyle(
																color: AppColors.textMuted,
																fontSize: 16,
															),
															textAlign: TextAlign.center,
														),
													)
												: ListView.builder(
														controller: _scrollController,
														itemCount: _controller.captions.length,
														itemBuilder: (context, index) {
															final caption = _controller.captions[index];
															return CaptionTile(
																caption: caption,
																speakerColor: _speakerColor(caption.speaker),
															);
														},
													),
									),
								),
							],
						),
						floatingActionButton: FloatingActionButton(
							onPressed: () {
								Navigator.push(
									context,
									MaterialPageRoute(builder: (_) => const CaptionReviewScreen()),
								);
							},
							backgroundColor: AppColors.accent,
							tooltip: 'View Caption History',
							child: const Icon(Icons.history),
						),
					);
				},
			),
		);
	}
}
