import 'dart:async';
import 'package:flutter/foundation.dart';

abstract class MindMapControllable {
  void centerNodeById(String nodeId, {Duration duration});
  void highlightNode(List<String> nodeId);
}

class MindMapController {
  WeakReference<MindMapControllable>? _stateRef;

  void attach(MindMapControllable state) => _stateRef = WeakReference(state);
  void detach() => _stateRef = null;

  void centerNodeById(String nodeId,
      {Duration duration = const Duration(milliseconds: 500)}) {
    final state = _stateRef?.target;
    state?.centerNodeById(nodeId, duration: duration);
  }

  void highlightNodeById(List<String> nodeId) {
    final state = _stateRef?.target;
    state?.highlightNode(nodeId);
  }
} 