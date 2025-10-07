import '../repositories/chat_repository.dart';

class StartProductDiscussion {
  final ChatRepository _repository;

  StartProductDiscussion(this._repository);

  Future<Map<String, dynamic>> call({
    required String productId,
    String? initialMessage,
  }) async {
    return await _repository.startProductDiscussion(
      productId: productId,
      initialMessage: initialMessage,
    );
  }
}


