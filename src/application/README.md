# Application layer

放置创建、编辑、筛选、排序、拖拽移动、保存和迁移等用例。当前 `port/IEventRepository.h` 定义事件快照读取、完整快照保存及结构化错误端口，CSV 实现只能位于基础设施层；此层不包含 QML 视觉实现或具体 CSV 解析细节。

