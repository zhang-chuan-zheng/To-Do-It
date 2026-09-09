# To Do It 项目结构与代码职责

> 文档版本：v1.4  
> 用途：项目唯一且强制维护的程序开发手册；包含所有项目文件、目录、公开函数和核心逻辑的注释  
> 适用基线：C++20、Qt 6.11.2、Qt Quick/QML、MSVC x64、Ninja 1.12.1、CMake 3.24+

## 1. 文档使用规则

### 1.1 状态标记

- `[现有]`：当前工作区已经存在。
- `[计划]`：需求确认后按本文创建，目前可能尚不存在。
- `[运行时]`：由安装器或应用在用户机器上生成，不提交真实内容。
- `[生成]`：由 IDE、CMake、编译器或打包工具生成，不手工维护。

### 1.2 强制同步规则

本文件是项目变更完成条件的一部分。每次对项目中的任何内容进行更改后，都必须在同一次修改中更新本文件的对应位置；没有同步更新时，该次更改一律视为未完成，不得交付、提交或发布。该规则同样适用于只修改文档、资源、构建脚本、测试、配置或本机开发约定的情况。

本文件必须逐一覆盖项目中的所有实际文件，并说明文件用途、允许编辑内容和关键逻辑；对同构生成文件可登记明确的生成规则，但不得用含糊的目录描述替代源文件注释。每次更改后必须重新核对实际文件清单，新增文件先登记、删除文件同步移除或记录迁移去向。

至少包括下列变化：

1. 新增、删除、移动或重命名目录/文件；
2. 改变一个目录的边界或依赖方向；
3. 新增、删除或改变公开类、公开函数、QML 组件接口；
4. 改变 CSV、配置、更新清单或日志格式；
5. 改变安装目录、运行时目录或第三方依赖；
6. 把“计划”内容实现为“现有”内容。

自动生成目录只说明生成来源、生成工具与禁止编辑事项，不逐个记录其中可随时重建的临时文件；自动生成目录不得包含唯一业务数据。

## 2. 总体依赖方向

```text
QML View
   ↓
presentation/controllers
   ↓
application/usecases ───→ application/ports
   ↓                           ↑
domain                    infrastructure
                              ↑
platform/windows ─────────────┘
```

约束：

- `domain` 不依赖 Qt UI、CSV、Windows 或安装器。
- `application` 可依赖 `domain`，但只通过端口接口访问文件和平台能力。
- `infrastructure`、`platform/windows` 实现应用层端口。
- `presentation` 只通过应用服务改变业务状态，不直接读写 CSV。
- QML 不解析 CSV、不计算树规则、不直接调用 Win32。
- `updater` 不链接主界面模块，只复用数据格式与迁移代码。

## 3. 目标目录树

```text
To Do It/
├─ .gitignore                                      [现有]
├─ .qtcreator/ToDoIt.qmlproject.user              [本机生成，不提交]
├─ .vscode/                                        [现有]
│  ├─ extensions.json                              [现有]
│  ├─ launch.json                                  [现有]
│  ├─ settings.json                                [现有]
│  └─ tasks.json                                   [现有]
├─ CMakeLists.txt                                  [现有]
├─ CMakePresets.json                               [现有]
├─ CMakeUserPresets.example.json                   [现有]
├─ CMakeUserPresets.json                           [本机，现有，不提交]
├─ build-local-release.log                         [本机构建日志，不提交]
├─ README.md                                       [现有]
├─ ToDoIt.qmlproject                               [现有，Qt Design Studio]
├─ assets/                                         [现有]
│  ├─ icons/                                       [现有]
│  │  ├─ README.md                                 [现有]
│  │  ├─ default/README.md                         [现有]
│  │  ├─ default/{search,minimize,maximize,restore,close}.svg [现有]
│  │  ├─ default/{chevron-down,calendar,sort-up,sort-down,add}.svg [现有]
│  │  ├─ manifest.json                             [计划]
│  │  └─ *.png                                     [计划]
│  ├─ logos/                                       [现有]
│  │  ├─ README.md                                 [现有]
│  │  ├─ default/README.md                         [现有]
│  │  ├─ manifest.json                             [计划]
│  │  └─ default/app.svg                           [现有]
│  ├─ quotes/                                      [现有]
│  │  ├─ README.md                                 [现有]
│  │  └─ philosophy_quotes.json                    [计划]
│  └─ themes/                                      [现有]
│     ├─ README.md                                 [现有]
│     ├─ default-theme.json                        [计划]
│     └─ backgrounds/README.md                     [现有]
├─ cmake/                                          [现有]
│  ├─ CompilerWarnings.cmake                       [现有]
│  ├─ LocalizedMsvc.cmake                          [现有]
│  ├─ Dependencies.cmake                           [计划]
│  ├─ Sanitizers.cmake                             [计划]
│  └─ InstallLayout.cmake                          [计划]
├─ config/                                         [现有]
│  ├─ README.md                                    [现有]
│  ├─ default-settings.json                        [计划]
│  └─ default-resources.json                       [现有]
├─ data/                                           [现有，开发样例]
│  ├─ README.md                                    [现有]
│  ├─ event.csv                                    [本机，现有，不提交]
│  ├─ event.example.csv                            [计划]
│  └─ settings.example.json                        [计划]
├─ docs/                                           [现有]
│  ├─ proposal.md                                  [现有]
│  ├─ release.md                                   [现有]
│  └─ structure.md                                 [现有]
├─ installer/                                      [现有]
│  ├─ README.md                                    [现有]
│  ├─ config/config.xml.in                         [现有]
│  ├─ controller/installer-controller.qs           [现有]
│  ├─ update/{apply-update.ps1,README.txt}          [现有]
│  └─ packages/com.todoit.app/meta/
│     ├─ package.xml.in                            [现有]
│     └─ installscript.qs                          [现有]
├─ scripts/                                        [现有]
│  ├─ README.md                                    [现有]
│  ├─ Initialize-MsvcEnvironment.ps1               [现有]
│  ├─ check-structure.ps1                          [现有]
│  ├─ configure.ps1                                [现有]
│  ├─ build.ps1                                    [现有]
│  ├─ test.ps1                                     [现有]
│  ├─ run.ps1                                      [现有]
│  ├─ package.ps1                                  [现有]
│  └─ prepare-github-release.ps1                   [现有]
├─ src/                                            [现有]
│  ├─ CMakeLists.txt                               [现有]
│  ├─ .qmlls.ini                                   [生成，不提交]
│  ├─ main.cpp                                     [现有]
│  ├─ application/
│  │  ├─ CMakeLists.txt                            [现有框架]
│  │  └─ port/IEventRepository.h                   [现有读写端口]
│  ├─ domain/
│  │  ├─ CMakeLists.txt                            [现有框架]
│  │  └─ model/EventRecord.h                       [现有数据记录]
│  ├─ infrastructure/
│  │  ├─ CMakeLists.txt                            [现有静态库]
│  │  ├─ path/InstallPaths.{h,cpp}                 [现有]
│  │  └─ persistence/
│  │     ├─ CsvCodec.{h,cpp}                       [现有只读解析]
│  │     └─ CsvEventRepository.{h,cpp}             [现有原子读写仓储]
│  ├─ platform/windows/CMakeLists.txt              [现有框架]
│  └─ presentation/
│     ├─ controllers/
│     │  ├─ CMakeLists.txt                         [现有]
│     │  ├─ AppShellController.{h,cpp}             [现有]
│     │  ├─ EventDataController.{h,cpp}            [现有读写视图适配]
│     │  └─ RichTextFormatter.{h,cpp}              [现有选择范围格式器]
│     └─ qml/
│        ├─ CMakeLists.txt                         [现有]
│        ├─ Main.qml                               [现有主窗口框架]
│        ├─ pages/MainPage.qml                     [现有交互页面框架]
│        ├─ components/*.qml                       [现有视觉与交互组件，逐文件见 3.1]
│        ├─ components/WindowResizeHandles.qml     [现有窗口边角缩放]
│        ├─ effects/GlassSurface.qml               [现有静态框架]
│        ├─ effects/PopupGlassBackground.qml       [现有应用内弹层模糊]
│        └─ styles/{IconCatalog,Theme,Metrics,Typography,Motion}.qml [现有]
├─ tests/
│  ├─ CMakeLists.txt                               [现有]
│  ├─ framework/AppShellControllerTest.cpp         [现有]
│  └─ updater/UpdateCoordinatorTest.cpp            [现有]
├─ third_party/                                    [现有]
│  ├─ README.md                                    [现有]
│  ├─ licenses/README.md                           [现有]
│  └─ qwindowkit/                                  [计划，固定版本]
└─ updater/                                        [现有]
   ├─ CMakeLists.txt                               [现有]
   ├─ main.cpp                                     [现有]
   ├─ EventCsvMigrator.{h,cpp}                     [现有]
   ├─ UpdateManifest.{h,cpp}                       [现有]
   ├─ UpdateCoordinator.{h,cpp}                    [现有]
   ├─ UpdateHistoryWriter.{h,cpp}                  [现有]
   ├─ UpdateReport.h                               [现有]
   ├─ manifests/0.1.0.json                         [现有]
   └─ README.md                                    [现有]
```

构建后还会出现 `.vs/`、`build/`、`out/` 等 `[生成]` 目录；它们不得作为源代码修改，也不得写入用户数据。

### 3.1 当前实际文件登记表

此表是“所有项目文件均有注释”的核对基线。一次连续开发批次完成全部程序文件后，必须统一用实际文件清单复核并更新本表一次；文件实现细节仍以本手册后续对应章节为准。

