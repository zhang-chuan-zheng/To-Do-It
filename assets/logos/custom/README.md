# 自定义软件图标预留目录

此目录用于放置你自己的 To Do It 软件图标，不要修改 `assets/logos/default/` 中的回退资源。

- `app.svg`：主界面标题栏 Logo。建议使用正方形画布、透明背景和 SVG 格式。文件存在时，CMake 配置阶段会优先将它打包为稳定资源 `icons/app.svg`；不存在时自动使用 `assets/logos/default/app.svg`。
- `app.ico`：为后续 Windows 可执行文件、安装程序和卸载程序预留的多尺寸图标。建议包含 16、20、24、32、40、48、64、128 和 256 px。当前版本只预留路径，尚未把它写入 Windows 资源脚本。

替换 `app.svg` 后需要重新执行一次 CMake 配置，再由你自行编译。文件名和目录层级必须保持不变。
