import 'package:equatable/equatable.dart';

// 대화 메시지를 나타내는 모델
class ChatMessage extends Equatable {
  const ChatMessage({required this.text, required this.isUser});
  final String text;
  final bool isUser;

  @override
  List<Object?> get props => [text, isUser];
}