| 文件 | 用途与允许编辑内容 |
| --- | --- |
| `.gitignore` | 排除构建产物、本机预设、工具链、构建日志和真实用户数据，包括开发期 `data/event.csv`；只添加可重建或私有文件规则。 |
| `.qtcreator/ToDoIt.qmlproject.user` | Qt Creator/Qt Design Studio 生成的本机工作区状态；由 IDE 维护、`*.user` 规则忽略，禁止作为共享工程配置编辑或提交。 |
| `.vscode/extensions.json` | 推荐 Microsoft C/C++ 与 CMake Tools 扩展；可编辑推荐列表，不得绑定个人扩展状态。 |
| `.vscode/launch.json` | 提供 MSVC 的 F5 启动调试配置；构建前置任务、Qt DLL PATH 和指向根目录 `data/event.csv` 的 `TODOIT_EVENT_FILE` 只作用于调试进程，可编辑程序参数和调试器选项。 |
| `.vscode/settings.json` | 让 VS Code 使用 Qt 自带 CMake 与 CMake Presets；首次由用户选择 `local-dev`，可编辑工作区级工具入口，不得加入凭据或用户专属临时目录。 |
| `.vscode/tasks.json` | 提供配置、构建、QML 检查、测试和运行任务；只调用 `scripts/` 中的统一入口，避免在编辑器配置中复制工具链逻辑。 |
| `CMakeLists.txt` | 定义项目、C++20、Qt 模块、主程序/迁移器/测试子目录及 Release 安装规则；安装默认资源、许可声明和版本清单但明确排除 `data/`。 |
| `CMakePresets.json` | 共享且无个人路径的 Ninja Debug/Release 配置基线。 |
| `CMakeUserPresets.example.json` | 推荐 `D:/Qt` 布局的本机预设模板；固定 Qt、配套 C++ 编译器与 Ninja，实际路径只改复制后的不提交文件。 |
| `CMakeUserPresets.json` | 本机实际 Qt 6.11.2 `msvc2022_64` 与 Ninja 路径；以 `cl.exe` 复用已导入的 x64 MSVC 环境，固定 `local-dev`/`local-release`，不提交仓库。 |
| `build-local-release.log` | 本机构建过程留下的诊断日志；仅用于临时排错，受 `*.log` 忽略，不得作为发布输入或手工维护。 |
| `README.md` | 新开发者入口、CSV 原子读写与缺失文件初始化的当前状态、数据路径、强制开发手册规则、Qt LGPL 路线，以及固定 Qt 工具链脚本的真实命令。 |
| `ToDoIt.qmlproject` | Qt Design Studio 的开发期入口；收集 QML、图片和默认 JSON，指向静态壳主文件与本地构建导入路径，不参与正式编译或安装。 |
| `assets/icons/README.md` | 图标目录边界、格式与替换规则。 |
| `assets/icons/default/README.md` | 登记已提供的主页面 SVG 图标稳定文件名、自定义同名覆盖规则和禁止写回发行资源约束。 |
| `assets/icons/default/add.svg` | 添加事项的独立圆角方框加号 SVG；可替换路径由资源配置决定，组件不得硬编码 Unicode 加号。 |
| `assets/icons/default/attachment-add.svg` | 附件区末尾唯一添加入口的圆角文件框加号 SVG；在 18 px 显示尺寸下保持清晰，与 `add.svg` 分离并允许独立替换。 |
| `assets/icons/default/calendar.svg` | 预留日期选择器矢量图标；当前时间字段未展示无功能按钮，日期选择弹窗接入后才启用。 |
| `assets/icons/default/chevron-down.svg` | 搜索条件、状态筛选和可编辑状态框共用的下拉箭头。 |
| `assets/icons/default/close.svg` | 窗口关闭和附件解除关联操作的矢量图标。 |
| `assets/icons/default/maximize.svg` | 窗口最大化操作的矢量图标。 |
| `assets/icons/default/minimize.svg` | 窗口最小化操作的矢量图标。 |
| `assets/icons/default/palette.svg` | 备注工具栏的调色盘 SVG；点击后打开系统颜色选择器，只作用于当前选中文字。 |
| `assets/icons/default/restore.svg` | 最大化窗口还原操作的矢量图标。 |
| `assets/icons/default/search.svg` | 标题栏固定圆形搜索入口的矢量图标。 |
| `assets/icons/default/sort-down.svg` | 表头降序操作的矢量箭头。 |
| `assets/icons/default/sort-up.svg` | 表头升序操作的矢量箭头。 |
| `assets/logos/README.md` | Logo 清单、默认/自定义根目录和回退规则。 |
| `assets/logos/default/README.md` | 登记默认 `app.svg`、稳定资源键和用户自定义同名覆盖规则。 |
| `assets/logos/default/app.svg` | To Do It 默认灰色圆角复选标志；可由 `IconCatalog.appLogo` 或资源配置替换。 |
| `assets/quotes/README.md` | 本地名言数据的出处、长度与审核规则。 |
| `assets/themes/README.md` | 主题令牌、渐变、颜色和背景资源边界。 |
| `assets/themes/backgrounds/README.md` | 默认背景图片目录及自定义镜像规则。 |
| `cmake/CompilerWarnings.cmake` | 为项目目标统一启用 MSVC/GNU/Clang 高等级警告。 |
| `cmake/LocalizedMsvc.cmake` | 修复中文 MSVC 与 CMake 3.30/Ninja 的 `/showIncludes` 前缀乱码；只在检测到确切乱码值时改写 CMake 变量，其他工具链不受影响。 |
| `config/README.md` | 默认配置模板与运行时用户配置的边界。 |
| `config/default-resources.json` | 定义 Logo、图标、背景的默认/自定义根，并登记当前稳定 SVG 文件键；相对路径以安装目录解析。 |
| `data/README.md` | 开发期本地 `event.csv` 的原子读写、加载失败锁止写回、忽略规则，以及与真实安装数据的隔离边界。 |
| `data/event.csv` | 开发启动默认读取的本地事件文件；当前仅含带 UTF-8 BOM 的 13 列正式表头，不含内置示例事件，不提交版本库。 |
| `docs/proposal.md` | 已确认产品需求、平台约束、已验证工具链事实与后续需求变更规则。 |
| `docs/release.md` | Release 构建前提、Qt IFW 混合安装器、GitHub Pages 在线仓库、GitHub Release、离线更新、卸载、版本/字段迁移规则和发布门禁。 |
| `docs/structure.md` | 本程序开发手册自身；任何项目更改必须同步维护对应注释。 |
| `installer/README.md` | CMake Install/Qt 部署到 Qt IFW 混合安装器、在线/离线仓库的边界，并规定更新不覆盖数据、迁移先备份校验、卸载默认保留数据。 |
| `installer/config/config.xml.in` | Qt IFW 全局配置模板；定义每用户默认目录、维护工具、许可、本地仓库权限及可选远程仓库占位符，版本和仓库 XML 由打包脚本替换。 |
| `installer/controller/installer-controller.qs` | 安装控制脚本；从 `LOCALAPPDATA` 计算默认目录，同时保留目录选择页面。 |
| `installer/packages/com.todoit.app/meta/package.xml.in` | 应用组件元数据模板；声明版本、发布日期、强制/关键组件、许可和组件脚本。 |
| `installer/packages/com.todoit.app/meta/installscript.qs` | 停止主进程，先布置程序与快捷方式，最后调用迁移器；迁移失败使 IFW 维护事务失败，数据不进入组件归档。 |
| `installer/update/apply-update.ps1` | 验证解压的本地仓库与安装目录，只为当次维护工具进程添加临时 `file:///` 仓库并更新固定组件 ID。 |
| `installer/update/README.txt` | 随离线更新 ZIP 分发的默认/自定义安装目录操作说明。 |
| `scripts/README.md` | 列出已实现的配置/构建/测试/结构门禁脚本、参数边界和不修改 PATH/不重复业务逻辑规则。 |
| `scripts/Initialize-MsvcEnvironment.ps1` | 为当前 PowerShell 进程定位并导入 Visual Studio x64 开发环境，兼容同时存在 `PATH`/`Path` 的宿主；不永久修改系统环境变量。 |
| `scripts/check-structure.ps1` | 兼容 PowerShell 5.1/7，只读核对全部非生成项目文件（含本机预设）均有开发手册注释；可编辑忽略规则和门禁提示，不得修改项目内容。 |
| `scripts/configure.ps1` | 导入 MSVC 后用绝对 CMake 路径和指定 Configure Preset 配置；`-Fresh` 只重建可再生成的缓存，脚本不得修改系统 PATH。 |
| `scripts/build.ps1` | 导入 MSVC 后用指定 Build Preset 构建，可限制并行度或通过 `-Target` 构建单一目标；失败必须原样传播。 |
| `scripts/test.ps1` | 用绝对 CTest 路径和指定 Test Preset 运行测试，可限制并行度；只可编辑测试编排，不得隐藏失败。 |
| `scripts/run.ps1` | 在当前进程 PATH 前置 Qt MSVC 运行库目录，并在本地数据文件存在时为子进程设置 `TODOIT_EVENT_FILE` 后启动构建产物；不部署文件、不持久修改环境。 |
| `scripts/package.ps1` | 不编译；部署已构建的 Release、填充 IFW 模板，按是否传入 HTTPS 仓库地址生成混合或纯离线安装器，并产出在线仓库、离线更新 ZIP、发布清单/元数据及 SHA-256。 |
| `scripts/prepare-github-release.ps1` | 不联网；核对版本/GitHub 标识、安装器固化的 GitHub Pages 地址和附件 SHA-256，把精确版本的 Release 附件及可部署 Pages 目录整理到受项目根边界保护的 `out/github-publish/`。 |
| `src/CMakeLists.txt` | 创建主程序目标、链接 Qt Quick/Controls/Dialogs/Effects，在同一作用域注册 QML 模块，并生成 CMake Install 的 Qt QML 自包含部署脚本。 |
| `src/.qmlls.ini` | Qt/CMake 为 QML Language Server 生成的导入路径提示；由 `QT_QML_GENERATE_QMLLS_INI` 重建、已忽略，禁止手改。 |
| `src/main.cpp` | 应用进程入口；解析安装目录或开发覆盖的数据路径，在栈上构造 CSV 仓储、事件数据控制器和富文本格式器，注册三个 QML 单例并加载根 QML；对象析构顺序保证控制器引用的仓储仍然存活。 |
| `src/application/CMakeLists.txt` | 定义 `ToDoIt::Application` 接口目标及其对领域层的单向依赖；业务用例出现后才可加入本层源文件。 |
| `src/application/README.md` | 用例、端口、事务和应用服务依赖边界。 |
| `src/application/port/IEventRepository.h` | 定义 `load()` 与 `save(snapshot)` 读写仓储端口，以及包含行列的加载错误和独立保存错误；接口只暴露领域快照，不泄漏 CSV/Qt 文件类型。 |
| `src/domain/CMakeLists.txt` | 定义最底层 `ToDoIt::Domain` 接口目标和公共源码包含根；只可加入纯领域代码及目标级编译要求。 |
| `src/domain/README.md` | 纯领域模型、事件树与业务规则边界。 |
| `src/domain/model/EventRecord.h` | 定义与持久字段一一对应、但不含 CSV/QML 细节的 `EventRecord` 数据记录，作为当前仓储到展示控制器的传输对象。 |
| `src/infrastructure/CMakeLists.txt` | 构建含路径与 CSV 读取实现的 `ToDoIt::Infrastructure` 静态库，链接应用端口和 Qt Core；只可加入存储、配置和迁移实现。 |
| `src/infrastructure/README.md` | CSV、JSON、备份、迁移等外部实现边界。 |
| `src/infrastructure/path/InstallPaths.h` | 声明以可执行文件目录为根的运行时路径对象及 `eventFile()` 查询。 |
| `src/infrastructure/path/InstallPaths.cpp` | 实现安装根保存和 `[InstallDir]/data/event.csv` 拼接；不得依赖当前工作目录。 |
| `src/infrastructure/persistence/CsvCodec.h` | 声明带起始行号的 CSV 记录、解析错误、解析结果和只读 `CsvCodec::parse()`。 |
| `src/infrastructure/persistence/CsvCodec.cpp` | 实现 UTF-8 BOM 检查和 RFC 4180 状态机，支持引号内逗号、双引号及换行并返回精确记录行号。 |
| `src/infrastructure/persistence/CsvEventRepository.h` | 声明 `IEventRepository` 的文件型读写实现，集中公开当前 `supportedSchemaVersion` 和只读数据文件路径。 |
| `src/infrastructure/persistence/CsvEventRepository.cpp` | 文件不存在时原子创建正式空表头；读取时把 13 列 CSV 严格反序列化并校验完整树；保存时校验完整快照、编码附件 JSON 与 RFC 4180 字段，再用禁用直接回退的 `QSaveFile` 原子提交 UTF-8 BOM、表头和记录。 |
| `src/platform/windows/CMakeLists.txt` | 定义 `ToDoIt::WindowsPlatform` 接口目标并依赖应用端口；只可加入 Windows 平台适配和必要系统库。 |
| `src/platform/windows/README.md` | Windows 窗口、DWM、缩略图和文件打开能力边界。 |
| `src/presentation/controllers/CMakeLists.txt` | 构建 `ToDoIt::PresentationControllers` 静态库、加入事件控制器与富文本格式器、注入项目版本；公开链接 Qt Core/Gui/应用层，私有链接 Qt Quick 以访问 `QQuickTextDocument`。 |
| `src/presentation/controllers/AppShellController.h` | 声明 QML 应用壳单例的四个只读属性；可编辑仅限进程级元数据/框架状态接口，不得加入事件业务。 |
| `src/presentation/controllers/AppShellController.cpp` | 返回应用名、CMake 项目版本、阶段说明和框架就绪标志；可编辑属性实现，`backendReady` 不得冒充数据层就绪。 |
| `src/presentation/controllers/EventDataController.h` | 声明供 QML 使用的启动事件、数据路径、加载/保存错误和加载状态属性，并提供 `createEventId()` 与 `saveEvents(rows)`；以 const 引用持有应用仓储端口。 |
| `src/presentation/controllers/EventDataController.cpp` | 在领域事件与 QML 行之间转换，生成 UUID，保留创建时间，把本地显示时间/附件 URL 转回持久格式并调用完整快照原子保存；加载或保存失败时生成含路径的中文诊断。 |
| `src/presentation/controllers/RichTextFormatter.h` | 声明选择范围富文本接口 `toggleBold()` 与 `applyColor()`；参数使用 QML 文本文档对象和选择起止位置，不暴露文档所有权。 |
| `src/presentation/controllers/RichTextFormatter.cpp` | 通过 `QQuickTextDocument` 取得 Qt 文本文档，夹紧非空选择范围，并用 `QTextCursor` 编辑块仅合并所选字符的字重或前景色；无效文档、空选择或无效颜色返回失败。 |
| `src/presentation/controllers/README.md` | C++ 控制器、视图模型及 QML 接口边界，说明事件快照读写和仅作用于选择范围的富文本格式职责。 |
| `src/presentation/qml/CMakeLists.txt` | 注册 QML 模块、根页面、样式单例及全部主页面组件；新增/删除 QML 文件时必须同步本清单。 |
| `src/presentation/qml/Main.qml` | 创建圆角无边框根窗口、石墨实色回退与低饱和环境光，装配 `MainPage` 和窗口缩放热区，把页面暴露为下拉弹层快照源，并在正常关闭信号中同步刷新待保存事件。 |
| `src/presentation/qml/pages/MainPage.qml` | 装配标题栏、信息栏、表头、事件列表和帮助行；注入 CSV 事件与 UUID 工厂，转发快照给 `EventData.saveEvents()`，保存失败时保留脏标记并显示错误，同时协调页面级点击外部失焦。 |
| `src/presentation/qml/components/AddEventButton.qml` | 34 px 单一新增事项入口，中央显示 20 px 独立 SVG 图标和“添加事项”文字，使用 `Item` 和指针处理器而非默认 `Button` 状态；发出 `addRequested()`，同时作为移回一级的拖放目标并发出 `rootDropRequested()`。 |
| `src/presentation/qml/components/AppLogo.qml` | 暴露可替换 `source` 并默认使用 `IconCatalog.appLogo`；可编辑显示与回退外观，不得硬编码用户路径。 |
| `src/presentation/qml/components/AttachmentStrip.qml` | 绘制左对齐“附件”、行高级附件小块和唯一的末尾添加按钮；末尾入口加载独立 `attachment-add.svg`，支持文件 URL/路径显示，悬停显示完整路径和解除关联按钮，双击发出打开请求。 |
| `src/presentation/qml/components/BottomHelpBar.qml` | 以无外框单行文字显示帮助消息和严重程度；可编辑排版，消息优先级留给后续控制器。 |
| `src/presentation/qml/components/CompactDateEditor.qml` | 在独立字段框内提供无 Qt 输入掩码的固定 16 字符时间编辑器，自行维护 12 个数字槽，支持逐数字前进、自动越过分隔符、鼠标在分隔符前后原生定位、逐字符方向键以及数字位删除，并执行范围及闰年校验；公开 `text`、`allowEmpty`、`editing`、`invalidInput`、`valueEdited()` 和 `validationFailed()`。 |
| `src/presentation/qml/components/EditableStatusComboBox.qml` | 可输入且可从已有状态选择的状态字段；公开 `statusText`、`statusOptions`、`editing`、`statusEdited()`，颜色仅表达状态，下拉层使用统一页面模糊和深色遮罩。 |
| `src/presentation/qml/components/EventCard.qml` | 单个事项的完整圆角边界及整卡拖放/悬停命中区；独立移动代理驱动 Qt Drag，标题 Enter 提交后释放焦点并报告鼠标是否仍在卡内，备注面板高度跟随卡片动画并报告编辑状态。 |
| `src/presentation/qml/components/EventTableHeader.qml` | 绘制无子框的加高七列表头，以轻微纵向线标示列边界，紧凑排序箭头紧贴名称，并与列表共用滚动条槽和列宽；向事件树发送排序方向。 |
| `src/presentation/qml/components/EventTreeView.qml` | 用 `initialEvents` 替换空源模型，不含内置事项；负责筛选、搜索、动画排序、UUID 草稿、时间、附件和唯一备注，使用移动代理完成成为子项/同级移动/移回一级并拒绝后代投放；修改只标脏，5 分钟到期时仅在脏状态发出完整持久快照，关闭时再次检查并可强制刷新。 |
| `src/presentation/qml/components/ExpandableSearchBox.qml` | 搜索圆形锚点保持不动并向右展开至 460 px，条件选择后接垂直居中的输入框；普通悬停离开提供 800 ms 延迟，点击外部造成失焦且内容为空时由 `collapseImmediatelyIfIdle()` 立即收起，并继续发送实时查询信号。 |
| `src/presentation/qml/components/FieldFrame.qml` | 事件原子字段共用的清晰细描边圆角容器；公开内边距、高亮和填充色，不持有字段数据。 |
| `src/presentation/qml/components/FramelessTitleBar.qml` | 无外框顶层菜单栏，组合可替换 SVG Logo、名称、64 px 留距搜索和 SVG 窗口按钮；`pointInsideSearch()` 为全局失焦逻辑排除搜索区域，普通按下仅发出 `backgroundPressed()`，移动超过系统拖动阈值后才调用 Qt Window 系统移动，避免单击遗留原生指针捕获。 |
| `src/presentation/qml/components/GlassPanel.qml` | 用统一内容材质包裹任意子内容；可编辑内边距、层级和交互外观，不负责桌面模糊。 |
| `src/presentation/qml/components/GlassToolTip.qml` | 统一附件路径等悬停说明的自适应宽度弹层，使用主题字体、换行和应用内模糊背景。 |
| `src/presentation/qml/components/ImportanceSelector.qml` | 五个等宽胶囊分段表示 1/3/5/7/9，点击按累计段选择等级；仅发出 `levelRequested()`，不显示数值。 |
| `src/presentation/qml/components/IconImage.qml` | 统一加载 SVG/位图图标并提供可访问名称和最小文字回退；业务组件只绑定资源 URL，不再自行绘制符号。 |
| `src/presentation/qml/components/InfoFilterBar.qml` | 名言占据左侧弹性区域，右侧放置彼此独立的筛选框和统计框；公开动态筛选选项、统计标签和计数 alias，不自行遍历事件。 |
| `src/presentation/qml/components/QuoteBanner.qml` | 将名言和作者保持在同一行，正常宽度不放大、缩窄时自适应减小；双击发出本地换句请求。 |
| `src/presentation/qml/components/ColorPalettePopup.qml` | 与主界面一致的非模态调色盘；提供圆形预设色、紧凑居中的 RGB/CMYK 数值输入、双向换算和“应用到所选文字”，保持打开以连续格式化多个选区。 |
| `src/presentation/qml/components/RichNoteEditor.qml` | 备注标题行右侧提供加粗按钮和 `palette.svg` 调色盘按钮；保存并恢复选择范围，调用 C++ 格式器只改变选中文字；正文高度跟随富文本 `contentHeight`，不使用内部滚动区域。 |
| `src/presentation/qml/components/RoundIconButton.qml` | 统一 SVG 图标按钮的 hover、焦点和帮助信号；新增 `iconSize` 控制不同用途的图片显示尺寸，`chromeStyle` 让窗口按钮静止时无框、交互时才显底色。 |
| `src/presentation/qml/components/SearchFieldSelector.qml` | 位于搜索胶囊内且无独立边框，紧凑完整显示四种搜索字段；弹层使用统一页面模糊与深色遮罩，选项不省略并发出 `fieldSelected()`。 |
| `src/presentation/qml/components/SortButton.qml` | 在约 22 px 高的紧凑范围内显示上下方向并发出方向请求；活动方向使用主题强调色圆形底和高不透明度，不再显示会遮挡箭头的排序优先级数字。 |
| `src/presentation/qml/components/WindowResizeHandles.qml` | 覆盖无边框窗口四边及四角的 6 px 系统缩放热区，设置对应鼠标指针并调用 `startSystemResize()`；最大化或全屏时自动禁用。 |
| `src/presentation/qml/components/StatusFilterComboBox.qml` | 基础模型只保留系统筛选“未完成事项/全部事项”，由事件树追加 CSV 中实际状态；以统一页面模糊和深色遮罩承载弹层并发出筛选请求。 |
| `src/presentation/qml/components/StatusSummary.qml` | 根据外部计数显示整数百分比；可编辑格式，不遍历事件或补祖先。 |
| `src/presentation/qml/components/README.md` | 可复用组件目录边界、高保真主页面组件范围、固定槽滚动条/SVG 图标接口及禁止直接读写业务数据规则。 |
| `src/presentation/qml/dialogs/README.md` | 独立确认、错误和恢复对话框目录边界。 |
| `src/presentation/qml/effects/GlassSurface.qml` | 绘制统一 tint 和完整细描边；已取消造成横线的顶部高光层，仍明确禁止捕获/模糊桌面。 |
| `src/presentation/qml/effects/PopupGlassBackground.qml` | 截取弹层覆盖的 `MainPage` 区域，使用 `MultiEffect` 模糊后叠加深色石墨遮罩和圆角描边；只处理应用内下拉背景，不替代 Windows 桌面磨砂。 |
| `src/presentation/qml/effects/README.md` | 视觉效果目录及 `GlassSurface`、应用内弹层模糊与 Windows 桌面模糊之间的职责边界。 |
| `src/presentation/qml/pages/README.md` | 页面级布局、信号转发和不持有业务状态的装配边界。 |
| `src/presentation/qml/styles/Metrics.qml` | 单例保存窗口尺寸、6 px 缩放热区、64 px 标题搜索间距、460 px 搜索展开宽度、34 px 添加入口、圆角、列宽、加高表头、搜索条件宽度，以及 14 px 固定滚动槽、9 px 滑块宽度和 12% 最小滑块比例；禁止业务状态。 |
| `src/presentation/qml/styles/Motion.qml` | 单例保存通用、220 ms 备注高度、搜索、260 ms 重排动画、缓动曲线、800 ms 搜索与空草稿离开延迟及减少动画开关；可编辑动效令牌。 |
| `src/presentation/qml/styles/IconCatalog.qml` | 单例集中公开应用标志、搜索、窗口、下拉、日期、排序、添加事项和附件添加图标 URL；以后资源定位器可覆盖这些属性。 |
| `src/presentation/qml/styles/Theme.qml` | 单例保存颜色/材质令牌和 `useVariant()` 主题切换接口；可编辑主题数据，不得写事件逻辑。 |
| `src/presentation/qml/styles/Typography.qml` | 单例保存字体族、字号、字重及名言缩放令牌；可编辑排版令牌。 |
| `src/presentation/qml/styles/README.md` | 四个样式单例的职责及业务组件不得复制视觉常量的边界。 |
| `tests/CMakeLists.txt` | 注册应用壳与更新协调器两个 Qt Test/CTest 目标及 Qt 运行库测试环境。 |
| `tests/framework/AppShellControllerTest.cpp` | 验证应用壳名称、版本和框架就绪属性；可编辑框架契约断言，不替代业务测试。 |
| `tests/updater/UpdateCoordinatorTest.cpp` | 覆盖同架构备份校验、拒绝猜测无版本 CSV、无数据首次安装不提前创建事件文件、按稳定字段名新增缺省列/移除旧列，以及拒绝未显式声明的字段改名。 |
| `tests/README.md` | 当前应用壳与更新数据安全测试边界、未执行状态、后续测试分层、fixture 与关键回归范围。 |
| `third_party/README.md` | 固定第三方版本、来源、许可证、模块和补丁；明确外部 Qt SDK、LGPL 动态模块及发布物登记规则。 |
| `third_party/licenses/README.md` | 说明打包时必须显式提供官方未修改 LGPLv3 文本及新增第三方许可登记规则。 |
| `updater/CMakeLists.txt` | 构建只链接 Qt Core/Infrastructure 的 `ToDoIt::UpdateCore` 和控制台 `ToDoItMigrator`，并把迁移器安装到主程序旁。 |
| `updater/main.cpp` | 解析数据目录、清单和安装/更新模式，调用协调器，以 0/2/3 退出码向安装器报告成功、参数错误或迁移失败。 |
| `updater/UpdateReport.h` | 定义更新结果、版本/架构、事件数量、哈希、备份和程序变更摘要的数据结构。 |
| `updater/EventCsvMigrator.h` | 声明纯内存 CSV 迁移结果及 `EventCsvMigrator::migrate()`，输入已解析旧记录和目标字段结构。 |
| `updater/EventCsvMigrator.cpp` | 按大小写敏感稳定字段名映射记录；同名字段保留、新字段写目标缺省值、目标不存在字段不写入，并输出 UTF-8 BOM/RFC 4180/CRLF 候选内容。 |
| `updater/UpdateManifest.h` | 声明应用/数据版本、各版事件字段与缺省值、含显式删除字段的连续迁移描述和程序文件变更清单。 |
| `updater/UpdateManifest.cpp` | 严格读取发布 JSON，验证版本、字段定义、缺省值、迁移步长/ID/源版本唯一性，以及旧字段消失是否在 `removedFields` 显式确认。 |
| `updater/UpdateCoordinator.h` | 声明 `UpdateOptions` 和 `UpdateCoordinator::execute()` 安装/更新事务入口。 |
| `updater/UpdateCoordinator.cpp` | 锁定数据目录、用已登记表头探测 CSV 架构、阻止降级/未知格式、创建并校验永久备份、生成候选迁移文件、调用正式仓储验证后原子替换，并在后续状态写入失败时恢复备份。 |
| `updater/UpdateHistoryWriter.h` | 声明不记录事项正文的 JSONL 更新历史追加接口。 |
| `updater/UpdateHistoryWriter.cpp` | 追加版本、架构、文件变更、数量、哈希、备份位置、时间和结果；日志失败显式返回。 |
| `updater/manifests/0.1.0.json` | 首个发布清单；固定应用 0.1.0、event schema 1、settings schema 1，登记 13 个稳定字段及字符串缺省值，不声明不存在的旧格式迁移。 |
| `updater/README.md` | 独立迁移器的职责、同名字段复制/新增缺省/显式删除策略、安全失败和未来架构升级门禁。 |

