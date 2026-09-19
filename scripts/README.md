# Development scripts

- `Initialize-MsvcEnvironment.ps1`：仅为当前进程导入 Visual Studio x64 开发环境，不更改系统环境变量。
- `configure.ps1`：使用 Qt 自带 CMake 和指定预设配置项目；切换 Qt/编译器时可传 `-Fresh` 安全重建生成缓存。
- `build.ps1`：通过 Ninja 构建所选预设，可用 `-Parallel` 限制并行数，或用 `-Target` 构建 `all_qmllint` 等单一目标。
- `test.ps1`：运行所选 CTest 预设并透传失败。
- `run.ps1`：为当前进程加入 Qt MSVC 运行库目录；若项目根 `data/event.csv` 存在，则仅为当前进程设置 `TODOIT_EVENT_FILE` 后启动已构建程序。
- `check-structure.ps1`：检查所有非生成文件都已在 `docs/structure.md` 中登记。
- `package.ps1`：只对已构建的 `local-release` 目录执行 CMake Install、Qt QML 部署、文件哈希清单和 Qt IFW 打包；不会调用构建命令，并要求显式提供官方 LGPLv3 文本。打包前验证主程序、迁移器、`qt.conf`、核心 Qt DLL、Windows 平台插件和 Qt Quick Controls QML 插件均存在，同时拒绝“EXE 在根目录、Qt DLL 在 `bin/`”的不可启动布局。脚本从 `assets/logos/custom/app.ico` 或默认回退文件选择安装器图标，并把统一石墨 QSS、版本化欢迎页和卸载数据选择页装入 IFW。传入 HTTPS `RepositoryUrl` 时生成混合安装器，否则生成纯离线安装器；两种模式都会输出离线更新 ZIP、在线仓库 ZIP、发布元数据、发布清单和 SHA-256。
- `prepare-github-release.ps1`：校验版本、GitHub 标识、打包时固化的 Pages 更新地址及全部附件 SHA-256，再整理 GitHub Release 附件和可直接发布到 Pages 的仓库目录；不会连接 GitHub、提交或上传内容。

脚本只负责编排工具，不实现业务规则，也不会修改用户或系统 PATH。
