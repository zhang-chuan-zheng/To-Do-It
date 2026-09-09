# Installer

使用 Qt Installer Framework 构建安装、更新和卸载流程。程序文件先由 CMake Install 与 Qt QML 部署脚本生成发行暂存目录：配置 HTTPS 仓库地址时生成包含首版载荷并记住远程仓库的混合 `Setup.exe`；不配置地址时生成纯离线安装器。同时生成供维护工具读取的在线仓库 ZIP 和完全离线更新 ZIP。在线仓库可部署到 GitHub Pages，离线脚本只在当次运行把解压目录注册为临时 `file:///` 仓库。

安装和更新内容永远不包含 `data/`。组件操作会停止主程序，在程序文件与快捷方式操作之后调用 `ToDoItMigrator`；迁移器取得锁、备份、校验并按稳定字段名迁移数据，用退出码决定维护事务是否成功。Qt IFW 生成的 `ToDoItMaintenanceTool.exe` 同时承担在线更新、离线更新和卸载。`RemoveTargetDir=false` 且用户数据不属于安装组件，因此默认卸载保留整个 `data/`。
