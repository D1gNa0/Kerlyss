import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/song_entity.dart';
import '../theme/aether_colors.dart';
import 'aether_glass.dart';
import '../../data/repositories/repository_providers.dart';

class TapBpmDialog extends ConsumerStatefulWidget {
  final SongEntity song;

  const TapBpmDialog({super.key, required this.song});

  @override
  ConsumerState<TapBpmDialog> createState() => _TapBpmDialogState();
}

class _TapBpmDialogState extends ConsumerState<TapBpmDialog> with SingleTickerProviderStateMixin {
  final List<DateTime> _taps = [];
  int _currentBpm = 0;
  bool _isSaving = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 1.0,
      upperBound: 1.08,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap() {
    final now = DateTime.now();
    _pulseController.forward().then((_) => _pulseController.reverse());

    // Reset if it's been more than 2.5 seconds since last tap
    if (_taps.isNotEmpty && now.difference(_taps.last).inMilliseconds > 2500) {
      _taps.clear();
    }

    setState(() {
      _taps.add(now);

      if (_taps.length > 1) {
        // Professional Moving Window: Only consider the last 10 taps for responsiveness
        final calculationWindow = _taps.length > 10 ? _taps.sublist(_taps.length - 10) : _taps;
        
        final durationMs = calculationWindow.last.difference(calculationWindow.first).inMilliseconds;
        if (durationMs > 0) {
          final beats = calculationWindow.length - 1;
          final minutes = durationMs / 60000.0;
          _currentBpm = (beats / minutes).round();
        }
      } else {
        _currentBpm = 0;
      }
    });
  }

  void _reset() {
    setState(() {
      _taps.clear();
      _currentBpm = 0;
    });
  }

  Future<void> _save() async {
    if (_currentBpm <= 0) return;
    setState(() => _isSaving = true);
    
    try {
      await ref.read(songRepositoryProvider).updateBpm(widget.song.id, _currentBpm);
      if (mounted) {
        Navigator.of(context).pop(_currentBpm);
      }
    } catch (e) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialBpm = widget.song.bpm;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: AetherGlass(
        borderRadius: 24,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'TAP TO DETECT BPM',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                letterSpacing: 2,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.song.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 32),
            
            // The huge Tap Button
            ScaleTransition(
              scale: _pulseController,
              child: GestureDetector(
                onTapDown: (_) => _handleTap(),
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _taps.isNotEmpty ? AetherColors.primaryAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                      color: _taps.isNotEmpty ? AetherColors.primaryAccent : Colors.white24,
                      width: 2,
                    ),
                    boxShadow: _taps.isNotEmpty ? [
                      BoxShadow(color: AetherColors.primaryAccent.withValues(alpha: 0.4), blurRadius: 20)
                    ] : [],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _currentBpm > 0 
                        ? '$_currentBpm' 
                        : (initialBpm != null ? '$initialBpm' : 'TAP'),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            Text(
              'Tap to the rhythm of the beat',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
            ),
            
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: _reset,
                  child: const Text('RESET', style: TextStyle(color: Colors.white54, letterSpacing: 1)),
                ),
                ElevatedButton(
                  onPressed: (_currentBpm > 0 && !_isSaving) ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AetherColors.primaryAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('SAVE BPM', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
