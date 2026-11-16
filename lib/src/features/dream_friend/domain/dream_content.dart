import 'package:cloud_firestore/cloud_firestore.dart';

// Firestore의 콘텐츠 데이터를 담을 모델 클래스
class DreamContent {
  const DreamContent({
    required this.id,
    required this.title,
    this.artist,
    this.duration,
    required this.audioUrl,
  });

  final String id;
  final String title;
  final String? artist; // 자장가인 경우 사용
  final String? duration; // 콘텐츠 길이 (예: "3:45")
  final String audioUrl; // 오디오 파일이 저장된 경로

  factory DreamContent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DreamContent(
      id: doc.id,
      title: data['title'] as String? ?? '제목 없음',
      artist: data['artist'] as String?,
      duration: data['duration'] as String?,
      audioUrl: data['audioUrl'] as String? ?? '',
    );
  }
}