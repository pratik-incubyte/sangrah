import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/gallery_bloc.dart';

class MemoryDebugPanel extends StatelessWidget {
  const MemoryDebugPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GalleryBloc, GalleryState>(
      builder: (context, state) {
        if (state is! GalleryLoaded) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Memory Statistics',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ..._buildMemoryStats(state.memoryStats),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildMemoryStats(Map<String, dynamic> stats) {
    return stats.entries.map((entry) {
      Color valueColor = Colors.green;
      
      // Color coding based on values
      if (entry.key == 'estimatedMemoryMB') {
        final double memoryMB = double.tryParse(entry.value.toString()) ?? 0;
        if (memoryMB > 100) {
          valueColor = Colors.red;
        } else if (memoryMB > 50) {
          valueColor = Colors.orange;
        }
      } else if (entry.key == 'cachedThumbnails') {
        final int cached = int.tryParse(entry.value.toString()) ?? 0;
        if (cached > 300) {
          valueColor = Colors.orange;
        } else if (cached > 500) {
          valueColor = Colors.red;
        }
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _formatStatName(entry.key),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
            Text(
              entry.value.toString(),
              style: TextStyle(
                color: valueColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _formatStatName(String key) {
    switch (key) {
      case 'totalItems':
        return 'Total Items:';
      case 'cachedThumbnails':
        return 'Cached Thumbnails:';
      case 'estimatedMemoryMB':
        return 'Est. Memory (MB):';
      case 'loadedPages':
        return 'Loaded Pages:';
      case 'currentWindow':
        return 'Current Window:';
      case 'windowSize':
        return 'Window Size:';
      default:
        return '${key.replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')}:';
    }
  }
}

/// Floating action button to toggle debug panel visibility
class MemoryDebugFab extends StatefulWidget {
  const MemoryDebugFab({super.key});

  @override
  State<MemoryDebugFab> createState() => _MemoryDebugFabState();
}

class _MemoryDebugFabState extends State<MemoryDebugFab> {
  bool _showDebugPanel = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_showDebugPanel)
          Positioned(
            bottom: 80,
            right: 16,
            child: const MemoryDebugPanel(),
          ),
        FloatingActionButton(
          mini: true,
          onPressed: () {
            setState(() {
              _showDebugPanel = !_showDebugPanel;
            });
          },
          backgroundColor: _showDebugPanel ? Colors.red : Colors.blue,
          child: Icon(
            _showDebugPanel ? Icons.close : Icons.memory,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
