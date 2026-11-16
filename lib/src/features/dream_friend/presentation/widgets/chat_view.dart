import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sleepy/src/features/dream_friend/application/dream_friend_controller.dart';
import 'package:sleepy/src/features/dream_friend/presentation/widgets/chat_message.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ChatView extends ConsumerStatefulWidget {
  const ChatView({super.key});
  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = const [
    ChatMessage(text: '꿈친구에게 오늘 있었던 일을 이야기해봐!', isUser: false),
  ].toList();

  bool _isLoading = false;

  // STT
  final SpeechToText _speechToText = SpeechToText();
  bool _speechAvailable = false;   // 디바이스/서비스 사용 가능 여부
  bool _hasPermission = false;     // 마이크/음성권한
  bool _isListening = false;

  // TTS
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
  }

  Future<void> _initSpeech() async {
    final available = await _speechToText.initialize(
      onError: (e) {
        // 필요하면 로그/토스트 등
      },
      onStatus: (status) {
        // status: listening / notListening 등
      },
      debugLogging: false,
    );
    _hasPermission = await _speechToText.hasPermission;
    _speechAvailable = available && _hasPermission;
    setState(() {});
  }

  Future<void> _initTts() async {
    // 말하기 완료를 기다리도록 설정(연속 요청 안정화)
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.setLanguage("ko-KR");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
  }

  @override
  void dispose() {
    _textController.dispose();
    _speechToText.cancel(); // stop 대신 cancel로 깔끔 종료
    _flutterTts.stop();
    super.dispose();
  }

  // 듣기 시작
  Future<void> _startListening() async {
    if (!_speechAvailable) {
      // 권한이 없거나 디바이스 미지원
      return;
    }
    // TTS가 말하고 있으면 중지
    await _flutterTts.stop();

    setState(() => _isListening = true);
    final ok = await _speechToText.listen(
      onResult: _onSpeechResult,
      listenOptions: SpeechListenOptions(
        partialResults: true, // 기존 partialResults 대신
        listenMode: ListenMode.dictation,
        cancelOnError: false,
      ),
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 3),
      localeId: 'ko_KR',
    );

    if (!ok) {
      setState(() => _isListening = false);
    }
  }

  // 듣기 중지
  Future<void> _stopListening() async {
    if (!_isListening) return;
    await _speechToText.stop();
    setState(() => _isListening = false);
  }

  // 음성 인식 결과
  void _onSpeechResult(SpeechRecognitionResult result) {
    // partialResults=true면 중간중간 호출됨
    _textController.text = result.recognizedWords;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textController.text.length),
    );
  }

  // 말하기
  Future<void> _speak(String text) async {
    // 말하기 전에 항상 STT 정지(하울링/충돌 방지)
    if (_isListening) await _stopListening();
    if (text.trim().isEmpty) return;
    await _flutterTts.speak(text);
  }

  // 메시지 전송 (STT+TTS 연동)
  Future<void> _handleSubmitted(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    if (_isListening) {
      await _stopListening();
    }

    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(text: query, isUser: true));
      _isLoading = true;
    });

    try {
      final dreamFriendController = ref.read(dreamFriendControllerProvider.notifier);
      final String response = await dreamFriendController.sendMessage(query);
      await _speak(response);
    } catch (e) {
      const errorMessage = '오류가 발생했어요. 다시 시도해주세요.';
      await _speak(errorMessage);
      setState(() {
        _messages.add(const ChatMessage(text: errorMessage, isUser: false));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dreamFriendState = ref.watch(dreamFriendControllerProvider);
    final messages = dreamFriendState.messages;
    final micIcon = _speechToText.isListening ? Icons.mic_off : Icons.mic;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: messages.length,
            itemBuilder: (context, index) => _buildChatBubble(messages[index]),
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 8.0),
                Text("꿈친구가 답변을 만들고 있어요..."),
              ],
            ),
          ),
        const Divider(height: 1.0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  onSubmitted: _handleSubmitted,
                  decoration: InputDecoration.collapsed(
                    hintText: _speechToText.isListening ? '듣고 있어요...' : '메시지 보내기',
                  ),
                ),
              ),
              IconButton(
                icon: Icon(micIcon),
                onPressed: _speechToText.isListening ? _stopListening : _startListening,
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _isLoading ? null : () => _handleSubmitted(_textController.text),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: isUser ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