不提交的 `CMakeUserPresets.json` 已按本机 Qt 工具链生成，其职责见第 4 节；`.vs/`、`build/` 等可重建文件由第 13 节的生成规则统一覆盖。

## 4. 根目录文件

### `.gitignore` `[现有]`

作用：排除 CMake/IDE/编译产物及真实运行数据。

可编辑内容：新增生成目录、临时文件或本地数据规则。`CMakeUserPresets.json` 与 `src/.qmlls.ini` 均为本机/生成文件。禁止忽略 `docs/`、配置模板、迁移脚本、第三方许可证和测试数据样例。

### `.vscode/` `[现有]`

作用：为 VS Code 提供不依赖个人全局配置的轻量入口；所有动作仍复用 CMake Presets 与 `scripts/`，因此 VS Code、Qt Creator 和命令行不会形成三套构建规则。

- `extensions.json`：仅推荐 `ms-vscode.cpptools` 与 `ms-vscode.cmake-tools`，不强制安装主题或无关扩展。
- `launch.json`：提供 `cppvsdbg` 的 `To Do It: Debug (MSVC)` 配置；F5 先调用共享 Build 任务，再从 `build/local-dev/bin` 启动，并只给调试进程添加 Qt 6.11.2 MSVC DLL 路径以及 `${workspaceFolder}/data/event.csv` 的 `TODOIT_EVENT_FILE` 覆盖。
- `settings.json`：指定 Qt 自带 CMake 并启用预设；首次使用 CMake Tools 时选择 `local-dev`，个人调试偏好应留在用户设置。
- `tasks.json`：定义 Configure、Build、QML Lint、Test、Run 五个任务；QML Lint 向 `build.ps1` 传递 `-Target all_qmllint`，其余任务也只调用仓库脚本，路径与参数调整时需同步脚本和本节。

可编辑内容：共享且可复现的工作区体验。不得保存账号、密钥、绝对用户数据目录，或在任务中复制 C++/QML 业务逻辑。

### `CMakeLists.txt` `[现有]`

作用：定义项目版本、C++ 标准、Qt 组件、全局构建选项和顶层子目录。

主要逻辑：

- `project(ToDoIt VERSION ...)`：唯一应用版本来源；发布时同步安装包版本。
- `CMAKE_CXX_STANDARD 20`：要求 C++20 且关闭编译器扩展。
- `CMAKE_MSVC_RUNTIME_LIBRARY`：MSVC 使用动态运行库，Debug 对应 `/MDd`，Release 对应 `/MD`，与 Qt 官方 MSVC 二进制保持一致。
- 三类输出目录：可执行文件和 DLL 放到 `build/<preset>/bin`，静态库/导入库放到 `build/<preset>/lib`。
- `TODOIT_WARNINGS_AS_ERRORS`：开发/CI 可开启，普通首次配置默认关闭。
- `find_package(Qt6 ...)`：主程序加载 `Quick`、`QuickControls2`、`QuickDialogs2`、`QuickEffects`；`BUILD_TESTING=ON` 时才额外加载 `Test`，避免发布目标无条件依赖测试模块。
- `todoit_fix_localized_msvc_dependencies()`：仅修正已知中文 MSVC/CMake 3.30 依赖前缀乱码，使 Ninja 能隐藏并追踪 `/showIncludes` 输出。
- `add_subdirectory(...)`：先加入主程序，再加入不依赖 UI 的更新核心，最后在 CTest 开启时加入测试目标。
- Release 安装规则：安装 `assets/`、默认资源模板、第三方声明和与项目版本同名的不可变更新清单；任何 `data/` 内容均不进入安装集。缺少版本清单时配置直接失败。

可编辑内容：版本号、显式构建开关、新模块入口。不得在此堆放业务源文件清单或硬编码个人 Qt 安装路径。

### `CMakePresets.json` `[现有]`

作用：提供不含个人绝对路径的 `dev`、`release` 配置基线，固定 Ninja、构建类型、测试开关和输出目录约定；本机预设继承它们。

可编辑内容：生成器、构建类型、项目级开关。Qt 本机路径放在用户预设 `CMakeUserPresets.json` 中且不提交，禁止把个人绝对路径写入共享预设。

### `CMakeUserPresets.example.json` `[现有]`

作用：给出推荐 `D:/Qt/` 布局下的 `local-dev`、`local-release` 配置、构建和测试预设示例，包括 Qt 6.11.2 `msvc2022_64`、`cl.exe` 与 Ninja 路径。`cl.exe` 依赖调用方预先导入 Visual Studio x64 开发环境，避免把会随 MSVC 更新变化的具体工具集目录固化到文件中。项目只启用 C++，因此不设置未使用的 `CMAKE_C_COMPILER`；CMake 可执行文件由命令行、脚本或 VS Code `cmake.cmakePath` 选择，不在预设内部自引用。

可编辑内容：只维护可复制的示例。实际安装路径变化时先复制成 `CMakeUserPresets.json` 再修改；不得把个人路径回写进本示例后误认为适合所有机器。

### `CMakeUserPresets.json` `[本机，现有且不提交]`

作用：本机已生成，引用 `D:/Qt/6.11.2/msvc2022_64`、由开发环境解析的 `cl.exe` 和 `D:/Qt/Tools/Ninja/ninja.exe`；提供 `local-dev` 与 `local-release` 的配置、构建和测试预设。Qt 安装的 `D:/Qt/Tools/CMake_64/bin/cmake.exe` 负责读取此预设。该文件只描述本机 SDK，不属于共享源码，也不进入安装包。

调用预设前必须通过 Visual Studio Developer PowerShell、Qt Creator 的 MSVC Kit，或 `scripts/Initialize-MsvcEnvironment.ps1` 取得 x64 `cl.exe`。不能让 PATH 中的 MinGW、Anaconda Qt 5 或其他 ABI 进入本构建。切换 Qt Kit、架构或编译器系列后必须使用 `configure.ps1 -Fresh` 或新的构建目录，不复用旧 `CMakeCache.txt`。

如果用户坚持项目本地 SDK，则路径指向 `.toolchains/Qt/`；`.toolchains/` 整体忽略。推荐方案仍是共享的 `D:/Qt/`。

### `README.md` `[现有]`

作用：面向新开发者说明产品、依赖、目录入口、强制开发手册规则、Qt LGPL 路线、已验证的本机 Qt 工具链，以及配置、构建、测试和打包命令。构建示例必须使用 Qt 自带 CMake 的绝对路径和本机预设，避免命中系统 PATH 中不兼容的工具。

可编辑内容：真实可执行的上手步骤与当前状态；实现变化后同步更新，避免复制 `proposal.md` 的全部产品细节。

### `ToDoIt.qmlproject` `[现有，Qt Design Studio]`

作用：提供 Qt Design Studio 可直接打开的视觉工程入口。`mainFile` 指向 `src/presentation/qml/Main.qml`；`QmlFiles` 递归收集正式 QML 源码，`ImageFiles` 暴露 `assets/`，`Files` 暴露 `config/*.json`，`qt6Project` 明确使用 Qt 6。`importPaths` 同时包含源码 QML 根与 `build/local-dev/src`，后者在完成本地配置后提供生成的模块元数据；`targetDirectory` 与正式模块 URI `ToDoIt` 的资源目录一致。

可编辑内容：设计期文件集合、主预览文件和相对导入路径。不得在此复制 CMake 构建逻辑、固定个人绝对路径或把 QDS 预览结果当作 Release 产物；新增运行时 QML 仍必须登记到 `src/presentation/qml/CMakeLists.txt`。

## 5. 资源、配置和开发数据

### `assets/`

作用：存放可替换、可打包但不包含用户隐私的视觉与文本资源。Logo、图标和背景图保持外部文件，以便用户替换；程序可内置最小应急图标，但不得覆盖用户文件。

#### `assets/logos/manifest.json` `[计划]`

逻辑名到默认目录内相对文件的映射，例如 `appLogo`、`searchLogo`、`attachmentLogo`。字段包括 `schemaVersion`、`key`、`relativePath`、`preferredSize`、`allowedFormats`，相对路径可包含子目录。

可编辑内容：相对路径、尺寸和格式，不得使用工作区外的绝对路径。

#### `assets/icons/manifest.json` `[计划]`

记录窗口、排序、附件、删除、刷新、拖拽等功能图标。功能键名是代码契约，换图时只改路径；重命名键必须同步 QML 和测试。

#### `assets/logos/default/app.svg` 与 `assets/icons/default/*.svg` `[现有]`

`app.svg` 是默认灰色圆角复选标志；功能图标当前包括搜索、最小化、最大化、还原、关闭、下拉、日期、升序、降序、添加事项和附件添加。所有文件均为小型 SVG，正式 QML 通过 `IconCatalog` 读取稳定 URL，不使用字体符号模拟图标。`add.svg` 与 `attachment-add.svg` 分别服务两个添加入口，禁止退回文字加号；`calendar.svg` 已作为未来日期选择弹窗资源登记，但当前时间编辑器没有展示不可操作的日期按钮。

可编辑内容：SVG 的路径、描边、填色和几何形状。文件名是资源契约；如需重命名，必须同时修改 `config/default-resources.json`、`IconCatalog.qml`、QML 资源清单及本开发手册。

#### `assets/quotes/philosophy_quotes.json` `[计划]`

每条记录包含 `id`、`text`、`author`、`source`、`verified`。`QuoteRepository::load()` 拒绝缺少作者/出处、未核验或默认窗口下需缩至 50% 以下才可显示的文本。

可编辑内容：经核验的短名言及出处。不得录入来源不明的网络语录。

#### `assets/themes/default-theme.json` `[计划]`

默认主题令牌：颜色、渐变、玻璃 tint、描边、高光、圆角、字号、间距、动画时长和可选背景图片路径。只存数据，不存 QML/JavaScript 逻辑。

### `config/default-settings.json` `[计划]`

首次运行配置模板。字段包含 `schemaVersion`、默认筛选“未完成事件”、搜索范围“全部”、窗口默认尺寸、主题 ID、`searchCollapseDelayMs: 800`、空草稿超时 2000 ms、自动保存延迟 1000 ms 和缩略图缓存上限。

可编辑内容：安全默认值。更新程序不得用模板覆盖已有用户配置，只能通过配置迁移补充缺失字段。

### `config/default-resources.json` `[现有]`

首次运行复制为 `data/config/resources.json`。顶层字段为 `schemaVersion`、`logos`、`icons` 和 `backgrounds`；资源分组包含 `defaultRoot` 与允许为空的 `customRoot`，Logo/图标分组的 `files` 进一步把稳定逻辑键映射到相对 SVG 文件名，不得在代码中另设不同名称的旁路配置。

解析规则：逻辑资源的相对路径不变；先在对应分组的 `customRoot` 查找同结构文件，单个文件缺失时回退 `defaultRoot`，默认文件也缺失时使用程序内应急资源。相对根路径一律以安装目录解析，绝不能受快捷方式的“起始位置”或进程当前工作目录影响；绝对根路径按原值使用。

用户可以手工编辑 `customRoot`。更新程序迁移并保留该文件，不用新版模板覆盖。

### `data/` `[现有，开发数据与样例]`

此目录保存格式说明、被忽略的本机开发数据和后续脱敏样例。真实发布用户数据仍位于安装目录的 `data/`，不得提交版本库。

- `event.csv` `[本机，现有且不提交]`：VS Code 调试和 `scripts/run.ps1` 默认读取的开发文件；当前仅含 UTF-8 BOM 与正式 13 列表头，不提供任何内置展示事项。开发者可按 `proposal.md` 追加自己的测试记录。
- `event.example.csv` `[计划]`：覆盖顶级、深层、空状态、富文本、多个附件和 CSV 转义的测试样例。
- `settings.example.json` `[计划]`：覆盖默认主题、窗口几何、筛选和多字段排序配置。

