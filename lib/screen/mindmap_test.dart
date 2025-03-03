import 'package:flutter/material.dart';
import 'package:flutter_application_1/widget/mind_map.dart';

void main() => runApp(const MindMapApp());

class MindMapApp extends StatelessWidget {
  const MindMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '思维导图示例',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MindMapExample(),
    );
  }
}

class MindMapExample extends StatefulWidget {
  const MindMapExample({super.key});

  @override
  State<MindMapExample> createState() => _MindMapExampleState();
}

class _MindMapExampleState extends State<MindMapExample> {
  late MindMapNode rootNode;
  int _nodeCounter = 1;
  MindMapNode? r2;
  MindMapNode? r1;
  final MindMapController _controller = MindMapController();

  @override
  void initState() {
    super.initState();
    // 初始化根节点并添加示例节点
    rootNode = MindMapHelper.createRoot(
      text: "中心主题",
      position: const Offset(400, 300), // 初始位置
    );
    // 添加初始子节点
    r1 = MindMapHelper.addChildNode(rootNode, "右节点1");
    MindMapHelper.addChildNode(rootNode, "左节点1", left: true);

    r2 = MindMapHelper.addChildNode(rootNode, "右节点2");
    _nodeCounter += 3;
  }

  void _addNode(bool left) {
    setState(() {
      MindMapHelper.addChildNode(
        r1!,
        "节点${_nodeCounter++}",
        left: left,
      );
      var n = MindMapHelper.addChildNode(
        r2!,
        "节点${_nodeCounter++}",
        left: left,
      );

      MindMapHelper.organizeTree(rootNode);

      _controller.centerNode(n);
      _controller.highlightNode(n.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('思维导图测试')),
      body: MindMap(
        width: double.infinity,
        height: double.infinity,
        rootNode: rootNode,
        onUpdated: () => setState(() {}),
        controller: _controller,
        onNodeTap: (node) {
          print("点击了节点: ${node.text}");
          _controller.highlightNode(node.id);
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'right',
            onPressed: () => _addNode(false),
            child: const Icon(Icons.arrow_forward),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'left',
            onPressed: () => _addNode(true),
            child: const Icon(Icons.arrow_back),
          ),
        ],
      ),
    );
  }
}
