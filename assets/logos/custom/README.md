# 自定义软件图标目录

此目录用于放置你自己的 To Do It 软件图标，不要修改 `assets/logos/default/` 中的回退资源。

- `app.svg`：主界面标题栏 Logo。建议使用正方形画布、透明背景和 SVG 格式。文件存在时，CMake 配置阶段会优先将它打包为稳定资源 `icons/app.svg`；不存在时自动使用 `assets/logos/default/app.svg`。
- `app.ico`：Windows 可执行文件和 Qt IFW 安装程序使用的多尺寸图标。建议至少包含 16、20、24、32、40、48、64、128 和 256 px。文件存在时，CMake 会通过 RC 资源写入 `ToDoIt.exe`，打包脚本也会把同一文件复制给安装器；不存在时两处都回退到 `assets/logos/default/app.ico`。

为了让窗口、EXE 和安装器保持一致，建议同时提供 `app.svg` 与 `app.ico`。替换任一文件后需要重新执行一次 CMake 配置，再由你自行编译和打包；文件名和目录层级必须保持不变。Windows 原生 EXE 图标必须使用 ICO，不能直接以 SVG 替代。
