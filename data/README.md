# Development data

该目录只允许放开发期本地数据和脱敏样例说明。`event.csv` 是 VS Code 与 `scripts/run.ps1` 默认读写的本地事件文件，已被 `.gitignore` 排除；它必须使用 UTF-8 BOM、固定 13 列表头和 RFC 4180 转义，不得提交真实事件、用户配置、附件内容、备份或日志。保存使用完整快照原子替换，加载失败时禁止写回。正式安装版本读写 `[程序目录]/data/event.csv`。
