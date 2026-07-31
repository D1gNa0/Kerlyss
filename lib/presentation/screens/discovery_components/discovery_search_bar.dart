import 'dart:async';
import 'package:flutter/material.dart';
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: SizedBox(
        height: 60,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isFocused
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AetherColors.accentCyan,
                      AetherColors.primaryAccent,
                    ],
                  )
                : null,
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: AetherColors.accentCyan.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: AetherColors.primaryAccent.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          padding: EdgeInsets.all(isFocused ? 1.5 : 0),
          child: AetherGlass(
            borderRadius: isFocused ? 14.5 : 16,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, right: 10),
                  child: Icon(
                    Icons.search_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    textInputAction: TextInputAction.search,
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
                      } else if (searchState.searchMode == SearchMode.spotifyImport && value.isEmpty) {
                        ref.read(discoverySearchProvider.notifier).setSearchMode(SearchMode.songs);
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
                      hintText: 'Search songs or paste Spotify link...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.2),
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                if (hasText)
                  AetherIconButton(
                    tooltip: 'Clear search',
                    icon: Icons.close_rounded,
                    color: Colors.white70,
                    size: 18,
                    buttonSize: 40,
                    onPressed: () {
                      _debounceTimer?.cancel();
                      widget.controller.clear();
                      ref.read(discoverySearchProvider.notifier).setSearchMode(SearchMode.songs);
                      ref.read(discoverySearchProvider.notifier).onSearchQueryChanged('');
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
