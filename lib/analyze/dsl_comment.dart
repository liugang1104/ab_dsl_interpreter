import 'analyzer.dart';

/// 注释节点解析
extension CommentImplUtil on CommentImpl {
  List<String> translateToJson() {
    List<String> comments = [];
    for (final node in childEntities.whereType<DartDocToken>()) {
      String comment = node.lexeme;
      comments.add(comment);
    }
    return comments;
  }
}