## 6. 构建模块

### `cmake/CompilerWarnings.cmake` `[现有]`

公开函数：

- `todoit_enable_warnings(target_name)`：为 MSVC 启用 `/W4 /permissive-`，为 GCC/Clang 启用 `-Wall -Wextra -Wpedantic`；按选项决定是否把警告视为错误。

可编辑内容：跨编译器等价警告。禁止使用全局字符串覆盖用户提供的编译器参数。

### `cmake/LocalizedMsvc.cmake` `[现有]`

公开函数：

- `todoit_fix_localized_msvc_dependencies()`：非 MSVC 立即返回；当且仅当 `CMAKE_CXX_CL_SHOWINCLUDES_PREFIX` 等于当前 CMake 3.30 对中文 UTF-8 文本产生的确切乱码时，将 C++ 与通用依赖前缀恢复为“注意: 包含文件:  ”。Ninja 随后能解析头文件依赖并隐藏扫描行。

可编辑内容：已复现的 CMake/MSVC 本地化兼容分支。匹配必须足够精确，禁止无条件改写英语、其他语言、Clang 或 MinGW 工具链；Qt/CMake 升级后先验证上游是否已修复，再决定保留或删除。

### `cmake/Dependencies.cmake` `[计划]`

公开函数：

- `todoit_configure_dependencies()`：定位 Qt 6.11 系列和固定的 QWindowKit 1.5.0。
- `todoit_validate_toolchain()`：检查 Qt 构建 ABI、x64 架构与当前 MSVC Kit 是否匹配，配置阶段失败并给出清晰说明。

只启用 QWindowKit Core/Quick；禁止自动跟随未固定的主分支。

### `cmake/Sanitizers.cmake` `[计划]`

- `todoit_enable_sanitizers(target)`：在兼容的 Debug 工具链启用 AddressSanitizer 与 UndefinedBehaviorSanitizer；不影响 Release 安装包。

### `cmake/InstallLayout.cmake` `[计划]`

- `todoit_configure_install_layout(target)`：声明可执行文件、Qt 运行库、外部资源、默认配置和迁移清单的安装位置；明确排除运行时 `data/`，防止更新覆盖用户数据。
- 通过 `qt_generate_deploy_qml_app_script()` 生成 Qt Quick 部署脚本，使 `cmake --install` 形成可直接交给安装器的 staging 目录。

### 开发 SDK（源码树外）

推荐布局：

```text
D:/Qt/
├─ 6.11.2/msvc2022_64/            Qt 库、工具与 windeployqt
└─ Tools/
   ├─ CMake_64/                   CMake 3.30.5
   ├─ Ninja/                      Ninja 1.12.1
   ├─ QtCreator/                  Qt Creator
   ├─ QtDesignStudio/             Qt Design Studio
   └─ QtInstallerFramework/       [计划安装，当前不存在]

D:/Microsoft Visual Studio/18/Community/
└─ VC/Tools/MSVC/14.51.36231/     x64 MSVC 编译器与运行库开发文件
```

除标记为计划的 Qt Installer Framework 外，上述开发工具已在本机安装；静态框架已完成 Debug 配置、编译、QML 检查、CTest 与运行时冒烟验证，CMake 报告 C++ 编译器为 x64 MSVC 19.51.36256.0。SDK 目录不属于项目结构、不提交，也不整体随软件分发。VS Code 的 Microsoft CMake Tools 通过 `CMakeUserPresets.json` 与 `cmake.cmakePath` 指向真实工具；Qt Creator 必须选择 Qt 6.11.2 MSVC 64-bit Kit；Qt Design Studio 只编辑/预览 QML，正式构建仍以根 CMake 为准。`twxs.cmake 0.0.17` 仅为编辑器扩展，建议禁用。系统 PATH 中另有 MinGW 与 Anaconda Qt 5，故禁止使用裸 `g++`、`qmake` 或未经核对的 `windeployqt` 构建/部署本项目。

## 7. 主程序 C++ 结构

### `src/CMakeLists.txt` `[现有]`

作用：先按依赖方向加入五个分层 target，再创建 `ToDoIt` 可执行目标，链接 Infrastructure、WindowsPlatform、PresentationControllers、Qt Quick/QuickControls2/QuickDialogs2/QuickEffects，启用警告并定义 Windows GUI 属性；通过 `include(presentation/qml/CMakeLists.txt)` 在创建可执行目标的同一 CMake 目录作用域内调用 `qt_add_qml_module()`，确保 Qt 能正确执行元类型提取、QML 类型注册和目标终结。目标安装到发行根目录，`qt_generate_deploy_qml_app_script()` 让 `cmake --install` 自动收集 Qt DLL、平台插件和 QML 运行模块。

可编辑内容：目标自己的源文件、私有链接库、所包含的模块清单和安装规则。禁止添加全局编译选项或个人路径；可执行目标作为 QML 模块 backing target 时，不得把其 `qt_add_qml_module()` 改回子目录作用域中的 `add_subdirectory()` 调用。

### `src/.qmlls.ini` `[生成，不提交]`

作用：`QT_QML_GENERATE_QMLLS_INI=ON` 时由 Qt/CMake 写入，告诉 VS Code、Qt Creator 或其他 QML Language Server 当前构建的模块导入路径。它可能随预设、Qt 版本或构建目录变化而更新。

可编辑内容：无。该文件不是产品配置，不进入安装包；若内容失效，应重新运行配置而不是手工修改。

### `src/main.cpp` `[现有启动装配]`

作用：保持最小化，只负责进程级启动和依赖装配。

当前逻辑顺序：

1. 构造 `QGuiApplication` 并设置应用/组织名称；
2. 在栈上构造 `AppShellController`，把 CMake 项目版本同步到 Qt 应用元数据；
3. 用 `QCoreApplication::applicationDirPath()` 构造 `InstallPaths`，默认得到 `[可执行文件目录]/data/event.csv`；仅当进程提供 `TODOIT_EVENT_FILE` 时改用该开发/诊断覆盖路径；
4. 构造 `CsvEventRepository`，同步执行一次 `load()`，并把仓储引用、结果与实际路径交给进程级 `EventDataController`；仓储先构造、后析构，覆盖控制器整个引用期；
5. 在栈上构造 `RichTextFormatter`，使用 `qmlRegisterSingletonInstance()` 在 URI `ToDoIt.Controllers` 1.0 下注册 `AppShell`、`EventData` 与 `RichTextFormatter`；
6. 加载 `qrc:/qt/qml/ToDoIt/Main.qml`，根对象为空时返回非零退出码；
7. 进入 Qt 事件循环。

后续在此处继续装配设置、平台服务及正式命令控制器，并初始化 QWindowKit。所有注册给 QML 的对象必须由进程级对象持有，生命周期覆盖 QML 引擎；`main()` 只负责组合，不复制 CSV 解析、保存或 UI 业务。

公开函数仅保留 `int main(int argc, char *argv[])`。业务逻辑不得写入 `main()`。

### 分层 CMake 目标 `[现有框架]`

#### `src/domain/CMakeLists.txt`

定义 `todoit_domain` INTERFACE target 及别名 `ToDoIt::Domain`，要求 C++20，并把 `src/` 暴露为统一公共包含根。当前头文件 `EventRecord.h` 通过接口目标向上层提供；新增纯领域实现时可转为真实静态库，禁止链接 Qt UI、文件格式或 Windows 库。

#### `src/application/CMakeLists.txt`

定义 `todoit_application` INTERFACE target 及别名 `ToDoIt::Application`，仅依赖 `ToDoIt::Domain`。当前通过公共包含根提供 `IEventRepository` 完整快照读写端口；出现应用层 `.cpp` 时再转为真实库，不得反向依赖 infrastructure、platform 或 presentation。

#### `src/infrastructure/CMakeLists.txt`

构建 `todoit_infrastructure` STATIC target 及别名 `ToDoIt::Infrastructure`，公开依赖 `ToDoIt::Application`，私有链接 `Qt6::Core`，显式编译 `InstallPaths`、`CsvCodec` 和 `CsvEventRepository` 并启用项目警告。Qt 仅用于 UTF-8、日期、UUID 和 JSON 校验；该目标不得依赖 presentation。

#### `src/platform/windows/CMakeLists.txt`

定义 `todoit_windows_platform` INTERFACE target 及别名 `ToDoIt::WindowsPlatform`，只依赖 `ToDoIt::Application`。QWindowKit、DWM、文件服务和缩略图实现后在此声明依赖；当前 target 不代表 Acrylic 或无边框平台适配已经完成。

`src/CMakeLists.txt` 按 Domain → Application → Infrastructure/WindowsPlatform/Presentation 的顺序加入子目录，主可执行文件只链接公开别名。Domain/Application 当前为仅头文件接口目标，Infrastructure/PresentationControllers 已是静态库。

### `src/domain/` `[现有记录模型，完整业务模型计划]`

作用：保存不依赖 UI、CSV 或 Windows 的业务实体和值对象。

#### `domain/model/EventRecord.h` `[现有]`

`EventRecord` 是仓储边界使用的普通 C++20 数据记录，字段为 `schemaVersion`、`eventId`、`parentId`、`siblingOrder`、`title`、`importance`、`startAt`、`completedAt`、`status`、`noteHtml`、`attachments`、`createdAt`、`updatedAt`。默认版本为 1、默认重要度为 5；字符串保持已校验的 UTF-8/ISO 8601 原值。它不含 CSV 列索引、QML 属性名、显示编号、持续时间或筛选状态，也不负责验证和修改业务。

#### `domain/model/EventId.h` `[计划]`

- `EventId::generate()`：生成 UUID。
- `EventId::parse(text)`：严格校验文本 UUID；失败返回显式错误。
- `toString()`：输出稳定的小写规范格式。

ID 创建后不可修改，迁移时只能保留或为确实没有 ID 的旧记录生成一次。

#### `domain/model/AttachmentRef.h` `[计划]`

只保存原文件绝对路径及可选显示名，不拥有文件。

- `normalizedPath()`：统一分隔符用于比较，不改变磁盘文件。
- `displayName()`：从路径提取文件名。
- `isSameTarget(other)`：按 Windows 路径大小写规则去重。

#### `domain/model/Event.h/.cpp` `[计划]`

事件聚合根，字段与 `proposal.md` 的 CSV 表一致，但不包含“当前可见序号”等临时 UI 状态。

关键函数：

- `Event::createDraft(now)`：创建仅驻留内存的草稿，默认重要度 5、开始时间为当前分钟、状态为空。
- `effectiveStatus()`：原始状态为空时返回业务语义“进行中”，不修改原始字段。
- `isCompleted()` / `isCancelled()`：只做严格状态判断。
- `changeStatus(newStatus, now)`：进入“已完成”时填当前完成时间；离开“已完成”时清空完成时间；不得级联子事件。
- `setStartTime(value)` / `setCompletedTime(value)`：先调用验证器，完成时间早于开始时间时拒绝。
- `setTitle(value)`：保存修剪后的名称；空名称返回验证错误；不检查跨事件唯一性，完全相同的标题合法。
- `id()`：返回不可变 UUID；所有编辑、拖拽、附件和删除命令只用 UUID 定位事件，禁止以标题定位。
- `attach(path)`：加入不重复的绝对路径引用。
- `detach(path)`：只删除引用，绝不删除原文件。
- `setNoteHtml(sanitizedHtml)`：只接受已经过白名单清理的 HTML。

所有修改函数返回结果对象，禁止用异常表示普通输入错误。

#### `domain/model/SortDescriptor.h` `[计划]`

定义字段 `Title/Importance/Start/Completed/Duration`、方向 `Ascending/Descending`、首次选择序号与活动状态。重复操作同一字段更新原描述符，不追加重复字段。

#### `domain/model/FilterCriteria.h` `[计划]`

保存状态筛选、搜索文本和搜索字段集合。空状态筛选值与显示文案“进行中”分离，避免把 UI 文案写回 CSV；只要存在空状态事件，可选状态集合必须含有效值“进行中”且不得暴露空字符串选项。

#### `domain/service/EventTree.h/.cpp` `[计划]`

维护 `event_id → Event` 与父子邻接表，是树结构唯一写入口。

关键函数：

- `insertRoot(event, position)`：插入一级事件。
- `insertChild(parentId, event, position)`：校验父节点存在后插入。
- `moveSubtree(eventId, targetParentId, position)`：整棵移动；先用 `isAncestorOf()` 阻止自身/后代投放，再一次性更新父关系与手工顺序。
- `reorderWithinParent(eventId, beforeOrAfterId)`：只调整同级 `sibling_order`。
- `childrenOf(parentId)` / `ancestorsOf(eventId)`：返回稳定手工顺序。
- `isAncestorOf(ancestorId, nodeId)`：沿父链检查，设置访问集防御损坏数据中的环。
- `validateForest()`：检查唯一 ID、父存在、无环、每个节点最多一个父。
- `renormalizeSiblingOrder(parentId)`：需要时重排稀疏顺序值，不改变视觉顺序。
- `removeSubtree(eventId)`：返回将被删除的完整子树快照，供确认、备份和事务删除；不得提升子事件。

删除必须由应用层在用户确认后调用，领域层本身不显示提示框。

#### `domain/service/EventValidator.h/.cpp` `[计划]`

- `validateForSave(event)`：校验标题、重要度、时间、状态长度、HTML 白名单结果和附件路径结构；标题只要求本事件非空，不做跨事件唯一性检查。
- `validateTimeRange(start, completed, now)`：完成时间存在时必须不早于开始时间且不得晚于当前时间；未来开始时间合法。
- `validateStatus(value)`：允许空、基础状态和合法自定义文本，拒绝纯空白/控制字符。

#### `domain/service/HierarchyNumberFormatter.h/.cpp` `[计划]`

- `format(depth, visibleSiblingIndex)`：`3n+1` 层用阿拉伯数字，`3n+2` 层用小写拉丁序列，`3n+3` 层用大写罗马数字。
- `toAlphabetic(index)`：支持 `a...z, aa...`。
- `toRoman(index)`：生成正整数罗马数字；超出合理显示范围时仍返回确定文本并记录诊断。

索引来自当前可见兄弟集合，因此筛选、搜索或排序后从该层第一个可见节点重新开始。

#### `domain/service/DurationCalculator.h/.cpp` `[计划]`

- `calculate(event, now)`：未来开始返回 `NotStarted`；已完成使用完成减开始；否则使用当前减开始。
- `format(durationState)`：输出“尚未开始”或“xxx 天 xx 时 xx 分”。

只计算值，不创建计时器。

#### `domain/service/ChildProgressCalculator.h/.cpp` `[计划]`

- `calculateDirectChildren(parentId, tree)`：只看直接子事件；已完成计入分子，已取消不计分母，其他状态计入分母；返回 `{completed, eligibleTotal, hasDirectChildren}`。

全部直接子事件已取消时返回 `{0, 0, true}`，界面显示 `0/0`。

### `src/application/` `[现有读写端口，业务用例计划]`

作用：编排用例、事务和自动保存，不了解 CSV 或具体 Windows API。

#### `application/port/IEventRepository.h` `[现有读写端口]`

- `EventLoadError`：保存从 1 开始的记录行号、可为空的列名和稳定英文底层错误；展示层负责本地化组合。
- `EventLoadResult`：保存 `std::vector<EventRecord>` 与可选错误；`succeeded()` 只在没有错误时返回真。失败结果不得同时携带可展示的部分事件。
- `EventSaveError` / `EventSaveResult`：保存与文件格式无关的保存失败信息；`succeeded()` 只在没有错误时返回真。
- `IEventRepository::load()`：纯虚读取入口，返回一次完整事件快照或结构化错误，不暴露 CSV 类型。
- `IEventRepository::save(snapshot)`：纯虚完整快照保存入口；调用方必须传入不含草稿的完整有效树，具体原子写入由基础设施实现。

`createBackup(reason)` 仍为后续计划；普通保存备份接入时应扩展明确端口，不能把备份策略塞入展示层。

#### `application/port/ISettingsRepository.h` `[计划]`

- `loadSettings()`：缺失时返回默认配置，损坏时返回恢复错误。
- `saveSettings(settings)`：原子保存用户偏好。

#### `application/port/IFileService.h` `[计划]`

- `openWithDefaultApplication(path)`：提交给系统默认程序，返回是否成功启动。
- `exists(path)`：检查附件目标是否仍存在。
- `selectFiles()` / `relocateFile(oldPath)`：由平台层实现文件选择与重新定位。

