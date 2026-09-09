# To Do It

To Do It 是一款面向 Windows 10/11 的离线、单用户桌面任务清单软件。Qt Quick/QML 主页面通过 C++ 仓储读取并保存 `event.csv`：启动时严格校验文件格式并展示真实事件，代码中不内置示例事项；有效编辑、附件关联和树形拖放只标记内存快照为待保存，每 5 分钟仅在确有修改时原子写回，正常退出前再检查并刷新一次。项目提供 Release 安装部署、Qt Installer Framework 混合安装器、在线/离线更新仓库、维护工具卸载、版本清单和按稳定字段名迁移事件数据的独立迁移器；普通保存备份、损坏恢复、系统缩略图与系统磨砂仍待后续接入。

## 本机开发基线

- Qt 6.11.2：`D:/Qt/6.11.2/msvc2022_64`
- CMake 3.30.5：`D:/Qt/Tools/CMake_64/bin/cmake.exe`
- Ninja 1.12.1：`D:/Qt/Tools/Ninja/ninja.exe`
- x64 MSVC：由 Visual Studio 的 `VsDevCmd.bat` 注入
- 编辑器：VS Code、Qt Creator；QML 设计可使用 Qt Design Studio

## 配置、构建、测试与运行

在项目根目录打开 PowerShell：

```powershell
.\scripts\configure.ps1
.\scripts\build.ps1 -Parallel 4
.\scripts\build.ps1 -Target all_qmllint
.\scripts\test.ps1
.\scripts\run.ps1
```

VS Code 可在“终端 → 运行任务”中选择同名任务，也可在“运行和调试”中选择 `To Do It: Debug (MSVC)` 后按 F5。CMake Tools 中选择 `local-dev` 预设；若直接使用 CMake Tools 的按钮，请确保 VS Code 继承了 x64 MSVC 开发环境。Qt Creator 中选择 Qt 6.11.2 MSVC 64-bit Kit 后打开根 `CMakeLists.txt`。Qt Design Studio 打开根目录的 `ToDoIt.qmlproject` 编辑和预览 QML；正式构建仍以根 CMake 工程为准。

开发启动配置默认读取根目录下已忽略的 `data/event.csv`；正式安装版本默认读取可执行文件旁的 `data/event.csv`。目标文件不存在时，程序会先创建父目录并原子生成一个只有 UTF-8 BOM 与正式 13 列表头的空文件，绝不覆盖已有文件。现有文件必须符合 RFC 4180 和 `docs/proposal.md` 的字段规则；校验失败时事项列表保持为空、写回被锁止，具体行列错误显示在页面底部。正常保存使用 `QSaveFile` 原子提交，失败不会退化为直接覆盖原文件。

详细需求见 `docs/proposal.md`；所有目录、文件和公开职责见 `docs/structure.md`。任何项目变更都应同步更新结构手册，并运行 `.\scripts\check-structure.ps1`。

Release 构建、首次安装、GitHub Pages 在线更新、完全离线更新、卸载和版本控制步骤见 `docs/release.md`。`scripts/package.ps1` 只部署已经生成的 Release 二进制并制作发布物，不会隐式编译项目；`scripts/prepare-github-release.ps1` 只整理待上传文件，不会连接或修改 GitHub。
