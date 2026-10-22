import 'package:flutter/material.dart';

import '../models/repair_session.dart';
import '../services/ai_service.dart';
import '../services/voice_service.dart';

class VoiceScreen extends StatefulWidget {
  /// Optional: gives the assistant the current repair as context.
  final RepairSession? session;
  const VoiceScreen({super.key, this.session});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final _voice = VoiceService();
  final _ai = AiService();
  final _messages = <ChatMessage>[
    const ChatMessage(
      text: "Hi, I'm Fixora. Ask me anything about your repair.",
      isUser: false,
    ),
  ];
  final _textController = TextEditingController();
  final _scroll = ScrollController();

  bool _listening = false;
  bool _thinking = false;
  bool _autoSpeak = true;
  String _partial = '';
  String? _notice;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _voice.dispose();
    _textController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final ready = await _voice.init(
      onStatus: (s) {
        if (!mounted) return;
        if (s == 'done' || s == 'notListening') {
          setState(() => _listening = false);
        }
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _listening = false;
          _notice = 'Voice error: $e';
        });
      },
    );
    if (!mounted) return;
    if (!ready) {
      setState(() => _notice =
          'Speech recognition is unavailable. You can type your question instead.');
    }
  }

  Future<void> _toggleMic() async {
    if (_listening) {
      await _voice.stopListening();
      if (mounted) setState(() => _listening = false);
      return;
    }
    await _voice.stopSpeaking();
    setState(() {
      _listening = true;
      _partial = '';
      _notice = null;
    });
    await _voice.startListening(
      onResult: (words, isFinal) {
        if (!mounted) return;
        setState(() => _partial = words);
        if (isFinal) {
          setState(() => _listening = false);
          _send(words);
        }
      },
    );
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _thinking) return;

    // Gemini expects the conversation to start with a user turn.
    final history = _messages.skipWhile((m) => !m.isUser).toList();

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _thinking = true;
      _partial = '';
      _textController.clear();
    });
    _scrollToEnd();

    String reply;
    try {
      reply = await _ai.chat(
        question: text,
        context: widget.session?.diagnosis,
        history: history,
      );
    } catch (e) {
      reply = 'Sorry, I could not answer that. $e';
    }
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(text: reply, isUser: false));
      _thinking = false;
    });
    _scrollToEnd();
    if (_autoSpeak) await _voice.speak(reply);
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = widget.session;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice assistant'),
        actions: [
          IconButton(
            tooltip: _autoSpeak ? 'Mute replies' : 'Speak replies',
            icon: Icon(_autoSpeak ? Icons.volume_up : Icons.volume_off),
            onPressed: () {
              setState(() => _autoSpeak = !_autoSpeak);
              if (!_autoSpeak) _voice.stopSpeaking();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (session != null)
            Container(
              width: double.infinity,
              color: theme.colorScheme.primaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Helping with: ${session.diagnosis.faultName}',
                style: theme.textTheme.labelLarge,
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_thinking ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length) {
                  return const _Bubble(text: 'Thinking...', isUser: false);
                }
                final m = _messages[i];
                return _Bubble(text: m.text, isUser: m.isUser);
              },
            ),
          ),
          if (_notice != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(_notice!,
                  style: TextStyle(color: theme.colorScheme.error)),
            ),
          if (_listening)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                _partial.isEmpty ? 'Listening...' : _partial,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                      decoration: InputDecoration(
                        hintText: 'Type or tap the mic...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => _send(_textController.text),
                  ),
                  FloatingActionButton(
                    onPressed: _toggleMic,
                    backgroundColor: _listening
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    child: Icon(_listening ? Icons.stop : Icons.mic),
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

class _Bubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const _Bubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: TextStyle(color: isUser ? scheme.onPrimary : scheme.onSurface),
        ),
      ),
    );
  }
}
