import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sleepy/src/core/services/auth_service.dart';
import 'package:sleepy/src/core/services/database_service.dart';
import 'package:sleepy/src/features/dream_friend/domain/dream_friend.dart';
import 'package:uuid/uuid.dart';

class DreamFriendEditScreen extends ConsumerStatefulWidget {
  // 이전 화면에서 전달받는 꿈친구 객체. null이면 '추가 모드'.
  final DreamFriend? friend;

  const DreamFriendEditScreen({super.key, this.friend});

  @override
  ConsumerState<DreamFriendEditScreen> createState() =>
      _DreamFriendEditScreenState();
}

class _DreamFriendEditScreenState extends ConsumerState<DreamFriendEditScreen> {
  // 폼의 상태를 관리하기 위한 글로벌 키
  final _formKey = GlobalKey<FormState>();
  // 텍스트 필드를 제어하기 위한 컨트롤러
  late final TextEditingController _nameController;
  late final TextEditingController _personaController;

  bool _isLoading = false; // 저장/삭제 진행 중 상태
  bool get _isEditMode => widget.friend != null; // 수정 모드 여부 확인

  @override
  void initState() {
    super.initState();
    // 위젯이 생성될 때, 전달받은 친구 정보로 컨트롤러 초기화
    _nameController = TextEditingController(text: widget.friend?.name ?? '');
    _personaController = TextEditingController(text: widget.friend?.persona ?? '');
  }

  @override
  void dispose() {
    // 위젯이 제거될 때 컨트롤러 리소스 해제
    _nameController.dispose();
    _personaController.dispose();
    super.dispose();
  }

  /// '저장' 버튼을 눌렀을 때 실행되는 함수
  Future<void> _saveFriend() async {
    // 폼의 모든 유효성 검사가 통과했는지 확인
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final dbService = ref.read(databaseServiceProvider);
      final userId = ref.read(authServiceProvider).currentUser!.uid;

      // 수정 모드이면 기존 ID 사용, 추가 모드이면 새로운 UUID 생성
      final friendId = widget.friend?.id ?? const Uuid().v4();

      final newFriend = DreamFriend(
        id: friendId,
        name: _nameController.text,
        persona: _personaController.text,
      );

      try {
        await dbService.setDreamFriend(userId, newFriend);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${newFriend.name} 정보가 저장되었어요!')),
          );
          context.pop(); // 이전 화면으로 돌아가기
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('저장에 실패했어요: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
  
  /// '삭제' 버튼을 눌렀을 때 실행되는 함수
  Future<void> _deleteFriend() async {
      // 사용자에게 정말 삭제할 것인지 다시 한번 확인
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('정말 삭제하시겠어요?'),
          content: Text('${widget.friend!.name}(와)과 나눈 모든 대화가 사라져요.'),
          actions: [
            TextButton(onPressed: () => context.pop(false), child: const Text('취소')),
            TextButton(
              onPressed: () => context.pop(true),
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed != true) return; // 사용자가 '취소'를 누르면 중단

      setState(() => _isLoading = true);
      final dbService = ref.read(databaseServiceProvider);
      final userId = ref.read(authServiceProvider).currentUser!.uid;

      try {
        await dbService.deleteDreamFriend(userId, widget.friend!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${widget.friend!.name} 친구가 삭제되었어요.')),
          );
          context.pop(); // 이전 화면으로 돌아가기
        }
      } catch (e) {
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('삭제에 실패했어요: $e')),
          );
        }
      } finally {
         if (mounted) {
          setState(() => _isLoading = false);
        }
      }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 모드에 따라 AppBar 제목 변경
        title: Text(_isEditMode ? '꿈친구 수정' : '새 꿈친구 추가'),
        actions: [
          // 수정 모드일 때만 삭제 버튼 표시
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _isLoading ? null : _deleteFriend,
            ),
          // 저장 버튼
          IconButton(
            icon: const Icon(Icons.save_alt_outlined),
            onPressed: _isLoading ? null : _saveFriend,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 로딩 중이 아닐 때만 폼을 보여줌
          if (!_isLoading)
            Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '이름',
                        border: OutlineInputBorder(),
                        hintText: '꿈친구의 이름을 지어주세요.',
                      ),
                      validator: (value) =>
                          (value == null || value.isEmpty) ? '이름을 입력해주세요.' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _personaController,
                      decoration: const InputDecoration(
                        labelText: '페르소나 (성격/역할)',
                        border: OutlineInputBorder(),
                        hintText: '예: 항상 다정하고 친절하게 존댓말로 대답해주는 곰인형 친구',
                        helperText: '꿈친구의 성격, 말투, 역할을 자유롭게 설정해주세요. 구체적일수록 좋아요!',
                      ),
                      maxLines: 8,
                       validator: (value) =>
                          (value == null || value.isEmpty) ? '페르소나를 입력해주세요.' : null,
                    ),
                  ],
                ),
              ),
            ),
          // 로딩 중일 때 화면 전체에 로딩 인디케이터 표시
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}