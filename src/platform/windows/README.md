# Windows platform layer

放置 Windows 10/11 原生窗口、DWM 磨砂背景、DPI、Shell 文件选择和无边框窗口行为适配。`NativeAttachmentDialog` 使用系统 `IFileOpenDialog` 多选文件，并在同一原生窗口提供添加当前文件夹按钮；不得用 QML 重新实现文件浏览器。`resources/ToDoIt.rc.in` 是由 CMake 配置的 Windows 资源模板，只负责把选中的多尺寸 `app.ico` 写入主程序 EXE，不承载业务逻辑。