#### `application/port/IThumbnailProvider.h` `[计划]`

- `request(path, pixelSize, requestId)`：异步请求系统缩略图；用请求 ID 防止列表复用后把旧结果赋给错误行。
- `invalidate(path)`：文件时间戳改变或重新定位后清除缓存。

#### `application/port/IClock.h` `[计划]`

- `now()`：提供当前时间；生产实现使用系统时钟，测试实现可固定和推进时间。

#### `application/usecase/EventCommandService.h/.cpp` `[计划]`

- `createDraft()`：只创建内存草稿，不立即持久化。
- `commitDraft(draft)`：验证名称和字段，生成正式 ID，插入树并请求保存。
- `updateEvent(id, patch)`：应用单事件字段修改，验证后保存。
- `changeStatus(id, status)`：只修改目标事件；完成时间逻辑交给 `Event`。
- `moveEvent(request)`：执行子树移动/同级插入，成功后一次保存。
- `attachFiles(id, paths)` / `detachFile(id, path)`：只维护引用。
- `deleteSubtree(id, confirmationToken)`：验证确认令牌后创建备份、删除目标及全部子孙并一次保存；附件只解除引用。

#### `application/usecase/EventQueryService.h/.cpp` `[计划]`

- `buildVisibleTree(criteria, sortPipeline, now)`：先状态筛选，再实时搜索，再补祖先链，然后把排序流水线应用于每个可见兄弟集合，最后生成显示编号。
- `statusSummary(statusFilter)`：按状态筛选的完整集合计算顶部统计，不受搜索文本影响，也不把仅作为祖先显示的非匹配事件误计入分子。

查询返回不可变视图快照，QML 不自行重复计算。

#### `application/usecase/SortPipeline.h/.cpp` `[计划]`

实现用户确认的带检查点稳定排序：

- `appendOrUpdate(field, direction)`：新字段追加到末尾；已有字段保持原优先级位置，只更新方向。
- `captureCheckpoint(stepIndex)`：在每一步前后保存 `{parentId → siblingIds}` 顺序映射。
- `stableRefine(input, prefixCriteria)`：第一字段排序整个兄弟组；后续字段只排序此前所有字段值相等的连续组，保证先选字段优先。
- `recomputeFrom(stepIndex)`：恢复该步骤的输入检查点，重新执行该步骤及其后的所有活动步骤并更新检查点。
- `remove(field)`：恢复该字段执行前检查点，移除字段，再重新执行其后的步骤。
- `clear()`：恢复持久 `sibling_order`。
- `onSortableFieldCommitted(field)`：名称、重要度、开始/完成时间或状态编辑提交后，从最早受影响步骤重算。

示例 `A-B-C-D-B`：第二次操作 B 时恢复第一次 B 之前的 A 结果，更新并执行 B，再依次执行 C、D；取消 B 时恢复同一检查点，跳过 B 后执行 C、D。

空完成时间在升序时固定排在有效完成时间之后，在降序时固定排在有效完成时间之前。持续时间的一分钟显示刷新不调用 `recomputeFrom()`，只有开始/完成时间编辑提交等业务修改才重新排序。

#### `application/usecase/AutosaveCoordinator.h/.cpp` `[计划]`

- `markDirty(reason)`：累积修改版本；由单个 5 分钟周期计时器统一检查，不为每次输入重启短防抖。
- `flushIfDirty()`：仅有未落盘修改时创建最新快照并保存；5 分钟计时和正常退出检查调用，无修改时不打开文件。
- `onSaveFinished(version, result)`：只把对应或更新版本标为已保存，防止旧异步结果覆盖新状态。
- `suspend()` / `resume()`：迁移、恢复或严重解析错误时阻止自动写入。

同一时刻最多一个磁盘写入；保存期间的新修改在完成后再次刷新。

#### `application/usecase/DraftLifecycle.h/.cpp` `[计划]`

状态包含 `Hidden/Editing/PopupActive/IMEComposing/WaitingForDiscard/Valid`。

- `onFocusChanged()`、`onPointerChanged()`、`onKeyInput()`、`onImeChanged()`、`onPopupChanged()`：统一更新活动状态。
- `shouldDiscard(now)`：仅当标题为空、无焦点、无 IME/弹窗、指针离开且空闲超过 2 秒时返回真。
- `hasSecondaryContent()`：检测备注、非默认状态/时间或附件。
- `requestDiscardDecision()`：有次要内容时请求“丢弃/继续填写”；无次要内容直接允许丢弃。
- `resumeTitleEditing()`：用户选择保留时把焦点和文本光标恢复到名称栏。
- `discard()`：清除未持久化草稿并恢复添加按钮。

### `src/infrastructure/` `[现有 CSV 原子读写，备份及迁移计划]`

作用：实现 CSV、JSON、备份、原子文件和版本迁移。所有磁盘格式细节集中在此层。

#### `infrastructure/path/InstallPaths.h/.cpp` `[现有]`

- 私有构造函数保存传入的可执行文件目录，不读取进程工作目录。
- `fromExecutableDirectory(path)`：显式创建路径对象，便于启动装配和后续测试传入根目录。
- `installDirectory()`：只读返回安装根。
- `eventFile()`：返回 `installDirectory / "data" / "event.csv"`。

`settingsFile()`、备份/日志/缓存目录和 `ensureRuntimeDirectories()` 仍为后续计划；当前类不创建目录、不修改文件。

#### `infrastructure/persistence/CsvCodec.h/.cpp` `[现有只读解析]`

- `CsvRecord`：保存一条记录的起始物理行与原始 UTF-8 字段数组。
- `CsvParseError` / `CsvParseResult`：返回首个语法错误或全部记录，不抛出普通格式异常。
- `hasUtf8Bom(content)`：内部检查前三字节必须为 `EF BB BF`。
- `CsvCodec::parse(stream)`：一次读取字节流并用 RFC 4180 状态机解析；支持引号字段内的逗号、成对双引号、CRLF/LF 和换行，同时拒绝未闭合引号、裸字段内引号及闭引号后的非法字符。

`CsvCodec` 只负责读取语法状态机；记录编码由仓储保存链路实现。禁止改为 `split(',')`。

#### `infrastructure/persistence/CsvEventRepository.h/.cpp` `[现有原子读写仓储]`

`CsvEventRepository` 实现 `IEventRepository`，构造时保存目标路径；`eventFile()` 只读返回该路径。

- `initializeEventFileIfMissing()`：内部先以 `std::filesystem` 检查目标；文件缺失时创建父目录，再用 `QSaveFile` 原子提交 UTF-8 BOM、13 列表头和 CRLF。已有文件立即跳过，绝不覆盖；检查、建目录、写入或提交失败时返回明确错误。
- `load()`：二进制打开文件并调用 `CsvCodec::parse()`；严格匹配 13 列版本 1 表头，逐字段验证 UTF-8、版本、唯一 UUID、父 UUID、有限 `sibling_order`、非空标题、1/3/5/7/9 重要度、带偏移 ISO 8601 时间、完成状态时间、受限备注、绝对路径附件 JSON、创建/更新时间；最后验证父引用全部存在且父链无环。任一失败立即返回首个含行号/列名错误且不返回部分事件。
- `decodeUtf8()`：使用 `QStringDecoder` 拒绝非法 UTF-8。
- `hasExplicitOffset()` / `isValidIsoDateTime()`：要求日期合法且末尾有 `Z` 或 UTC 偏移。
- `decodeAttachments()`：只接受 JSON 字符串数组及绝对路径；空字段等价于空数组。
- `containsUnsafeRichText()`：拒绝脚本、远程/活动资源标签、链接属性与 `url()`；完整白名单净化将在写入链路补齐。
- `failure()`：统一构造不带部分数据的 `EventLoadResult`。
- `encodeCsvField()`：按 RFC 4180 判断是否加引号，并把字段内双引号成对转义；保留中文、换行和富文本字节。
- `encodeAttachments()` / `serialize()`：把附件绝对路径编码为紧凑 JSON，并按固定 13 列生成记录。
- `validateSnapshot()`：保存前重新校验版本、UUID、父引用、环、顺序、标题、重要度、时间、受限备注、附件路径和审计时间，禁止把无效内存状态落盘。
- `writeBytes()` / `writeRecord()`：检查每次写入长度，任一短写立即取消提交。
- `save(snapshot)`：创建缺失父目录，使用禁用直接写入回退的 `QSaveFile` 写入 BOM、表头和全部记录；只有 `commit()` 成功才替换正式 `event.csv`。

普通保存备份、恢复和迁移仍未实现。读取失败不得返回“空列表”伪装成功；`EventDataController` 会在加载失败时锁止写回，避免自动保存清空原文件。

#### `infrastructure/persistence/AtomicFileWriter.h/.cpp` `[计划]`

- `write(target, callback)`：在目标同目录创建唯一临时文件，调用回调写入，刷新并关闭，再校验临时文件。
- `commit(temp, target)`：使用可恢复替换；成功前保留旧文件，失败时清理临时文件并返回错误。

目标同目录可避免跨卷移动不具原子性。

#### `infrastructure/persistence/BackupManager.h/.cpp` `[计划]`

- `createRollingBackup(files)`：普通保存备份，成功后仅清理超过五份的普通备份。
- `createMigrationBackup(fromVersion, files)`：永久迁移备份，文件名含版本和 UTC 时间，不参与轮换清理。
- `listValidBackups()`：解析元数据并校验哈希。
- `restore(backupId)`：先备份当前损坏文件，再原子恢复选中版本。

#### `infrastructure/settings/JsonSettingsRepository.h/.cpp` `[计划]`

实现 `ISettingsRepository`。

- `loadSettings()`：解析 `schemaVersion`，合并默认配置中新增但用户文件缺失的键。
- `saveSettings(settings)`：使用原子写入；不得写入搜索内容、备注或其他非配置隐私数据。
- `validateThemeOverrides()`：限制颜色、数值范围及背景图片相对路径。

#### `infrastructure/content/JsonQuoteRepository.h/.cpp` `[计划]`

- `load(path)`：解析名言 JSON，校验 ID、正文、作者、出处和 `verified`。
- `filterForDefaultLayout(metrics)`：剔除默认布局下必须缩至正常字号 50% 以下才能完整显示的记录。

只读取发行内容，不写用户数据。

#### `infrastructure/content/ResourceLocator.h/.cpp` `[计划]`

- `loadConfiguration(resourcesJson, installRoot)`：读取 `logos/icons/backgrounds` 三组根目录，把相对路径固定解析到安装目录并校验规范化结果。
- `resolve(kind, logicalKey)`：从 manifest 得到统一相对路径，依次检查自定义根、默认根和内置应急资源。
- `reload()`：为未来即时刷新接口重新读取 JSON 和 manifest；首版在启动时调用。
- `configurationError()`：报告 JSON、路径越界或缺失默认资源，不阻止其他有效资源加载。

自定义目录允许复刻默认目录的任意子目录结构；一个文件缺失只触发该文件回退。

#### `infrastructure/migration/Migration.h` `[计划]`

迁移接口：

- `fromVersion()` / `toVersion()`：必须是相邻或被注册表明确允许的版本。
- `migrate(input, output, report)`：只操作暂存副本，记录增删改字段和告警。

#### `infrastructure/migration/MigrationRegistry.h/.cpp` `[计划]`

- `registerMigration(migration)`：启动时拒绝重复边。
- `resolvePath(from, to)`：找出确定的迁移链；缺一步即失败，禁止猜测格式。
- `migrateEventData(...)` / `migrateSettings(...)`：顺序执行并合并报告。

每个实际迁移放在 `migration/steps/EventV1ToV2.*`、`SettingsV1ToV2.*` 等独立文件中，旧迁移发布后不得重写语义。

#### `infrastructure/migration/IntegrityVerifier.h/.cpp` `[计划]`

- `verifyEvents(beforeSummary, migratedFile)`：校验可解析性、记录数预期、唯一 ID、父关系、无环、字段范围及附件条目数。
- `verifySettings(file)`：校验 JSON 和版本。
- `hashFile(path)`：为更新日志提供哈希，不读取内容到日志。

### `src/platform/windows/` `[现有目录与目标，业务代码计划]`

作用：隔离不可跨平台的窗口和 Windows Shell 能力。虽然产品仅支持 Windows，隔离后仍便于测试和替换库。

#### `platform/windows/window/WindowEffectsController.h/.cpp` `[计划]`

- `attach(QQuickWindow*)`：通过 QWindowKit 安装窗口代理，必须每个顶层窗口只安装一次。
- `setTitleBarItem(QQuickItem*)`：注册拖动标题栏。
- `setSystemButton(role, item)`：注册最小化、最大化和关闭按钮，使 Snap Layout/命中测试正常。
- `setInteractiveTitleItem(item)`：把搜索框等控件排除出拖动区。
- `applyBackdrop()`：Windows 11 优先请求 Acrylic/Mica；Windows 10 请求库支持的 DWM blur，并记录实际结果。
- `backdropAvailableChanged(bool)`：通知界面真实效果是否生效，禁止谎报。

平台边界：Windows 11 Build 22621+ 才有官方 Desktop Acrylic；Windows 10 路径依赖 QWindowKit 内部的非公开系统能力，不能承诺与 Windows 11 完全一致。系统策略强制实色时控制器只报告状态，不尝试用高成本截图/Shader 冒充桌面背景。

性能规则：原生/库调用只在创建、主题或窗口状态改变时执行；禁止在帧动画、事件行 delegate 或一分钟计时器中重复调用。

#### `platform/windows/shell/WindowsFileService.h/.cpp` `[计划]`

实现 `IFileService`。

- `openWithDefaultApplication(path)`：优先通过 `QDesktopServices::openUrl(QUrl::fromLocalFile(...))` 交给系统；成功提交后发出底栏消息，失败时给出可操作错误。
- `selectFiles()`：允许一次多选，不复制文件。
- `relocateFile(oldPath)`：默认打开旧文件父目录或最近有效目录，选中后更新引用。

#### `platform/windows/shell/WindowsThumbnailProvider.h/.cpp` `[计划]`

实现 `IThumbnailProvider`。后台有界队列调用 Windows Shell 缩略图/图标能力，结果转换为 QImage 后回到 UI 线程；缓存键包含规范路径、文件修改时间和请求尺寸。

- `request(...)`：内存命中立即返回，否则异步加载。
- `cancel(requestId)`：delegate 被回收时取消无用结果。
- `pruneCache(limit)`：按最近使用清理磁盘缩略图，不处理附件本身。

#### `platform/windows/WindowsClock.h/.cpp` `[计划]`

实现 `IClock::now()`，统一截断到分钟；业务测试不得直接读取系统时钟。

#### `platform/windows/InstallPathProbe.h/.cpp` `[计划，供安装器/诊断复用]`

- `probe(path)`：在目标中测试创建、写入、刷新、重命名和删除临时文件。
- `describeFailure()`：把 ACL/UAC、占用或磁盘错误转为明确提示。

#### `platform/windows/DpiCoordinator.h/.cpp` `[计划]`

- `onScreenChanged(screen)`：更新屏幕 DPI 与安全边距。
- `nativeHitTestThickness()`：计算无边框缩放命中宽度。
- `logicalThumbnailSize()`：保证不同缩放率下视觉尺寸一致。

### `src/presentation/controllers/` `[现有数据读写适配与富文本格式，命令控制器计划]`

作用：把应用用例和不可变视图快照转换为 QML 可绑定的属性、模型、信号和命令。

#### `presentation/controllers/CMakeLists.txt` `[现有]`

构建 `todoit_presentation_controllers` 静态库及别名 `ToDoIt::PresentationControllers`，公开 `src/` 包含根以及 `Qt6::Core`、`Qt6::Gui` 与 `ToDoIt::Application`，私有链接 `Qt6::Quick` 供实现访问 `QQuickTextDocument`。`TODOIT_PROJECT_VERSION` 只在该目标内部由 `${PROJECT_VERSION}` 生成；显式源清单包含 `AppShellController`、`EventDataController` 与 `RichTextFormatter`，新增控制器时继续应用项目警告规则。

#### `presentation/controllers/AppShellController.h/.cpp` `[现有框架]`

进程级 QML 单例，只暴露应用外壳元数据，不承载事件业务：

- `applicationName()`：返回稳定显示名 `To Do It`；
- `applicationVersion()`：返回根 CMake `PROJECT_VERSION`；
- `stageDescription()`：返回当前开发阶段说明；
- `backendReady()`：仅表示应用壳控制器已成功构造并可供 QML 绑定，不表示平台效果、备份恢复或完整事件业务已完成。

