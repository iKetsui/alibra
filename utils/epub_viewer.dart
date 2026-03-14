import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer_kit/flutter_epub_viewer_kit.dart';
import '../models/book.dart';
import '../database/hive.dart';

class SimpleEpubViewer extends StatefulWidget {
  final Book book;

  const SimpleEpubViewer({
    super.key,
    required this.book,
  });

  @override
  State<SimpleEpubViewer> createState() => _SimpleEpubViewerState();
}

class _SimpleEpubViewerState extends State<SimpleEpubViewer> {
  EpubReaderController? _controller;
  bool _isInitialized = false;
  String _errorMessage = '';
  
  // Local state for UI updates
  int _currentPage = 0;
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadBookState();
  }

  Future<void> _loadBookState() async {
    try {
      // Only fetch the progress/last page visited
      final dynamic savedProgress = await HiveService.getSetting('epub_progress_${widget.book.id}');
      
      _controller = EpubReaderController(
        // Convert dynamic to double safely
        initialProgress: (savedProgress as num?)?.toDouble() ?? 0.0,
        onPositionChanged: (position) {
          // SAVE: Last page visited/progress
          HiveService.saveSetting('epub_progress_${widget.book.id}', position.progress);
          
          if (mounted) {
            setState(() {
              _currentProgress = position.progress;
            });
          }
        },
      );

      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = "Error loading book: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage.isNotEmpty) {
      return Scaffold(body: Center(child: Text(_errorMessage)));
    }

    if (!_isInitialized || _controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: EpubReaderWidget(
        source: EpubSourceFile(widget.book.filePath),
        controller: _controller!,
        settingsStorageKey: 'epub_reader_settings_${widget.book.id}',
        topBarBuilder: (context, dynamic settings) => _buildTopBar(settings),
        bottomBarBuilder: (context, dynamic settings) => _buildBottomBar(settings),
        onPageChanged: (current, total) {
          setState(() => _currentPage = current);
        },
      ),
    );
  }

  PreferredSizeWidget _buildTopBar(dynamic settings) {
    return AppBar(
      backgroundColor: settings.backgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: settings.textColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.book.title,
            style: TextStyle(color: settings.textColor, fontSize: 14, fontWeight: FontWeight.bold),
            maxLines: 1,
          ),
          Text(
            'Page ${_currentPage + 1}',
            style: TextStyle(color: settings.textColor?.withOpacity(0.6), fontSize: 11),
          ),
        ],
      ),
      actions: [
        // Bookmark icon (Session-only: will show during use but won't save to DB)
        IconButton(
          icon: Icon(
            _controller!.isCurrentPageBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: settings.textColor,
          ),
          onPressed: () {
            _controller!.toggleBookmark();
            setState(() {}); 
          },
        ),
        IconButton(
          icon: Icon(Icons.tune, color: settings.textColor),
          onPressed: () => _controller!.showSettings(),
        ),
      ],
    );
  }

  Widget _buildBottomBar(dynamic settings) {
    return Container(
      color: settings.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea( // Ensures it looks good on iPhones/modern Androids
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left, color: settings.textColor),
              onPressed: () => _controller!.previousPage(),
            ),
            Expanded(
              child: Slider(
                value: _currentProgress.clamp(0.0, 1.0),
                onChanged: (val) => _controller!.goToProgress(val),
                activeColor: settings.textColor,
                inactiveColor: settings.textColor?.withOpacity(0.2),
              ),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right, color: settings.textColor),
              onPressed: () => _controller!.nextPage(),
            ),
          ],
        ),
      ),
    );
  }
}