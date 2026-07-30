import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/aether_glass.dart';
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
        child: SizedBox(
          height: 60,
          child: AetherGlass(
            borderRadius: isFocused ? 14.5 : 16,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    searchState.searchMode == SearchMode.spotifyImport
                        ? Icons.queue_music_rounded
                        : Icons.search_rounded,
                    color: searchState.searchMode == SearchMode.spotifyImport
                        ? Colors.lightGreenAccent
                        : (isFocused ? AetherColors.accentCyan : Colors.white24),
                    size: 20,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: () {
                    widget.controller.clear();
                    ref.read(discoverySearchProvider.notifier).toggleSearchMode();
                  },
                  tooltip: l10n.toggleSpotifyMode,
                ),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) {
                      ref.read(discoverySearchProvider.notifier).onSearchQueryChanged(value);
                      widget.onSearchTriggered();
                      widget.focusNode.unfocus();
                    },
                    onChanged: (value) {
                      ref.read(discoverySearchProvider.notifier).onSearchQueryChanged(value);
                      Future.delayed(const Duration(milliseconds: 600), widget.onSearchTriggered);
                    },
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: searchState.searchMode == SearchMode.spotifyImport
                          ? l10n.pasteSpotifyLink
                          : l10n.searchPlaceholder,
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.2),
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                if (hasText)
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white54,
                      size: 20,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: () {
                      widget.controller.clear();
                      ref.read(discoverySearchProvider.notifier).onSearchQueryChanged('');
                    },
                    tooltip: 'Clear',
                  ),
                if (searchState.searchMode == SearchMode.spotifyImport)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: searchState.downloadOnImport,
                        activeColor: Colors.lightGreenAccent,
                        checkColor: Colors.black,
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(discoverySearchProvider.notifier).toggleDownloadOnImport(val);
                          }
                        },
                      ),
                      Text(l10n.download, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
