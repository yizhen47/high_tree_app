# 题库格式文档 (zip Format Specification)

## 概述

题库文件采用 `.zip` 扩展名，本质上是一个ZIP压缩包，包含XML数据文件和相关资源文件。此格式专为Flutter应用中的题库管理系统设计。

## 文件结构

```
example.zip (ZIP压缩包)
├── data.xml                    # 主数据文件 (必需)
├── assets/                     # 资源文件夹
│   └── images/                 # 图片资源
│       ├── rId1.png           # 图片文件
│       ├── rId2.png
│       └── ...
└── [其他资源文件]
```

## 数据结构

### 1. 根结构 (QuestionBank)

题库的XML根元素为 `<QuestionBank>`，包含以下属性：

```xml
<QuestionBank id="uuid" version="1" displayName="题库名称">
    <Sections>
        <!-- 章节内容 -->
    </Sections>
</QuestionBank>
```

**属性说明：**
- `id`: 题库唯一标识符 (UUID格式)
- `version`: 题库版本号 (整数)
- `displayName`: 题库显示名称

### 2. 章节结构 (Section)

章节采用树形结构，支持多级嵌套：

```xml
<Section index="1" title="第一章">
    <note>章节备注</note>
    <image>chapter1_overview.png</image>
    <videos>
        <video>video1.mp4</video>
        <video>video2.mp4</video>
    </videos>
    <children>
        <Section index="1.1" title="第一节">
            <!-- 子章节内容 -->
        </Section>
    </children>
    <questions>
        <!-- 题目内容 -->
    </questions>
    <fromKonwledgeIndex>
        <item>parent_index</item>
    </fromKonwledgeIndex>
    <fromKonwledgePoint>
        <item>parent_title</item>
    </fromKonwledgePoint>
</Section>
```

**字段说明：**
- `index`: 章节索引标识
- `title`: 章节标题
- `note`: 章节备注（可选）
- `image`: 章节概览图片（可选，用于思维导图）
- `videos`: 章节视频列表（可选）
- `children`: 子章节列表（可选）
- `questions`: 题目列表（可选）
- `fromKonwledgeIndex`: 父级知识点索引路径
- `fromKonwledgePoint`: 父级知识点标题路径

### 3. 题目结构 (Question)

每个题目包含完整的题目信息：

```xml
<question id="uuid">
    <q>题目内容</q>
    <w>参考答案</w>
    <note>题目备注</note>
    <video>解析视频路径</video>
    <options>
        <option key="A">选项A内容</option>
        <option key="B">选项B内容</option>
        <option key="C">选项C内容</option>
        <option key="D">选项D内容</option>
    </options>
    <answer>
        <item>A</item>
        <item>C</item>
    </answer>
</question>
```

**字段说明：**
- `id`: 题目唯一标识符 (UUID格式)
- `q`: 题目内容（必需）
- `w`: 参考答案/解析（必需）
- `note`: 题目备注（可选）
- `video`: 视频解析路径（可选）
- `options`: 选择题选项（可选）
- `answer`: 标准答案（可选，支持多选）

## 特殊格式

### 图片引用

#### 章节概览图片
章节的图片字段用于存储概览图片路径，主要用于思维导图展示：

```xml
<image>algebra_mindmap.png</image>
```

该图片通常是章节知识点的思维导图或概览图，帮助用户快速理解章节结构。

### 视频引用

视频文件支持相对路径引用：

```xml
<video>videos/chapter1/lesson1.mp4</video>
```

## 数据类型

### SingleQuestionData

单个题目的数据结构：

```dart
class SingleQuestionData {
  List<String> fromKonwledgePoint;   // 知识点路径
  List<String> fromKonwledgeIndex;   // 索引路径
  Map<String, dynamic> question;     // 题目内容
  String fromId;                     // 来源题库ID
  String fromDisplayName;            // 来源题库名称
}
```

### Section

章节的数据结构：

```dart
class Section {
  String index;                           // 章节索引
  String title;                           // 章节标题
  String? note;                           // 章节备注
  String? image;                          // 章节概览图片（思维导图用）
  List<Section>? children;                // 子章节
  List<Map<String, dynamic>>? questions;  // 题目列表
  List<String>? videos;                   // 视频列表
  List<String> fromKonwledgePoint;        // 父级知识点
  List<String> fromKonwledgeIndex;        // 父级索引
}
```

## 示例

### 完整的题库示例

```xml
<?xml version="1.0" encoding="UTF-8"?>
<QuestionBank id="550e8400-e29b-41d4-a716-446655440000" version="1" displayName="数学基础题库">
         <Sections>
         <Section index="1" title="代数">
             <note>代数基础知识</note>
             <image>algebra_mindmap.png</image>
             <videos>
                 <video>algebra_intro.mp4</video>
             </videos>
             <children>
                <Section index="1.1" title="一元二次方程">
                    <questions>
                        <question id="q001">
                            <q>解方程 x² + 5x + 6 = 0</q>
                            <w>x = -2 或 x = -3</w>
                            <video>quadratic_solution.mp4</video>
                            <options>
                                <option key="A">x = -2 或 x = -3</option>
                                <option key="B">x = 2 或 x = 3</option>
                                <option key="C">x = -1 或 x = -6</option>
                                <option key="D">x = 1 或 x = 6</option>
                            </options>
                            <answer>A</answer>
                        </question>
                    </questions>
                </Section>
            </children>
        </Section>
    </Sections>
</QuestionBank>
```

## 文件操作

### 导入题库

1. 验证文件扩展名为 `.zip`
2. 解压ZIP文件
3. 验证 `data.xml` 文件存在
4. 解析XML结构
5. 验证必需字段

### 导出题库

1. 构建XML数据结构
2. 添加资源文件到ZIP
3. 压缩生成 `.zip` 文件

## 版本兼容性

当前格式版本：**1**

版本变更说明：
- v1: 初始版本，支持基本的题库、章节、题目结构
- 未来版本将保持向后兼容

## 最佳实践

1. **ID生成**: 使用UUID v4格式生成唯一标识符
2. **图片优化**: 建议使用PNG格式，文件名采用 `rId{数字}.png` 格式
3. **视频格式**: 支持MP4格式，使用相对路径引用
4. **文本编码**: 统一使用UTF-8编码
5. **文件大小**: 建议单个题库文件不超过100MB

## 工具支持

本格式由Flutter应用的题库管理系统原生支持，包括：
- 自动题目抽取
- 知识点树形导航
- 图片和视频资源管理
- 错题集功能
- 学习进度跟踪 