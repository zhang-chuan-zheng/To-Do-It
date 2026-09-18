# Installer

使用 Qt Installer Framework 构建安装、更新和卸载流程。程序文件先由 CMake Install 与 Qt QML 部署脚本生成发行暂存目录：配置 HTTPS 仓库地址时生成包含首版载荷并记住远程仓库的混合 `Setup.exe`；不配置地址时生成纯离线安装器。同时生成供维护工具读取的在线仓库 ZIP 和完全离线更新 ZIP。在线仓库可部署到 GitHub Pages，离线脚本只在当次运行把解压目录注册为临时 `file:///` 仓库。

`config/style.qss`、控制脚本和两个动态 `.ui` 页面共同实现 0.2.1 石墨主题：首次安装提供品牌欢迎页；许可页强制显示高对比度同意框；维护工具统一使用中文标题、状态、进度和错误反馈；卸载页默认保留数据，也允许用户选择永久删除并接受二次确认。Qt IFW 的原生安装、更新、回滚和卸载事务仍是唯一安装引擎。

安装和更新内容永远不包含 `data/`。组件操作会停止主程序，在程序文件与快捷方式操作之后调用 `ToDoItMigrator`；迁移器取得锁、备份、校验并按稳定字段名迁移数据，用退出码决定维护事务是否成功。Qt IFW 生成的 `ToDoItMaintenanceTool.exe` 同时承担在线更新、离线更新和卸载。`RemoveTargetDir=false` 且用户数据不属于安装组件，因此默认卸载保留整个 `data/`；只有用户在卸载选项页主动选择删除并二次确认后，控制脚本才在卸载完成时清理 `[InstallDir]/data`。

Windows 发行布局把 `ToDoIt.exe`、`ToDoItMigrator.exe`、`qt.conf` 和所有 `Qt6*.dll` 放在安装根目录，平台插件仍放在 `plugins/`、QML 模块仍放在 `qml/`。打包脚本在调用 Qt IFW 前检查这些路径，并拒绝 Qt DLL 被错误部署到相邻 `bin/` 的载荷。
