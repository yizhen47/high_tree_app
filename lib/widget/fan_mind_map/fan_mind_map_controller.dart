abstract class FanMindMapControllable {
  void highlightNode(List<String> nodeId);
}

class FanMindMapController {
  FanMindMapControllable? _controllable;

  void attach(FanMindMapControllable controllable) {
    _controllable = controllable;
  }

  void detach() {
    _controllable = null;
  }

  /// 高亮指定ID的节点
  void highlightNodeById(List<String> nodeIds) {
    _controllable?.highlightNode(nodeIds);
  }

  /// 高亮单个节点
  void highlightSingleNode(String nodeId) {
    highlightNodeById([nodeId]);
  }

  /// 清除所有高亮
  void clearHighlight() {
    highlightNodeById([]);
  }
} 