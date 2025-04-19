import 'package:flutter/material.dart';
import 'package:flutter_chatbot/theme/colors.dart';

class ExpandableInputField extends StatefulWidget {
  final void Function(String message) onSend;
  final TextEditingController controller;

  const ExpandableInputField({
    super.key,
    required this.onSend,
    required this.controller,
  });

  @override
  State<ExpandableInputField> createState() => _ExpandableInputFieldState();
}

class _ExpandableInputFieldState extends State<ExpandableInputField> {
  final FocusNode _focusNode = FocusNode();
  bool _showExpand = false;
  int _maxLines = 7;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChange);
  }

  void _handleTextChange() {
    final lines = '\n'.allMatches(widget.controller.text).length + 1;
    setState(() {
      _showExpand = lines >= 3; 
    });
  }

  void _send() {
    final text = widget.controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      widget.controller.clear();
    }
  }

  void _showExpandedSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;

        return SafeArea(
          child: Container(
            constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 16,
              left: 16,
              right: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: TextField(
                      controller: widget.controller,
                      maxLines: null,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: "Keep typing...",
                        hintStyle: TextStyle(color: AppColors.lightAquaText),
                        filled: true,
                        fillColor: AppColors.deepPurple.withOpacity(0.3),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      widget.onSend(widget.controller.text);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coolTeal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text(
                      "Send",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                maxLines: _maxLines,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: AppColors.lightAquaText),
                  filled: true,
                  fillColor: AppColors.deepPurple.withOpacity(0.3),
                  contentPadding: const EdgeInsets.fromLTRB(
                    16, // left
                    14, // top
                    40, // right padding for icon
                    14, // bottom
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_showExpand)
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.fullscreen,
                        size: 18, color: Colors.white),
                    onPressed: _showExpandedSheet,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _send,
          icon: const Icon(Icons.send, color: AppColors.goldSun),
        ),
      ],
    );
  }
}
