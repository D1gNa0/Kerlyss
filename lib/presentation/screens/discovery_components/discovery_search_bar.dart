import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/aether_glass.dart';
import '../../common/vercel_hover_button.dart';
import '../../state/discovery_search_provider.dart';
import '../../theme/aether_colors.dart';
import 'package:kerlyss/l10n/app_localizations.dart';

class DiscoverySearchBar extends ConsumerStatefulWidget {
  final FocusNode focusNode;
  final TextEditingController controller;
  final VoidCallback onSearchTriggered;

  const DiscoverySearchBar({
    super.key,
    required this.focusNode,
    required this.controller,
    required this.onSearchTriggered,
  });

  @override
  ConsumerState<DiscoverySearchBar> createState() => _DiscoverySearchBarState();
}

class _DiscoverySearchBarState extends ConsumerState<DiscoverySearchBar> {
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onRebuild);
    widget.controller.addListener(_onRebuild);
  }

  @override
  void didUpdateWidget(DiscoverySearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onRebuild);
      widget.focusNode.addListener(_onRebuild);
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onRebuild);
      widget.controller.addListener(_onRebuild);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    widget.focusNode.removeListener(_onRebuild);
    widget.controller.removeListener(_onRebuild);
    super.dispose();
  }

  void _onRebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(discoverySearchProvider);
    final l10n = AppLocalizations.of(context)!;
    final isFocused = widget.focusNode.hasFocus;
    final hasText = widget.controller.text.isNotEmpty;

    final activeAccentColor = searchState.searchMode == SearchMode.spotifyImport
        ? Colors.lightGreenAccent
        : AetherColors.accentCyan;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Mode Selector Pills
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: searchState.searchMode == SearchMode.songs ? AetherColors.glassWhite : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: searchState.searchMode == SearchMode.songs ? Colors.white.withValues(alpha: 0.28) : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: VercelHoverButton(
                  onTap: () {
                    widget.controller.clear();
                    ref.read(discoverySearchProvider.notifier).setSearchMode(SearchMode.songs);
                  },
                  borderRadius: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text('SEARCH SONGS', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: searchState.searchMode == SearchMode.spotifyImport ? Colors.lightGreenAccent.withValues(alpha: 0.18) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: searchState.searchMode == SearchMode.spotifyImport ? Colors.lightGreenAccent.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: VercelHoverButton(
                  onTap: () {
                    widget.controller.clear();
                    ref.read(discoverySearchProvider.notifier).setSearchMode(SearchMode.spotifyImport);
                  },
                  borderRadius: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.queue_music_rounded, color: Colors.lightGreenAccent, size: 14),
                      SizedBox(width: 6),
                      Text('SPOTIFY IMPORT', style: TextStyle(color: Colors.lightGreenAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Box Input
          SizedBox(
            height: 60,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: const Color(0xFF121216),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isFocused ? activeAccentColor : Colors.white.withValues(alpha: 0.12),
                  width: isFocused ? 1.5 : 1.0,
                ),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: activeAccentColor.withValues(alpha: 0.25),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, right: 10),
                    child: Icon(
                      searchState.searchMode == SearchMode.spotifyImport
                          ? Icons.link_rounded
                          : Icons.search_rounded,
                      color: searchState.searchMode == SearchMode.spotifyImport
                          ? Colors.lightGreenAccent
                          : (isFocused ? AetherColors.accentCyan : Colors.white70),
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      textInputAction: TextInputAction.search,
                      enableInteractiveSelection: true,
                      selectionControls: materialTextSelectionControls,
                      contextMenuBuilder: (context, editableTextState) {
                        return AdaptiveTextSelectionToolbar.buttonItems(
                          anchors: editableTextState.contextMenuAnchors,
                          buttonItems: editableTextState.contextMenuButtonItems,
                        );
                      },
                      onSubmitted: (value) {
                        _debounceTimer?.cancel();
                        ref.read(discoverySearchProvider.notifier).onSearchQueryChanged(value);
                        widget.onSearchTriggered();
                        widget.focusNode.unfocus();
                      },
                      onChanged: (value) {
                        // Auto-detect Spotify playlist URL and switch mode automatically
                        if (RegExp(r'https?://open\.spotify\.com/playlist/').hasMatch(value) || value.contains('spotify.com')) {
                          if (searchState.searchMode != SearchMode.spotifyImport) {
                            ref.read(discoverySearchProvider.notifier).setSearchMode(SearchMode.spotifyImport);
                          }
                        }
                        ref.read(discoverySearchProvider.notifier).onSearchQueryChanged(value);
                        _debounceTimer?.cancel();
                        _debounceTimer = Timer(const Duration(milliseconds: 600), () {
                          if (mounted) {
                            widget.onSearchTriggered();
                          }
                        });
                      },
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: searchState.searchMode == SearchMode.spotifyImport
                            ? l10n.pasteSpotifyLink
                            : l10n.searchPlaceholder,
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 12,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  if (searchState.searchMode == SearchMode.spotifyImport && !hasText)
                    AetherIconButton(
                      tooltip: 'Paste from clipboard',
                      icon: Icons.content_paste_rounded,
                      color: Colors.lightGreenAccent,
                      size: 18,
                      buttonSize: 40,
                      onPressed: () async {
                        final data = await Clipboard.getData(Clipboard.kTextPlain);
                        if (data?.text != null && data!.text!.isNotEmpty) {
                          widget.controller.text = data.text!;
                          widget.controller.selection = TextSelection.collapsed(offset: data.text!.length);
                          ref.read(discoverySearchProvider.notifier).onSearchQueryChanged(data.text!);
                          widget.onSearchTriggered();
                        }
                      },
                    )
                  else if (hasText)
                    AetherIconButton(
                      tooltip: 'Clear search',
                      icon: Icons.close_rounded,
                      color: Colors.white70,
                      size: 18,
                      buttonSize: 40,
                      onPressed: () {
                        _debounceTimer?.cancel();
                        widget.controller.clear();
                        ref.read(discoverySearchProvider.notifier).onSearchQueryChanged('');
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