四项均为 `CONSTANT FINAL` 只读 `Q_PROPERTY`。可编辑内容是应用级元数据和可诊断框架状态；一旦状态需要运行时变化，应改为带 NOTIFY 的真实属性，禁止继续谎报常量。

#### `presentation/controllers/EventDataController.h/.cpp` `[现有读写视图适配]`

该进程级 QML 单例接收仓储 `const` 引用、一次 `EventLoadResult` 和实际文件路径。它不拥有仓储；`IEventRepository::load()` 与 `save()` 本身均为 const 操作，`main.cpp` 保证仓储生命周期覆盖控制器，并由控制器把 QML 完整快照提交给仓储。该 const-correct 接口同时修复了入口中 `const CsvEventRepository` 无法绑定非常量引用的编译错误。

- `events()` / `events`：返回 `QVariantList`；每项包含 `eventKey`、`parentId`、`titleText`、五段重要度索引、显示开始/完成时间、有效状态、持续时间、备注 HTML、以 `|` 连接的本地附件 URL、手工顺序和 `isDraft=false`。
- `eventFilePath()` / `eventFilePath`：返回本次实际读取路径，便于诊断。
- `loadError()` / `loadError`：加载失败时将底层错误组合为包含文件路径、行号、列名的中文信息；成功时为空。
- `saveError()` / `saveError`：最近一次保存失败的中文诊断，成功保存后清空，并通过 `saveErrorChanged()` 通知 QML。
- `loaded()` / `loaded`：表示启动快照是否完整加载成功；为假时 `saveEvents()` 始终拒绝写回，保护原文件。
- `createEventId()`：使用 `QUuid` 生成不带花括号的稳定 UUID，供新事项草稿成为正式事项后持久化。
- `saveEvents(rows)`：忽略的草稿已由 QML 快照排除；逐行验证 UUID、标题、重要度、时间与附件，把“进行中”转为空状态，保留既有 `created_at`、统一更新 `updated_at`，然后调用仓储 `save()`。
- `fromUtf8()`、`parseDateTime()`、`displayDateTime()`：内部把已校验 UTF-8/ISO 8601 值转换为本地 `yyyy-MM-dd HH:mm`；空完成时间显示破折号。
- `storageDateTime()`：把界面本地时间转换为带系统 UTC 偏移的 ISO 8601；空完成时间映射为空字段。
- `attachmentPaths()`：把 QML 本地文件 URL 转回本机绝对路径，拒绝相对附件路径。
- `durationText()`：已完成使用完成时间，未完成使用构造控制器时的当前时间；未来开始显示“尚未开始”。当前没有分钟计时器，持续时间只在启动装载时计算一次。
- `attachmentText()`：把绝对路径转换为 QML 可用的本地文件 URL，并以 Windows 文件名不允许出现的 `|` 连接供现有附件组件解析。
- `loadErrorText()`：格式化展示层诊断，不更改仓储结果。

启动事件、路径、加载错误和加载状态为 `CONSTANT FINAL`；保存错误是带 NOTIFY 的运行时属性。以后若支持重新加载，必须增加对应通知信号或拆分成可变模型，不得只修改内部成员造成 QML 不更新。

#### `presentation/controllers/RichTextFormatter.h/.cpp` `[现有选择范围格式器]`

该进程级 QML 单例不拥有备注文档，只在同步调用期间访问传入的 `QQuickTextDocument`：

- `selectedCursor(document, start, end)`：验证文档对象，把正反选择统一并夹紧到文档有效字符范围；空选择返回无效游标。
- `toggleBold(document, start, end)`：读取选择起点字重，在一个 `QTextCursor` 编辑块中只合并所选字符的 Normal/Bold 字重。
- `applyColor(document, start, end, color)`：验证颜色，在一个编辑块中只合并所选字符的前景色。

两个公开调用均用布尔值报告是否实际应用；不得保存文档裸指针、不得对没有选择的整段文字套用格式。

#### `presentation/controllers/EventTreeModel.h/.cpp` `[计划]`

继承 `QAbstractItemModel`，持有可见树快照而非真实仓储。

必须实现：

- `index()`、`parent()`、`rowCount()`、`columnCount()`：严格反映当前可见父子树。
- `data()` / `roleNames()`：提供 ID、显示编号、标题、重要度、时间、状态、持续时间、直接子进度、备注和附件角色。
- `flags()`、`mimeData()`、`canDropMimeData()`、`dropMimeData()`：桥接拖拽请求；真正合法性与写入交给 `EventCommandService`。
- `replaceSnapshot(snapshot)`：按稳定 ID 计算最小模型更新；无法安全增量更新时使用一次 reset，禁止逐字段触发整树重算。

#### `presentation/controllers/EventCommandController.h/.cpp` `[计划]`

- `commitEdit(eventId, patch)`：提交字段后触发验证、保存及必要的排序流水线重算；事件只以 UUID 定位，允许名称重复。
- `requestLeaveWithInvalidEdits(action)`：无效字段只保留在界面编辑会话，不写入领域快照或磁盘；存在无效修改时阻止页面切换或退出，并请求“放弃修改/继续编辑”。放弃时恢复仓储中的最后有效快照，继续时取消原动作并聚焦第一个错误字段；其他事件的合法编辑仍可独立保存。
- `requestDelete(eventId)`：构造子树数量和警告信息，打开确认框。
- `confirmDelete(eventId, token)`：校验一次性令牌并调用整棵删除；取消或过期令牌不得改变数据。
- `requestMove(dropRequest)`：区分前插、成为子级、后插和一级投放，并在活动排序时拒绝前/后插。

#### `presentation/controllers/FilterSortController.h/.cpp` `[计划]`

- `setStatusFilter(value)`：默认“未完成事件”。
- `setSearchText(value)` / `setSearchFields(fields)`：每次输入安排同事件循环合并刷新。
- `toggleSort(field, direction)`：调用 `SortPipeline::appendOrUpdate()`；点击相同活动方向时取消该字段。
- `removeSort(field)` / `clearSorts()`：通过检查点重算剩余步骤或恢复手工顺序。
- `sortHistory()`：仅供内部恢复与诊断，首版不暴露独立撤销 UI。
- `canManualReorder()`：存在活动排序字段时返回假；只有筛选/搜索时仍返回真。

#### `presentation/controllers/DraftEventController.h/.cpp` `[计划]`

暴露 `visible`、`title`、`editingState`、`discardCountdownActive`、`hasSecondaryContent` 等属性，并把 QML 的焦点、鼠标、键盘、IME 和弹窗事件转交 `DraftLifecycle`。两秒到期后按内容决定直接丢弃或请求确认；用户保留时发出 `focusTitleRequested()`。不得用单个 `hovered` 布尔值决定丢弃草稿。

#### `presentation/controllers/EditingStateCoordinator.h/.cpp` `[计划]`

- `beginEdit(componentId)` / `endEdit(componentId)`：登记所有可编辑控件。
- `setImeComposing()` / `setPopupActive()`：统一处理输入法、下拉框、日期框和文件框。
- `mayCollapse(componentId)`：只在没有编辑锁时允许搜索框、备注或草稿折叠。

该协调器覆盖已有事件和搜索框；`DraftLifecycle` 额外处理空草稿自动移除。

#### `presentation/controllers/AttachmentController.h/.cpp` `[计划]`

- `addFiles(eventId)`：多选后去重并请求保存。
- `removeReference(eventId, path)`：只解绑。
- `open(path)`：检查存在性并调用文件服务；成功时精确生成指定底栏提示。
- `relocate(eventId, oldPath)`：选择新文件并替换引用。

#### `presentation/controllers/StatusSummaryController.h/.cpp` `[计划]`

- `recalculate(allEvents, statusFilter)`：顶部统计分母始终为全部事件；祖先上下文不重复计数。
- `summaryText()`：输出数量与取整百分比；总数为零时百分比定义为 0%。

#### `presentation/controllers/MinuteTicker.h/.cpp` `[计划]`

- `start()`：对齐下一分钟边界后每分钟只发一个 `minuteChanged(now)` 信号。
- `stop()`：无窗口或应用退出时停止。

所有未完成事件共享该信号，不为每行创建 Timer。

#### `presentation/controllers/QuoteController.h/.cpp` `[计划]`

- `loadVerifiedQuotes()`：载入并验证名言资源。
- `chooseRandom()`：启动时随机且尽量避免连续重复。
- `nextRandom()`：响应手动刷新。
- `fontScaleFor(width, metrics)`：默认布局最低 50%；用户缩窗路径允许继续缩小。

#### `presentation/controllers/ThemeController.h/.cpp` `[计划]`

- `loadTheme(id)`：合并默认令牌与合法用户覆盖。
- `setColorToken()` / `setGradientToken()` / `setBackgroundImage()`：为未来设置 UI 预留。
- `saveOverrides()`：写入用户配置，不改源码主题文件。

#### `presentation/controllers/BottomStatusController.h/.cpp` `[计划]`

- `setEditingHint()`、`pinClickedHint()`、`setHoverHint()`、`showTransientMessage()`：按“编辑 > 点击固定 > 悬停 > 默认”解析当前文案。
- `showAttachmentOpened(fileName)`：输出“XXX已打开，请注意所有修改均将被保存！”。
- `showError(message)`：错误优先于普通临时消息，并保持到用户确认或问题解除。

#### `presentation/controllers/WindowController.h/.cpp` `[计划]`

- `minimize()`、`toggleMaximized()`、`close()`：标题栏按钮命令。
- `restoreGeometry()` / `persistGeometry()`：按屏幕可用区域校正并保存窗口位置。
- `backdropAvailable`：向 QML 暴露真实系统背景状态及错误说明。

## 8. QML 页面、组件、效果与样式

### `src/presentation/qml/CMakeLists.txt` `[现有]`

作用：由 `src/CMakeLists.txt` 使用 `include()` 在主目标目录作用域内加载，并用 `qt_add_qml_module()` 声明 `ToDoIt` QML 模块及当前全部页面、组件、效果、样式和默认 SVG。清单循环计算 QML 相对别名，并逐项把默认 SVG 映射到 `qrc:/qt/qml/ToDoIt/icons/`；`IconCatalog`、`Theme`、`Metrics`、`Typography`、`Motion` 设置 `QT_QML_SINGLETON_TYPE`，由 QML 模块统一提供。

可编辑内容：新增 QML 文件清单、单例属性和资源别名。文件移动后必须同步资源 URL、本地路径变量和本文件；新增长路径资源时必须逐项声明相对别名。该文件是被包含的目标清单，不是独立子目录入口，不得在这里创建另一个同名目标。

### `src/presentation/qml/Main.qml` `[现有主窗口框架]`

作用：唯一顶层窗口组合入口。

当前逻辑：创建 1360×820、最小 1100×680 的圆角无边框 `ApplicationWindow`，默认使用最终设计稿的石墨色系，绘制低饱和灰青、暗红和蓝灰环境光并装配带 `id` 的 `MainPage`；只读 `popupBackdropSource` 将该页面提供给应用内下拉弹层截取，最上层 `WindowResizeHandles` 为四边和四角补齐系统鼠标缩放。本阶段未连接 `WindowEffectsController`，没有 Acrylic/DWM；实色背景仍是平台效果接入前的明确回退，不得把应用内弹层模糊称为真实桌面磨砂。

可编辑内容：顶层窗口约束、应用级快捷键和页面装配。

### `src/presentation/qml/pages/MainPage.qml` `[现有 CSV 展示页面]`

按垂直顺序组合 `FramelessTitleBar`、`InfoFilterBar`、事件列表 `GlassPanel` 和 `BottomHelpBar`；事件列表内部再组合 `EventTableHeader` 与 `EventTreeView`。页面导入 `ToDoIt.Controllers 1.0`，将 `EventData.events` 和 `createEventId()` 工厂交给事件树，并把动态筛选选项、统计标签与计数绑定回信息栏。事件树发出完整快照时调用同步 `EventData.saveEvents()`；失败则重新置脏并优先显示 `EventData.saveError`。`flushPendingChanges()` 供根窗口关闭前刷新；页面仍通过 `pointInsideItem()`、`clearFocusWhenTappedOutside()`、延后 `TapHandler` 和 `releaseInputFocusRequested()` 协调输入焦点，不直接解析或写 CSV。

### `src/presentation/qml/components/` `[现有 CSV 展示、交互与快照保存协调]`

每个组件只公开必要属性/信号；颜色、圆角和间距必须引用 `Theme`/`Metrics`，禁止写散落魔法数。

