/// ============================================================================
/// MARKDOWN TEXT WIDGET - Markdown Renderer for Chat
/// ============================================================================
library;

import 'package:flutter/material.dart';

/// A widget that renders markdown formatting commonly used in AI responses
/// Supports: **bold**, *italic*, `code`, # headings, - bullet points, numbered lists
class MarkdownText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final Color? textColor;

  const MarkdownText({
    super.key,
    required this.text,
    this.baseStyle,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = baseStyle ??
        TextStyle(
          color: textColor ?? Colors.white,
          fontSize: 16,
          height: 1.4,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildParagraphs(text, defaultStyle),
    );
  }

  List<Widget> _buildParagraphs(String text, TextStyle baseStyle) {
    final List<Widget> widgets = [];
    final lines = text.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmedLine = line.trim();
      
      if (trimmedLine.isEmpty) {
        // Empty line - add spacing
        widgets.add(const SizedBox(height: 8));
        continue;
      }
      
      // Check for headings
      if (trimmedLine.startsWith('### ')) {
        widgets.add(_buildHeading(trimmedLine.substring(4), baseStyle, 3));
      } else if (trimmedLine.startsWith('## ')) {
        widgets.add(_buildHeading(trimmedLine.substring(3), baseStyle, 2));
      } else if (trimmedLine.startsWith('# ')) {
        widgets.add(_buildHeading(trimmedLine.substring(2), baseStyle, 1));
      }
      // Check for bullet points
      else if (trimmedLine.startsWith('- ') || trimmedLine.startsWith('• ')) {
        widgets.add(_buildBulletPoint(trimmedLine.substring(2), baseStyle));
      }
      // Check for numbered lists
      else if (RegExp(r'^\d+\.\s').hasMatch(trimmedLine)) {
        final match = RegExp(r'^(\d+)\.\s(.*)').firstMatch(trimmedLine);
        if (match != null) {
          widgets.add(_buildNumberedItem(match.group(1)!, match.group(2)!, baseStyle));
        }
      }
      // Regular paragraph
      else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: RichText(
            text: TextSpan(
              style: baseStyle,
              children: _parseInlineFormatting(trimmedLine, baseStyle),
            ),
          ),
        ));
      }
    }
    
    return widgets;
  }

  Widget _buildHeading(String text, TextStyle baseStyle, int level) {
    double fontSize;
    FontWeight fontWeight = FontWeight.bold;
    
    switch (level) {
      case 1:
        fontSize = baseStyle.fontSize! * 1.5;
        break;
      case 2:
        fontSize = baseStyle.fontSize! * 1.3;
        break;
      case 3:
      default:
        fontSize = baseStyle.fontSize! * 1.15;
        break;
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: RichText(
        text: TextSpan(
          style: baseStyle.copyWith(
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
          children: _parseInlineFormatting(text, baseStyle.copyWith(
            fontSize: fontSize,
            fontWeight: fontWeight,
          )),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text, TextStyle baseStyle) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•  ',
            style: baseStyle.copyWith(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: baseStyle,
                children: _parseInlineFormatting(text, baseStyle),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedItem(String number, String text, TextStyle baseStyle) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ',
            style: baseStyle.copyWith(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: baseStyle,
                children: _parseInlineFormatting(text, baseStyle),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _parseInlineFormatting(String text, TextStyle baseStyle) {
    final List<InlineSpan> spans = [];
    
    // Pattern for: ***bold italic***, **bold**, *italic*, `code`
    final RegExp pattern = RegExp(
      r'(\*\*\*(.+?)\*\*\*)|(\*\*(.+?)\*\*)|(\*(.+?)\*)|(`(.+?)`)',
    );

    int lastEnd = 0;

    for (final match in pattern.allMatches(text)) {
      // Add text before the match
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }

      // Bold and Italic (***text***)
      if (match.group(1) != null) {
        spans.add(TextSpan(
          text: match.group(2),
          style: baseStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ));
      }
      // Bold (**text**)
      else if (match.group(3) != null) {
        spans.add(TextSpan(
          text: match.group(4),
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ));
      }
      // Italic (*text*)
      else if (match.group(5) != null) {
        spans.add(TextSpan(
          text: match.group(6),
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      }
      // Code (`text`)
      else if (match.group(7) != null) {
        spans.add(TextSpan(
          text: ' ${match.group(8)} ',
          style: baseStyle.copyWith(
            fontFamily: 'monospace',
            backgroundColor: Colors.white.withOpacity(0.15),
            fontSize: baseStyle.fontSize! * 0.9,
          ),
        ));
      }

      lastEnd = match.end;
    }

    // Add remaining text after last match
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    // If no matches found, return the whole text
    if (spans.isEmpty) {
      spans.add(TextSpan(text: text));
    }

    return spans;
  }
}
