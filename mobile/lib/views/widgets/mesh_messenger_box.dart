import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class MeshMessengerBox extends StatelessWidget {
  final List<Map<String, String>> chatMessages;
  final TextEditingController controller;
  final Function(String message) onSend;

  const MeshMessengerBox({
    super.key,
    required this.chatMessages,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlush,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.forum_outlined, color: AppTheme.primaryBerry, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Offline Mesh Chat",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      "Sends packets directly to nearby phones without SIM or Internet",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Expanded Chat Messages Area
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: chatMessages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFFBDBDBD), size: 36),
                        const SizedBox(height: 8),
                        Text(
                          "No messages yet",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF757575),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "Type below to broadcast an offline message",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF9E9E9E),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    itemCount: chatMessages.length,
                    itemBuilder: (context, index) {
                      final item = chatMessages[chatMessages.length - 1 - index];
                      final isMe = item["sender"] == "Me";
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isMe ? AppTheme.primaryBerry : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(14),
                              topRight: const Radius.circular(14),
                              bottomLeft: isMe ? const Radius.circular(14) : Radius.zero,
                              bottomRight: isMe ? Radius.zero : const Radius.circular(14),
                            ),
                            border: isMe ? null : Border.all(color: const Color(0xFFEEEEEE)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                item["sender"] ?? "Unknown",
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isMe ? Colors.white70 : AppTheme.primaryBerry,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item["text"] ?? "",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: isMe ? Colors.white : AppTheme.textDark,
                                ),
                              ),
                              if (item["time"] != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item["time"]!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    color: isMe ? Colors.white60 : const Color(0xFF9E9E9E),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
        const SizedBox(height: 10),

        // Message Input Row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: GoogleFonts.poppins(color: AppTheme.textDark, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Type mesh message...",
                  hintStyle: GoogleFonts.poppins(color: const Color(0xFF9E9E9E), fontSize: 13),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppTheme.primaryBerry, width: 1.5),
                  ),
                ),
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    onSend(val.trim());
                    controller.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.primaryBerry,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    onSend(controller.text.trim());
                    controller.clear();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