| 文件 | 状态 | 作用与当前主要接口 |
| --- | --- | --- |
| `GlassPanel.qml` | 现有框架 | 默认内容容器；`surfaceLevel`、`panelRadius`、`contentPadding`、`interactive`，内容转交 `GlassSurface` |
| `GlassToolTip.qml` | 已实现统一提示 | `maximumTextWidth` 控制自适应宽度上限，正文可任意位置换行，背景复用 `PopupGlassBackground`；用于附件完整路径等悬停说明，不创建独立视觉风格 |
| `IconImage.qml` | 已实现 | `source`、`accessibleName`、`fallbackText`、只读 `loaded`；统一加载可替换图标文件，业务组件不得再硬编码 Unicode 图形 |
| `RoundIconButton.qml` | 已实现图标接口 | `iconSource`、`iconSize`、兼容性 `iconText`、`helpText`、`destructive`、`chromeStyle` 和 `helpVisibilityChanged()`；附件入口使用 18 px 图片，顶层窗口按钮静止无框、交互时才显示背景 |
| `FramelessTitleBar.qml` | 已实现主页面交互 | 无外层面板、底框或额外 level，表现为窗口原生顶层菜单栏；公开 `pointInsideSearch()` 和 `backgroundPressed()` 协调点击外部失焦，普通按下不启动系统移动，只有移动超过 `Qt.styleHints.startDragDistance` 后才调用一次 `startSystemMove()`，避免标题栏单击后 hover 失效；继续提供搜索信号与 SVG 窗口按钮 |
| `AppLogo.qml` | 已实现图标接口 | `source` 默认取 `IconCatalog.appLogo`，公开 `accessibleName`、`hasImage`；不再用文字复选符号模拟 Logo |
| `ExpandableSearchBox.qml` | 已实现主页面交互 | `text`、`selectedField`、`collapseDelay`、`queryEdited()`、`querySubmitted()`、`fieldChanged()`；圆形锚点固定并向右展开至 460 px；普通悬停离开仍延迟 800 ms，切换到外部控件后空搜索通过 `collapseImmediatelyIfIdle()` 立即收起，非空搜索保持展示 |
| `SearchFieldSelector.qml` | 已实现主页面交互 | 94 px 无内框紧凑选择器完整显示“全部/事项名称/备注/附件名称”，弹层最低 116 px、使用 `PopupGlassBackground` 模糊被覆盖页面并叠加深色石墨遮罩，不使用省略号；公开 `fieldSelected()` |
| `QuoteBanner.qml` | 已实现主页面视觉 | `quote`、`author`、`refreshRequested()`；名言和作者强制单行，正常宽度不放大，窗口缩小时可降至极小字号，双击只发出换句请求 |
| `StatusFilterComboBox.qml` | 已实现动态模型接口 | 默认系统筛选只有“未完成事项/全部事项”，外部 `options` 接收事件树根据 CSV 实际状态汇总的选项；下拉层使用 `PopupGlassBackground`，公开 `selectedStatus`、`filterRequested()` |
| `StatusSummary.qml` | 已实现动态统计展示 | `label`、`matchedCount`、`totalCount`、只读 `percentage`；不含固定 6 项/35% 的演示默认值，初始为 0/0，只格式化事件树传入的真实统计 |
| `InfoFilterBar.qml` | 已实现动态绑定接口 | 左侧单行名言，右侧彼此分离的筛选框和统计框；公开 `filterOptions`、`summaryLabel`、`matchedCount`、`totalCount` alias 及筛选/名言/帮助信号，不计算事件数据 |
| `FieldFrame.qml` | 已实现 | 原子字段统一圆角框；`contentPadding`、`highlighted`、`fillColor`，使用 `Theme.fieldOutline` 提供清晰而克制的字段边界 |
| `EventTableHeader.qml` | 已实现主页面交互 | 46 px 无子 level 的七列表头，使用半高低对比纵向分隔线明确列边界，标题字体增大，22 px 紧凑排序箭头紧贴字段名称；与列表共用相同列宽和 10 px 滚动条槽，发出排序请求并只显示方向状态，不显示数字优先级 |
| `SortButton.qml` | 已实现图标接口 | `direction`、`directionRequested()`；用 `sort-up.svg`/`sort-down.svg` 在 22 px 高范围内紧凑表示方向，活动箭头带主题强调色圆形底且不透明，另一方向弱化；再次点击活动方向请求取消，不显示优先级徽标 |
| `EventTreeView.qml` | 已实现 CSV 展示、交互与快照保存协调 | `replaceSourceEvents()` 装载真实快照且代码内无示例；动态生成状态、统计、筛选树和编号。`persistentSnapshot()` 排除空草稿，`schedulePersistence()` 仅标脏，单个 5 分钟 `persistenceTimer` 到期时由 `flushPersistence()` 检查并发出快照；无修改不打开文件，保存失败处理可重新置脏，正常关闭再检查一次。`eventIdFactory` 为草稿生成 UUID；独立拖动代理完成成为子项、同级前后插入和移回一级，`isDescendant()` 拒绝自身后代。`finishTitleEditing()` 释放名称焦点，鼠标不在卡内时清理备注状态 |
| `EventCard.qml` | 已实现主页面交互 | 完整事项外框是悬停、右键、左键激活和拖放命中区；不可见 `dragProxy` 由 `DragHandler` 移动并通过 `Drag.source` 保留事件 ID，避免只移动静态卡片导致 DropArea 无事件。标题 `onAccepted` 只提交一次、清除焦点并发出 `titleAccepted(pointerInside)`；备注面板以 220 ms 动画展开/收起 |
| `CompactDateEditor.qml` | 已实现交互与校验 | `text`、`allowEmpty`、只读 `editing`/`visuallyEmpty`、`invalidInput`、`valueEdited()`、`validationFailed()`；单一普通 `TextField` 固定为 16 字符并由 `digitPositions` 管理 12 个数字槽，不使用 Qt `inputMask`，因此鼠标可停在横线/空格/冒号前后，左右方向键逐字符移动；`enterDigit()`、`eraseBackward()`、`eraseForward()` 维护格式并自动跳到下一数字槽，提交时检查完整性、范围和闰年 |
| `ImportanceSelector.qml` | 已实现视觉接口 | `levelIndex`、`levelRequested()`；恰好五个低饱和蓝灰等宽分段，累计点亮映射 1/3/5/7/9，不显示数字 |
| `EditableStatusComboBox.qml` | 已实现视觉接口 | `statusText`、`statusOptions`、只读 `editing`、`statusEdited()`；既可输入也可从现有状态选择，状态色保持低饱和，下拉层统一使用应用内页面模糊和深色遮罩 |
| `AttachmentStrip.qml` | 已实现交互接口 | `attachmentKinds`、`addRequested()`、`removeRequested()`、`openRequested()`；接收真实文件 URL，左侧“附件”后只显示行高小块，末尾唯一添加入口以 `attachment-add.svg` 图片显示，悬停显示完整路径和解除关联按钮，双击请求系统打开；路径关联变化由事件树进入保存队列 |
| `ColorPalettePopup.qml` | 已实现自定义调色盘 | `selectedColor`、`applyRequested(color)`、`interactionStarted()`；圆形预设色与紧凑居中的 RGB 0–255、CMYK 0–100 输入实时双向同步，弹层保持打开以便重新选中文字并再次应用，点击关闭或外部区域才退出 |
| `RichNoteEditor.qml` | 已实现选择范围格式与自适应高度 | `text`、只读 `editing`、`noteEdited(html)`、`helpRequested(message)`；工具栏交互前保存非空选区，B 按钮和 `palette.svg` 按钮分别调用 `RichTextFormatter.toggleBold()` 或 `ColorPalettePopup`，应用后恢复选区。正文容器高度取最小高度与富文本 `contentHeight` 较大值，不使用内部滚动区域 |
| `AddEventButton.qml` | 已实现主页面交互 | 34 px 单一入口由普通 `Item`、`HoverHandler`、`TapHandler` 和 `DropArea` 组成，不再继承 Qt `Button` 的调色/焦点状态；中央并排显示 20 px `add.svg` 和“添加事项”，悬停只改变低对比背景与描边；`addRequested()` 创建草稿，`rootDropRequested()` 继续负责移回一级 |
| `WindowResizeHandles.qml` | 已实现窗口交互 | `hostWindow`、`handleWidth`、只读 `resizeEnabled`、`beginResize(edges)`；四条 6 px 边缘和四个 12 px 角落使用正确的水平/垂直/对角光标，按下调用 `Window.startSystemResize()`，最大化和全屏自动停用，不自行计算或持续写窗口几何 |
| `BottomHelpBar.qml` | 已实现主页面视觉 | `message`、`severity`；无外框单行底部提示，外边距与字号匹配，优先级由控制器处理 |
| `DropIndicator.qml` | 计划 | 显示“前插/成为子级/后插/移至一级”目标及非法投放状态 |
| `DateTimeEditor.qml` | 不再单独创建 | 连续固定格式输入及数字槽职责已合并到 `CompactDateEditor.qml`，跨字段时间关系由事件模型/正式控制器负责 |
| `ChildProgressBadge.qml` | 计划 | 固定宽度、小字号显示直接子进度；不在 QML 重新统计 |
| `AttachmentTile.qml` | 计划 | 系统缩略图、文件名、悬停删除按钮、缺失状态和重新定位；双击请求打开 |
| `DraftEventRow.qml` | 不再单独创建 | 当前草稿视觉复用 `EventCard.qml`，生命周期由 `EventTreeView` 管理；正式控制器接入后仍复用同一事件卡，避免两套布局 |

### `src/presentation/qml/dialogs/` `[现有目录，文件计划]`

- `ErrorDialog.qml`：显示不可内联处理的错误与诊断编号。
- `MissingAttachmentDialog.qml`：提供重新定位、保留引用、取消；不提供删除磁盘文件。
- `DataRecoveryDialog.qml`：CSV 损坏时列出有效备份及时间，不自动选择替用户覆盖。
- `DeleteSubtreeDialog.qml`：明确提示目标事件及所有子事件会一并删除，只有确认后签发一次性删除令牌。
- `InvalidEditDialog.qml`：切页或退出前提供“放弃修改/继续编辑”；不得提供绕过校验强制保存的按钮。

### `src/presentation/qml/effects/` `[现有静态框架]`

- `GlassSurface.qml` `[现有]`：`surfaceLevel`、`interactive`、`fillColor`；绘制圆角 tint、完整细描边及轻量颜色动画。已删除曾导致所有边框顶部出现横线的 1 px 高光层；它只处理应用内容材质，绝不捕获或模糊桌面。
- `PopupGlassBackground.qml` `[现有]`：使用 `ShaderEffectSource` 截取弹层覆盖的 `MainPage` 局部，再由 `MultiEffect` 模糊并覆盖高不透明度石墨 tint 与描边；`backdropSource`、`surfaceLevel`、`blurAmount` 是允许调整的视觉接口。它只用于 ComboBox 等应用内浮层，不能冒充 Windows Acrylic/DWM。
- `FocusRing.qml` `[计划]`：键盘焦点可访问性描边。
- `HoverGlow.qml` `[计划]`：轻量 hover 高光，属性动画只改变透明度/颜色。

禁止在每个事件行使用递归截图、Gaussian blur 或持续 ShaderEffectSource；真实桌面磨砂由窗口层一次完成。

### `src/presentation/qml/styles/` `[现有]`

- `Theme.qml`：QML 单例，默认启用最终设计稿的 `graphite` 石墨主题，提供环境光、内容材质、五段重要度及低饱和状态色令牌、`surfaceColor(level)`、`importanceColor(index)`、`statusColor(status)` 和 `useVariant(id)`；仍保留 `aurora` 作为未来可切换接口。
- `Metrics.qml`：1360×820 默认窗口、1100×680 最小窗口、6 px 窗口缩放热区、64 px 标题到搜索间距、460 px 搜索展开宽度、34 px 添加入口、统一圆角/紧凑间距，以及外卡到内框 6 px、字段间 4 px、事项间 8 px、26 px 附件缩略图、14 px 滚动槽、9 px 滚动条、12% 最小滑块比例和七列表格列宽。
- `Typography.qml`：默认使用 `Microsoft YaHei UI`，集中正文/辅助/标题字号和字重；名言由组件在正常字号上只缩不放。
- `Motion.qml`：`reducedMotion`、快/普通/搜索动画时长、220 ms 备注展开时长、260 ms 列表重排时长、800 ms 搜索收起延迟和统一缓动曲线。
- `IconCatalog.qml`：可写 URL 属性集中对应应用标志、搜索、窗口控制、下拉、日期、排序、添加事项、附件添加和备注调色盘图标；默认指向模块内 SVG，后续由资源定位器按自定义根目录逐文件覆盖。

样式切换修改这些令牌，不替换业务组件。未来背景图片路径来自用户配置覆盖。

## 9. 第三方依赖

### Qt 6.11.2 `[外部 SDK / 运行时动态库]`

首版使用 Qt 开源 LGPLv3 动态链接路线，当前直接依赖为 `Quick`、`QuickControls2`、用于附件系统多选框的 `QuickDialogs2`，以及用于应用内下拉背景模糊的 `QuickEffects`，并包括它们经审核的 LGPL 传递依赖。根 CMake 和 `cmake/Dependencies.cmake` 必须维护 Qt 模块许可白名单；新增 Qt 模块时先核对该确切版本的许可和 SBOM，GPL-only、未知许可或静态 Qt 目标在配置/打包阶段直接失败。

开发 SDK 已安装并验证于 `D:/Qt/`，不提交、不复制进最终安装包。发行目录只部署运行所需 DLL、插件和 QML 模块，并同时生成 Qt 版本、文件哈希、许可证、对应源码归档及 DLL 替换说明。若改用商业 Qt，必须先完成采购与许可迁移审查，禁止把商业和开源 Qt 混入同一构建。

### `third_party/README.md` `[现有]`

记录依赖名称、用途、固定版本/提交、上游地址、许可证、启用模块、本地补丁，以及外部 Qt SDK 与 LGPL 发布物规则。任何升级必须重新验证 Windows 10/11、Qt/MSVC ABI、x64 架构、窗口缩放、磨砂效果和许可证清单。

### `third_party/licenses/README.md` `[现有]`

要求发布者把官方、未修改的 `LGPL-3.0-only.txt` 作为 `scripts/package.ps1 -QtLicenseFile` 输入；许可正文不从网络自动下载，也不把本机 Qt SDK 路径提交到仓库。任何新增第三方库都必须先登记版本、许可和可再分发文本。

### `third_party/qwindowkit/` `[计划]`

QWindowKit 1.5.0 源码固定快照，Apache-2.0。仅构建 Core 与 Quick；关闭 Widgets、示例、文档和上游测试。它使用 Qt 私有实现和平台窗口能力，因此 Qt 升级时不得直接沿用旧二进制，必须重新编译并跑窗口回归测试。

禁止使用已归档的 FramelessHelper；其上游已明确迁移到 QWindowKit。

## 10. 安装、在线/离线更新和卸载

### `installer/` `[现有]`

使用 Qt Installer Framework 生成首次安装程序和 `ToDoItMaintenanceTool.exe`。传入 HTTPS 仓库时使用混合模式：安装器内含当前程序，可离线首装，同时把 GitHub Pages 仓库写入维护工具供用户主动在线检查。相同组件目录还由 `repogen` 生成在线仓库，并封装为可手工下载的离线更新 ZIP；在线更新、临时 `file:///` 离线更新和卸载均由维护工具执行。

#### `installer/config/config.xml.in` `[现有]`

定义产品名、版本占位符、发布者、开始菜单目录、每用户默认安装目录、维护工具名、窗口尺寸、许可证页面和卸载不删除根目录策略。`@TODOIT_REMOTE_REPOSITORIES@` 由打包脚本替换为空字符串或一个固定 HTTPS 仓库；仓库设置页面对用户隐藏，`SaveDefaultRepositories=true` 明确让维护工具保存正式仓库，`AllowRepositoriesForOfflineInstaller` 同时允许离线脚本传入当次临时本地仓库。

#### `installer/controller/installer-controller.qs` `[现有]`

- `Controller()`：读取 `LOCALAPPDATA`，将默认目录设为当前用户的 `Programs/ToDoIt`；目标目录页面仍允许用户修改。

脚本只做安装界面编排，数据判断全部交给 C++ 迁移器。

#### `installer/packages/com.todoit.app/meta/package.xml.in` `[现有]`

声明固定组件 ID `com.todoit.app` 的名称、版本/发布日期占位符、强制和关键组件属性、LGPLv3 许可页及 `installscript.qs`。打包脚本从根 CMake 读取版本并替换占位符。

#### `installer/packages/com.todoit.app/meta/installscript.qs` `[现有]`

- `Component()`：调用 `addStopProcessForUpdateRequest("ToDoIt.exe")`，避免更新运行中的主程序。
- `createOperations()`：先让 IFW 生成标准文件操作并创建应用/维护工具快捷方式；安装或更新的最后一个自定义操作执行新版本 `ToDoItMigrator`，非零退出码使维护事务失败。迁移器会恢复自己的数据备份，IFW 负责回滚此前包操作。
- `data/` 从不进入组件归档，配置同时设置 `RemoveTargetDir=false`，默认卸载不拥有也不删除用户数据。

#### `installer/update/` `[现有]`

- `apply-update.ps1`：参数 `InstallDir` 默认 `%LocalAppData%/Programs/ToDoIt`；验证 `repository/Updates.xml` 和维护工具存在后，以 `--add-temp-repository <file-uri> update com.todoit.app` 启动维护流程，退出码原样返回。
- `README.txt`：随更新 ZIP 提供解压、默认目录和自定义目录命令。

### `updater/` `[现有]`

#### `updater/CMakeLists.txt`

构建 `todoit_update_core` 静态库和别名 `ToDoIt::UpdateCore`，公开 Qt Core、私有复用 Infrastructure；`ToDoItMigrator` 是无 Qt Quick 的控制台目标，安装在主程序旁供 IFW 调用。

#### `updater/main.cpp`

解析 `--data-dir`、`--manifest`、`--mode install|update`。参数错误返回 2，协调器失败返回 3，成功返回 0；失败时也尽力追加历史日志，并向安装器标准错误输出原因和备份位置。

#### `UpdateManifest::load(path)`

读取 JSON 并要求非空应用版本、正整数事件/设置架构号。`eventSchemas` 为每个支持版本声明有序、唯一字段名和字符串缺省值，第一列必须是 `schema_version`，且必须包含当前目标结构。每个 `eventMigrations` 项必须有唯一 ID 和唯一源版本、只能描述 `n -> n+1`，并可通过 `removedFields` 显式批准删除字段；源结构中任何未在目标出现且未批准删除的字段都会使清单失败，以阻止意外重命名。程序变更摘要和 added/changed/removed 列表进入更新历史。

#### `EventCsvMigrator::migrate(source, targetSchema)`

接收 `CsvCodec` 已解析记录，不直接操作正式文件。它校验源表头无空白/重复字段和每行列数，按大小写敏感字段名复制同名值，把目标新增字段填为清单缺省值，把目标未定义字段从输出中省略，并把每行 `schema_version` 更新为目标版本。结果统一编码为 UTF-8 BOM、RFC 4180 和 CRLF，交给协调器验证与提交。

#### `UpdateCoordinator::execute(options)`

1. 读取清单和已有 `data/config/install-state.json`；
2. 要求清单目标架构与迁移器编译时支持架构完全一致；
3. 创建数据目录并用 `QLockFile` 取得迁移锁，崩溃锁 30 秒后才可判定陈旧；
4. 文件不存在时只写安装状态/历史，由主程序首次启动创建 CSV；
5. 文件存在时用 `CsvCodec` 解析 BOM/记录并探测统一 `schema_version`，拒绝无版本、混合版本和降级；
6. 创建 `data/backups/migrations/event-v<source>-to-v<target>-<time>-<uuid>.csv` 永久备份，并要求备份 SHA-256 与原文件完全一致；
7. 同架构时调用正式 `CsvEventRepository::load()` 完成全部字段和树关系校验，并要求校验前后 SHA-256 相同；
8. 旧架构只有在清单存在连续迁移路径时才调用 `EventCsvMigrator` 生成同目录临时候选文件；候选必须由新版本正式 `CsvEventRepository` 完整加载成功，才以关闭直接回退的 `QSaveFile` 原子替换正式 CSV；
9. 成功后原子提交 `install-state.json`，再追加历史；若事件已迁移但安装状态写入失败，则用永久备份恢复原 CSV。0.1.0 是首个正式架构，不存在可合理实现的 v0；未知格式始终保留原文件并失败。

