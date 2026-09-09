# Domain layer

放置事件实体、状态、重要程度、父子树、持续时间与排序规则等业务模型。当前 `model/EventRecord.h` 定义从持久化层交给应用层的完整事件记录，不包含 CSV 或 QML 字段名；本层不得依赖 UI、CSV、Windows API 或安装器。
