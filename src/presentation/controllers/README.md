# Presentation controllers

放置暴露给 QML 的 C++ 视图模型、树模型、筛选代理、排序控制器和编辑状态协调器。`AppShellController` 提供应用元数据；`EventDataController` 在 CSV 与页面快照之间转换并执行原子保存；`QuoteController` 验证内置离线名言 JSON、启动时随机选取并响应手动换句；`RichTextFormatter` 只对备注编辑器当前选择范围应用加粗或颜色，不修改整段默认字体。