#### `UpdateHistoryWriter::append(dataDirectory, report, error)`

向 `data/logs/update-history.jsonl` 追加一行紧凑 JSON，包含 UTC 时间、成功状态、模式、动作、版本、架构、事件数、事件文件/备份位置、前后 SHA-256 和程序变更列表；不记录标题、备注、附件路径正文等事项内容。

#### `updater/manifests/0.1.0.json` `[现有]`

首个不可回写发布清单，声明应用 0.1.0、事件架构 1、设置架构 1、完整 13 列字段顺序/缺省值、空迁移链和初始程序构成。未来发布先增加根项目版本，再新增同名清单；提高架构号时必须保留仍支持的旧结构、增加目标结构和连续迁移声明，并更新正式仓储及历史 fixture，不能只修改架构数字。

## 11. 开发脚本

- `scripts/Initialize-MsvcEnvironment.ps1` `[现有]`：参数 `VisualStudioInstallPath` 可覆盖自动探测；若当前进程已有 `cl.exe` 则直接复用，否则优先调用 `vswhere`，再使用已确认的 Visual Studio Community 回退路径。脚本通过 `VsDevCmd.bat -arch=x64 -host_arch=x64` 取得环境，使用大小写不敏感字典合并变量，并在宿主同时返回 `PATH` 与 `Path` 时优先保留含 MSVC 工具链的值；`VSLANG=1033` 只请求已安装的英文诊断，不永久修改用户或系统环境。
- `scripts/check-structure.ps1` `[现有]`：兼容 Windows PowerShell 5.1 与 PowerShell 7；枚举全部非生成项目文件（包括不提交的本机预设和当前存在的生成提示文件）并要求本手册出现其明确路径；存在 Git 仓库且工作区有变化时，要求 `docs/structure.md` 属于同一变化。`Get-ProjectRelativePath()` 使用经过根目录边界校验的字符串截取，避免依赖 .NET Framework 4.8 不存在的 `Path.GetRelativePath()`。脚本只读项目内容，不修改或删除文件。
- `scripts/configure.ps1` `[现有]`：参数 `Preset`（默认 `local-dev`）、`CMakePath`（默认 Qt 自带 CMake）、`Fresh` 与 `VisualStudioInstallPath`；先导入 x64 MSVC，再从项目根调用 `cmake --preset`。`-Fresh` 使用 CMake 官方缓存重建语义，适用于切换 Qt/编译器，不触碰源文件或用户数据；失败原样传播。
- `scripts/build.ps1` `[现有]`：参数 `Preset`、`CMakePath`、`Parallel`、`Target` 与 `VisualStudioInstallPath`；导入 MSVC 后从项目根调用 `cmake --build --preset`，按需追加并行度或单一目标（例如 `all_qmllint`），失败原样传播。
- `scripts/test.ps1` `[现有]`：参数 `Preset`、`CTestPath` 与 `Parallel`；验证 Qt 自带 CTest 后从项目根调用 `ctest --preset` 并原样传播失败。测试预设本身为进程提供 Qt DLL 路径，无需编译器环境。本阶段 QML lint 由 `build.ps1 -Target all_qmllint` 执行，Sanitizer 尚未集成。
- `scripts/run.ps1` `[现有]`：参数 `Preset` 与 `QtBinPath`；验证 `build/<preset>/bin/ToDoIt.exe` 和 Qt bin 后，只为当前进程前置 Qt 路径；若项目根 `data/event.csv` 存在，再为子进程设置 `TODOIT_EVENT_FILE` 并同步启动程序。运行无需导入 MSVC 开发环境；脚本不运行 `windeployqt`，也不改变持久 PATH 或用户数据。
- `scripts/package.ps1` `[现有]`：参数为 `Preset`、`CMakePath`、可选 `IfwRoot`/`RepositoryUrl` 和必填 `QtLicenseFile`。它先确认 Release 主程序、迁移器、版本清单与许可文件存在，HTTPS 校验可选仓库地址，再把受根目录边界保护的 `out/package-work` 作为唯一可清理临时目录；执行 `cmake --install` 而不构建，为部署载荷生成逐文件大小/SHA-256 `release-files.json`，填充 IFW XML 模板。传入仓库地址时调用 `binarycreator --hybrid`，否则使用 `--offline-only`；随后调用 `repogen`，输出首次安装 EXE、离线更新 ZIP、在线仓库 ZIP、清单、发布元数据和覆盖这些附件的 `SHA256SUMS.txt` 到 `out/packages/`，失败直接终止。
- `scripts/prepare-github-release.ps1` `[现有]`：必填 `Owner` 与 `Repository`，从 `publish-metadata.json` 读取并校验三段版本，限制 GitHub 标识字符，要求固化地址精确等于 `https://OWNER.github.io/REPOSITORY/updates/windows/x64`，并在复制前逐个核对 `SHA256SUMS.txt`；只在项目 `out/github-publish/v<version>/` 内清理和重建内容，将安装器、两类仓库 ZIP、清单、元数据及哈希复制到 `release-assets/`，把在线仓库解压到 `pages/updates/windows/x64/` 并生成 `.nojekyll`。脚本不调用 Git、GitHub API 或网络上传。

脚本可编辑工具参数和步骤，不得重新实现 CSV 迁移、事件验证或备份算法。

## 12. 测试结构

### `tests/CMakeLists.txt` `[现有框架]`

创建 `ToDoItAppShellControllerTest` 与 `ToDoItUpdateCoordinatorTest`，分别链接展示控制器和 `ToDoIt::UpdateCore`，注册 CTest 名称 `ToDoIt.AppShellController` 与 `ToDoIt.UpdateCoordinator`。测试进程的 `ENVIRONMENT_MODIFICATION` 从 `Qt6::Core` 目标目录推导运行库路径，只为测试进程前置 PATH，绝不修改用户或系统 PATH。后续按模块继续注册 Qt Test 目标和 fixture；除非出现明确缺口，不引入第二套 C++ 测试框架。

### `tests/framework/AppShellControllerTest.cpp` `[现有]`

使用 `QTEST_GUILESS_MAIN` 创建无界面测试进程：

- `exposesApplicationMetadata()`：断言应用名为 `To Do It` 且 CMake 注入版本非空；
- `reportsReadyBackend()`：断言框架控制器报告已正确构造。

可编辑内容：应用壳公开契约和启动装配前置条件；不得把该测试的通过解释为事件、CSV 或平台效果已经完成。

### `tests/updater/UpdateCoordinatorTest.cpp` `[现有，未执行]`

- `validatesAndBacksUpCurrentSchema()`：使用临时目录验证 v1 文件字节不变、迁移备份与安装状态存在；
- `refusesToGuessAnUnversionedSchema()`：无 `schema_version` 的历史样例必须失败且原字节不变；
- `initializesWithoutCreatingEventData()`：首次安装没有事件文件时成功记录状态，但不抢先创建 `event.csv`；
- `addsDefaultsAndDropsRemovedColumns()`：直接验证通用转换按同名字段保留数据、把新增列填为缺省值并从目标输出中移除旧列；
- `refusesImplicitFieldRename()`：旧字段从目标结构消失但未列入 `removedFields` 时，清单加载必须失败并提示可能发生字段重命名。

本批次遵循用户要求只编辑文件，新增测试尚未编译或运行。

### 计划测试文件

| 文件 | 覆盖逻辑 |
| --- | --- |
| `tests/domain/EventTreeTest.cpp` | 插入、无限级、整棵移动、同级排序、非法自身/后代投放、环检测、同名事件以 UUID 独立操作 |
| `tests/domain/NumberingTest.cpp` | 三层循环、字母跨 z、筛选后重编号 |
| `tests/domain/DurationTest.cpp` | 已完成、未完成、未来开始、非法时间 |
| `tests/domain/ChildProgressTest.cpp` | 只看直接子级、取消不进分母、自定义状态进分母、全取消边界 |
| `tests/application/FilterContextTest.cpp` | 状态命中、祖先补齐、不匹配子孙隐藏、最新未完成规则 |
| `tests/application/MultiSortTest.cpp` | A-B-C-D-B 检查点、方向更新、取消中间键、稳定分组细化、空完成时间、计时不重排 |
| `tests/application/MoveEventTest.cpp` | 前插、后插、成为子级、移回一级、筛选/排序场景 |
| `tests/application/DraftLifecycleTest.cpp` | 焦点、鼠标、键盘、IME、弹窗和空闲超时状态机 |
| `tests/application/DeleteSubtreeTest.cpp` | 确认令牌、完整子树删除、附件只解绑、保存失败回滚 |
| `tests/application/InvalidEditGuardTest.cpp` | 无效值不落盘、其他事件可保存、放弃恢复、继续编辑聚焦首错误字段 |
| `tests/infrastructure/CsvRoundTripTest.cpp` | 中文、逗号、引号、换行、受限 HTML、多附件 JSON 往返 |
| `tests/infrastructure/CsvEventRepositoryLoadTest.cpp` | BOM、13 列表头、UTF-8、UUID、父引用、环、时间、附件 JSON、失败不返回部分事件及表头-only 空快照 |
| `tests/infrastructure/AtomicSaveTest.cpp` | 写入失败、进程中断模拟、旧文件保留 |
| `tests/infrastructure/BackupManagerTest.cpp` | 五份轮换、永久迁移备份、恢复校验 |
| `tests/infrastructure/MigrationTest.cpp` | 每条历史迁移、链缺失、损坏数据、回滚 |
| `tests/infrastructure/ResourceLocatorTest.cpp` | 自定义根、嵌套路径、单文件回退、绝对/相对路径、损坏 JSON |
| `tests/infrastructure/LicenseManifestTest.cpp` | Qt 模块白名单、SBOM 解析、动态库判定、许可证与对应源码归档完整性 |
| `tests/presentation/EditingStateTest.cpp` | 编辑时备注/搜索/草稿不折叠 |
| `tests/qml/SearchBoxTest.qml` | 固定锚点、向右展开、799/800 ms 收起边界、重入取消、焦点/输入法/弹层/输入锁定 |

测试 fixture 放 `tests/fixtures/`，只使用合成脱敏数据。发布过的数据格式至少保留一个 fixture，防止更新器失去旧版本迁移能力。

## 13. 运行时目录（不提交真实内容）

```text
[InstallDir]/
├─ ToDoIt.exe
├─ ToDoItMigrator.exe
├─ ToDoItMaintenanceTool.exe
├─ release-manifest.json          当前发布/数据架构清单
├─ release-files.json             程序文件大小与 SHA-256
├─ assets/                         发行默认资源
├─ data/
│  ├─ event.csv                   用户事件
│  ├─ config/
│  │  ├─ install-state.json       已安装应用/事件架构版本
│  │  ├─ settings.json            用户行为与主题配置
│  │  └─ resources.json           默认/自定义资源根目录
│  ├─ customization/
│  │  ├─ logos/                   用户替换 Logo
│  │  ├─ icons/                   用户替换图标
│  │  └─ backgrounds/             用户背景图
│  ├─ backups/                    普通与永久迁移备份
│  ├─ cache/thumbnails/           可重建缓存
│  └─ logs/update-history.jsonl   更新历史
└─ licenses/                      Qt、QWindowKit 等许可证
```

资源解析顺序：`resources.json` 中对应分组的 `customRoot` → 同分组的 `defaultRoot` → 程序内最小应急资源。`data/customization/` 只是安装器预建且推荐使用的自定义根目录；用户也可把 `customRoot` 指向其他绝对路径。更新器不得删除或覆盖安装目录内的 `data/customization/`，也不得修改外部自定义目录。

卸载默认保留整个 `data/`，因此卸载后安装目录可能不会完全消失；只有用户明确选择删除数据时才移除。

## 14. 现有 README 边界文件

`assets/*/README.md`、`assets/*/default/README.md`、`assets/themes/backgrounds/README.md`、`config/README.md`、`data/README.md`、`installer/README.md`、`scripts/README.md`、`src/*/README.md`、`tests/README.md`、`third_party/README.md` 和 `updater/README.md` 用于在进入目录时快速说明边界。

可编辑内容：该目录的简短职责和关键禁令。详细类/函数契约以本文件为准；两者冲突时必须立即修正文档，不能让冲突长期存在。

## 15. 当前实现状态

当前已完成：Domain/Application/Infrastructure/WindowsPlatform/Presentation 分层 target；进程级 `AppShell`、`EventData` 与 `RichTextFormatter` QML 单例入口；`EventRecord`、完整快照读写仓储端口、安装路径解析、UTF-8 BOM/RFC 4180 CSV 解析、13 列事件反序列化、树关系校验和 `QSaveFile` 原子序列化；依据最终设计稿实现的高保真主页面；集中主题、尺寸、排版、图标和动效令牌；VS Code 任务与 Qt Creator/Qt Design Studio 共用的 MSVC + Ninja 预设；配置/构建/指定目标/QML 检查/测试/运行脚本；Release CMake Install/Qt QML 部署、Qt IFW 混合/纯离线安装模板、GitHub Pages 在线仓库与离线更新包整理脚本、版本化字段清单、按稳定字段名通用迁移、显式删除字段门禁、迁移锁/永久备份/候选校验/原子替换/失败恢复/SHA-256/更新历史，以及应用壳和更新协调器两项 Qt Test 源码；共享/本机预设、默认资源路径模板、目录契约、需求基线和本开发手册。

当前主页面已经显示无外框顶层菜单栏、SVG Logo 与窗口按钮、四边四角鼠标缩放、只在移动超过系统阈值后启动的标题栏拖动、460 px 搜索、延后判断的页面级点击外部失焦、带页面模糊与深色遮罩的统一下拉弹层、等高信息栏、紧凑排序表头、层级事项卡、独立字段框、重要度、可编辑状态、固定数字槽时间、直接子项比例、220 ms 平滑且目标锁定的单一备注区域、覆盖滚动视口完整高度的 9 px 主题滚动条、独立附件添加 SVG，以及同时显示 20 px 加号图片和“添加事项”文字的 34 px 添加入口。备注 B 与调色盘只格式化当前选中文字；新事项名称按 Enter 后提交并释放文本光标，鼠标已离开整卡时同时收起备注。

当前事项已接通 `event.csv` 双向快照：启动时从可执行文件相对 `data/event.csv` 读取，开发启动可用 `TODOIT_EVENT_FILE` 覆盖；目标不存在时先原子创建父目录与表头-only 空文件，已有文件绝不覆盖。严格加载失败时列表为空、底部显示文件/行/列诊断并锁止写回。有效字段编辑、备注格式、附件关联/解绑及树拖放只标记待保存；单个 5 分钟计时器仅在确有修改时生成不含空草稿的完整快照，保存前再次校验并原子提交，正常关闭前再次检查并只刷新未落盘修改；失败时保留待保存标记。拖动整卡可成为目标子事项、插入同级前后或投放到添加入口移回一级，整棵子树随父 ID 关系保留，目标为自身后代时拒绝。右键删除事务、普通保存备份与恢复、完整富文本白名单净化、持续时间分钟刷新、系统缩略图和平台磨砂仍未接入。

本次 Release 安装、卸载、GitHub 在线/离线更新与字段迁移文件遵循用户的“只编辑文件”要求，未重新配置、编译、运行、执行 QML lint、测试、CMake Install、调用 Qt IFW 或生成安装包；上述“已完成”只代表源码、脚本、模板与文档已经静态写入，不代表本次版本已经运行验证。`ToDoItUpdateCoordinatorTest` 新增的字段迁移用例同样尚未执行。

此前应用壳基线已使用 `D:/Qt/Tools/CMake_64/bin/cmake.exe` 3.30.5、`D:/Qt/Tools/Ninja/ninja.exe` 1.12.1、Qt 6.11.2 `msvc2022_64` Kit，以及 Visual Studio 18 Community 提供的 x64 MSVC 19.51.36256.0，以 `local-dev` 预设完成全新配置与 Debug 编译；当时 `all_qmllint` 零警告、CTest 1/1 通过，并完成 3 秒启动冒烟。该历史结果不覆盖本次未执行的 CSV 改动验证。MSVC 不提供 UBSan，本阶段也尚未建立独立 ASan 预设，因此不声称 Sanitizer 已通过；更换 Kit 后必须使用全新缓存并重新验证。
