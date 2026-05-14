import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/ride_model.dart';

class _C {
  static const primary   = Color(0xFF414833); // Primary Action
  static const dark      = Color(0xFF414833); // Header/Black
  static const accent    = Color(0xFF737A5D); // Accent
  static const black     = Color(0xFF414833);
  static const white     = Color(0xFFF5E3D2);
  static const textDark  = Color(0xFF414833);
  static const textMuted = Color(0xFF737A5D);
  static const bg        = Color(0xFFF5E3D2);
}

class FareNegotiateScreen extends StatefulWidget {
  final RideModel ride;
  const FareNegotiateScreen({super.key, required this.ride});
  @override
  State<FareNegotiateScreen> createState() => _FareNegotiateScreenState();
}

class _FareNegotiateScreenState extends State<FareNegotiateScreen> {
  final _offerCtrl   = TextEditingController();
  final _scrollCtrl  = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isConfirmed  = false;
  bool _isSending    = false;

  @override
  void initState() {
    super.initState();
    // Initial system message
    _messages.add(_ChatMessage(
      text:       'Captain is offering Rs ${widget.ride.offeredFare}. Make your offer.',
      isSystem:   true,
      time:       _now(),
    ));
  }

  String _now() {
    final t = TimeOfDay.now();
    return '${t.hour}:${t.minute.toString().padLeft(2, '0')}';
  }

  void _sendOffer() {
    if (_offerCtrl.text.isEmpty) return;
    final offer = _offerCtrl.text.trim();
    setState(() {
      _isSending = true;
      _messages.add(_ChatMessage(
        text:      'My offer: Rs $offer',
        isMe:      true,
        time:      _now(),
      ));
      _offerCtrl.clear();
    });

    // Simulate captain response
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isSending = false;
          final captainFare  = widget.ride.offeredFare ?? 120;
          final offerDouble  = double.tryParse(offer) ?? 0;
          final diff         = captainFare - offerDouble;

          if (diff <= 0) {
            _messages.add(_ChatMessage(
              text:      'Deal accepted! Rs $offer confirmed.',
              isSystem:  true,
              isAccepted: true,
              time:       _now(),
            ));
            _isConfirmed = true;
          } else if (diff <= 20) {
            final counter = (offerDouble + (diff / 2)).round();
            _messages.add(_ChatMessage(
              text: 'How about Rs $counter? That works for me.',
              isMe: false,
              time: _now(),
            ));
          } else {
            _messages.add(_ChatMessage(
              text: 'That\'s too low. My minimum is Rs ${captainFare - 20}.',
              isMe: false,
              time: _now(),
            ));
          }
        });
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _offerCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 160,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_C.dark, Color(0xFF414833)],
                  begin: Alignment.topLeft,
                  end:   Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft:  Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: _C.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: _C.white, size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: _C.white.withOpacity(0.2),
                        child: Text(
                          (widget.ride.captainName ?? 'C')[0].toUpperCase(),
                          style: const TextStyle(
                            color: _C.white, fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.ride.captainName ?? 'Captain',
                              style: const TextStyle(
                                color: _C.white, fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${widget.ride.from} → ${widget.ride.to}',
                              style: TextStyle(
                                color: _C.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _C.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Rs ${widget.ride.offeredFare}',
                          style: const TextStyle(
                            color: _C.white, fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Chat messages
                Expanded(
                  child: ListView.builder(
                    controller:  _scrollCtrl,
                    physics:     const BouncingScrollPhysics(),
                    padding:     const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount:   _messages.length,
                    itemBuilder: (context, i) =>
                        _ChatBubble(message: _messages[i]),
                  ),
                ),

                // Input area
                if (!_isConfirmed)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                    decoration: BoxDecoration(
                      color: _C.white,
                      border: const Border(top: BorderSide(color: Color(0xFFCCBFA3), width: 1)),
                      boxShadow: [
                        BoxShadow(
                          color:      Colors.black.withOpacity(0.02),
                          blurRadius: 20,
                          offset:     const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color:        _C.bg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFCCBFA3)),
                            ),
                            child: TextField(
                              controller:   _offerCtrl,
                              keyboardType: TextInputType.number,
                              style:        const TextStyle(
                                color: _C.textDark, fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: const InputDecoration(
                                hintText:       'Your offer in Rs...',
                                hintStyle:      TextStyle(color: _C.textMuted, fontWeight: FontWeight.w500),
                                prefixText:     'Rs  ',
                                prefixStyle:    TextStyle(
                                  color:      _C.textDark,
                                  fontWeight: FontWeight.w800,
                                  fontSize:   15,
                                ),
                                border:         InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _isSending ? null : _sendOffer,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color:        _isSending
                                  ? const Color(0xFFCCBFA3) : _C.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: _isSending
                                ? const Center(
                                    child: SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(
                                        color: _C.white, strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.send_rounded,
                                    color: _C.white, size: 22,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // Confirmed state
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                    decoration: BoxDecoration(
                      color: _C.white,
                      border: const Border(top: BorderSide(color: Color(0xFFCCBFA3), width: 1)),
                    ),
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(
                              context, '/active-ride'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.primary,
                        foregroundColor: _C.white,
                        minimumSize: const Size(double.infinity, 56),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Confirm & Start Ride',
                        style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isMe;
  final bool isSystem;
  final bool isAccepted;
  final String time;

  _ChatMessage({
    required this.text,
    this.isMe       = false,
    this.isSystem   = false,
    this.isAccepted = false,
    required this.time,
  });
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color:        message.isAccepted
                  ? _C.primary.withOpacity(0.1)
                  : const Color(0xFFCCBFA3).withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: message.isAccepted
                  ? Border.all(color: _C.primary.withOpacity(0.4))
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.isAccepted) ...[
                  const Icon(Icons.check_circle_rounded,
                      color: _C.primary, size: 16),
                  const SizedBox(width: 8),
                ],
                Text(
                  message.text,
                  style: TextStyle(
                    color:      _C.textDark,
                    fontSize:   13,
                    fontWeight: message.isAccepted
                        ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: message.isMe
          ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:        message.isMe ? _C.primary : _C.white,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(20),
            topRight:    const Radius.circular(20),
            bottomLeft:  Radius.circular(message.isMe ? 20 : 4),
            bottomRight: Radius.circular(message.isMe ? 4 : 20),
          ),
          border: message.isMe ? null : Border.all(color: const Color(0xFFCCBFA3), width: 1),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset:     const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color:    message.isMe ? _C.white : _C.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message.time,
              style: TextStyle(
                color:    message.isMe
                    ? _C.white.withOpacity(0.6) : _C.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


