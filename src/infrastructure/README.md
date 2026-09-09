# Infrastructure layer

放置 `event.csv` 持久化、原子写入、备份恢复、配置保存、附件路径记录与数据格式迁移实现。当前已实现 `InstallPaths`、RFC 4180 `CsvCodec` 和 `CsvEventRepository`：文件缺失时原子创建只有正式表头的空文件，读取时完整校验，保存时验证完整快照并使用 `QSaveFile` 原子替换。备份轮换、恢复和格式迁移仍待后续实现。
