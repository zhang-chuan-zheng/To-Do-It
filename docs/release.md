# To Do It 发布、安装、更新与卸载手册

本文是当前发布链路的操作手册。工程采用 Qt Installer Framework（Qt IFW）：首次安装使用包含应用载荷的混合安装器，安装目录中的 `ToDoItMaintenanceTool.exe` 同时承担在线更新、离线更新和卸载。GitHub Releases 保存面向用户的下载附件，GitHub Pages 保存维护工具可读取的 Qt IFW 更新仓库。

当前待发布应用版本为 0.2.0，`eventSchema=1`、`settingsSchema=1`。历史 `updater/manifests/0.1.0.json` 必须保留且不可覆盖；本次使用新增的 `updater/manifests/0.2.0.json`。

发布脚本不会编译源码，也不会上传 GitHub。开发者必须先自行完成 Release 构建和验证，再运行脚本整理发布物。

## 1. 发布物与数据边界

每个版本生成以下文件：

- `ToDoIt-Setup-<version>-x64.exe`：首次安装用混合安装器；即使离线也能安装内置版本，联网后维护工具可检查 GitHub Pages 更新仓库。
- `ToDoIt-OfflineUpdate-<version>-x64.zip`：无法联网时供已安装用户手工更新。
- `ToDoIt-OnlineRepository-<version>-x64.zip`：待部署到 GitHub Pages 的 Qt IFW 仓库归档，也作为该版本仓库快照留档。
- `release-manifest.json`：应用版本、事件/配置架构、字段定义、迁移链和程序变更摘要。
- `publish-metadata.json`：本次打包版本、事件架构、固化的更新地址和安装器模式。
- `SHA256SUMS.txt`：上述发布文件的 SHA-256 校验值。

安装和更新载荷不包含 `[InstallDir]/data/`。`event.csv`、用户配置、迁移备份和更新日志不上传 GitHub，也不属于安装组件。默认卸载只移除程序组件并保留 `data/`；用户仍可在备份后手工删除遗留数据。

## 2. 一次性准备

1. 用 Qt Maintenance Tool 安装 Qt Installer Framework 的当前稳定版本。
2. 准备 Qt 官方、未经修改的 `LGPL-3.0-only.txt`，打包时通过参数传入。
3. 在 GitHub 新建源代码仓库，例如 `OWNER/REPOSITORY`；建议默认分支为 `main`。
4. 计划使用固定更新地址：

   ```text
   https://OWNER.github.io/REPOSITORY/updates/windows/x64
   ```

   仓库名或所有者一旦改变，旧安装器内保存的地址不会自动改变；应把地址视为发布接口。若必须迁移地址，需要在旧地址保留重定向或发布一个仍能访问旧地址的过渡版本。
5. 在 GitHub 仓库的 `Settings → Pages` 中选择 `Deploy from a branch`，待首次推送 `gh-pages` 分支后选择 `gh-pages` 和根目录 `/`。

Qt SDK、Visual Studio、Ninja、构建目录、`out/`、本机 `CMakeUserPresets.json` 和真实 `data/` 均不得提交或打入用户安装包；项目 `.gitignore` 已覆盖这些主要路径。

## 3. 版本号规则

应用版本使用 `MAJOR.MINOR.PATCH`：

- `PATCH`：修复且兼容现有数据格式，例如 `0.1.0 → 0.1.1`；
- `MINOR`：新增向后兼容功能，可能增加事件字段，例如 `0.1.1 → 0.2.0`；
- `MAJOR`：破坏性产品或兼容性变化，例如 `0.2.0 → 1.0.0`。

每次发布必须同时完成：

1. 修改根 `CMakeLists.txt` 的 `project(ToDoIt VERSION ...)`；
2. 新建同名 `updater/manifests/<version>.json`，禁止覆盖已经发布的旧清单；
3. 将包 `<Version>` 通过模板自动替换为同一版本；
4. 提交代码并创建完全相同版本的 Git 标签 `v<version>`；
5. GitHub Release 必须从该标签创建，已发布标签不得移动或复用。

Qt IFW 通过远程仓库 `Updates.xml` 中的组件版本与已安装版本比较；只有新包版本更高时才显示更新。

## 4. `event.csv` 架构升级规则

字段名是永久、大小写敏感的数据接口：已经发布的字段不得重命名。每份新清单的 `eventSchemas` 必须保留本次支持迁移的全部旧结构，并增加目标结构；每个字段同时声明字符串缺省值。`schema_version` 必须始终是第一列。

假设 v2 新增 `category`，并明确删除旧字段 `legacy_field`，清单核心应为：

```json
{
  "eventSchema": 2,
  "eventSchemas": [
    {
      "version": 1,
      "columns": [
        { "name": "schema_version", "default": "1" },
        { "name": "event_id", "default": "" },
        { "name": "legacy_field", "default": "" }
      ]
    },
    {
      "version": 2,
      "columns": [
        { "name": "schema_version", "default": "2" },
        { "name": "event_id", "default": "" },
        { "name": "category", "default": "未分类" }
      ]
    }
  ],
  "eventMigrations": [
    {
      "id": "event-v1-to-v2",
      "fromSchema": 1,
      "toSchema": 2,
      "removedFields": ["legacy_field"]
    }
  ]
}
```

同时必须把 `CsvEventRepository::supportedSchemaVersion`、正式表头、序列化/反序列化和领域记录更新到目标结构。迁移器按精确同名字段复制旧值；目标新增字段使用目标清单缺省值；旧字段只有在相邻迁移的 `removedFields` 中明确列出且目标确实不存在时才丢弃。任何未声明的字段消失都会阻止发布清单加载，避免误改字段名导致静默丢数。

更新时执行顺序如下：

1. 请求关闭 `ToDoIt.exe`，取得 `data/.migration.lock`；
2. 严格解析旧 CSV，并用其 `schema_version` 与已登记表头确定源结构；
3. 把原文件复制到 `data/backups/migrations/`，核对备份与原文件 SHA-256；
4. 确认存在逐级 `n → n+1` 的连续迁移声明；
5. 在同目录生成候选 CSV，按字段名迁移并使用 UTF-8 BOM、RFC 4180 和 CRLF 输出；
6. 使用新版本正式 `CsvEventRepository` 对候选文件执行 UUID、父子树、时间、附件及字段约束完整校验；
7. 校验成功后通过 `QSaveFile` 原子替换正式 `event.csv`；若安装状态提交失败，则从迁移备份恢复；
8. 把版本、架构、记录数、哈希、备份路径和结果追加到 `data/logs/update-history.jsonl`，不记录事项正文。

无版本表头、表头与登记结构不一致、缺少连续迁移、数据损坏、目标验证失败或旧数据版本高于安装包时，更新会中止且不会用猜测结果覆盖用户数据。

## 5. 开发者自行构建 Release

在项目根目录 PowerShell 中执行：

```powershell
.\scripts\configure.ps1 -Preset local-release -Fresh
.\scripts\build.ps1 -Preset local-release -Parallel 4
.\scripts\test.ps1 -Preset local-release
```

上述步骤由开发者执行。本次代码交付没有代为编译、运行或测试。正式发布前还应在没有安装 Qt 的干净 Windows 10 和 Windows 11 虚拟机分别验证首次安装、启动、在线更新、离线更新、迁移失败回滚、卸载保留数据以及重新安装后继续读取旧数据。

## 6. 生成安装器与更新仓库

把占位符替换为真实 GitHub 所有者和仓库名：

```powershell
$UpdateUrl = "https://OWNER.github.io/REPOSITORY/updates/windows/x64"

.\scripts\package.ps1 `
  -Preset local-release `
  -IfwRoot "D:\Qt\Tools\QtInstallerFramework\4.11" `
  -QtLicenseFile "D:\Licenses\LGPL-3.0-only.txt" `
  -RepositoryUrl $UpdateUrl
```

若省略 `-IfwRoot`，脚本会在 `D:\Qt\Tools` 下查找 `binarycreator.exe`。若省略 `-RepositoryUrl`，脚本只生成不固化网络地址的纯离线安装器；用于 GitHub 在线更新的正式发行版必须传入 HTTPS 地址。

脚本不会调用 `cmake --build`。它验证现有 Release 二进制和版本清单，执行 CMake Install/Qt 部署，生成 Qt IFW 混合安装器、在线仓库、离线更新包、发布元数据及 SHA-256。输出位于 `out/packages/`。

接着整理 GitHub 文件：

```powershell
.\scripts\prepare-github-release.ps1 `
  -Owner "OWNER" `
  -Repository "REPOSITORY"
```

该脚本会校验安装器固化的仓库地址，生成：

- `out/github-publish/v<version>/release-assets/`：上传 GitHub Release 的全部附件；
- `out/github-publish/v<version>/pages/`：部署到 `gh-pages` 分支根目录的完整静态内容。

两个打包脚本都只操作项目 `out/` 下的生成文件，不连接 GitHub。

## 7. 首次上传源代码到 GitHub

若当前目录尚未建立 Git 仓库，在项目根目录执行：

```powershell
git init
git branch -M main
git add .
git commit -m "chore: prepare To Do It v0.2.0"
git remote add origin https://github.com/OWNER/REPOSITORY.git
git push -u origin main
```

提交前用 `git status` 确认没有 `build/`、`out/`、`data/event.csv`、Qt SDK、许可证私有工作目录或本机预设。以后每次发布先在 `main` 完成代码审查和测试，再创建不可复用的版本标签：

```powershell
git tag -a v0.2.0 -m "To Do It 0.2.0"
git push origin main
git push origin v0.2.0
```

## 8. 发布 GitHub Pages 更新仓库

将 `out/github-publish/v<version>/pages/` 的内容提交到仓库的 `gh-pages` 分支根目录。建议在单独的临时克隆中操作，避免切换或清理开发工作区。`pages/` 根目录必须包含 `.nojekyll`，更新路径必须最终能够访问：

```text
https://OWNER.github.io/REPOSITORY/updates/windows/x64/Updates.xml
```

在 GitHub `Settings → Pages` 确认来源是 `gh-pages` 分支根目录。发布后先用浏览器确认 `Updates.xml` 和其中引用的组件归档均可下载，再发布 Release。不要只上传 `Updates.xml`；它引用的仓库归档也必须同时存在。

每次新版本都用本次生成的整个 `pages/` 树替换 `gh-pages` 工作树并提交，例如提交信息 `release: publish update repository 0.1.1`。更新仓库只含程序包，不得包含 `event.csv` 或任何用户数据。

## 9. 创建 GitHub Release

在 GitHub 仓库打开 `Releases → Draft a new release`：

1. 选择已有标签 `v<version>`，标题填写 `To Do It <version>`；
2. 在说明中列出用户可见功能、修复、数据架构变化、兼容性和已知问题；
3. 上传 `out/github-publish/v<version>/release-assets/` 中的全部文件；
4. 首个稳定版本可勾选 latest；预览版使用 `-rc.N` 标签并标记 pre-release；
5. 下载一次附件，用 `SHA256SUMS.txt` 核对后再正式发布。

面向普通用户的主要下载是 `ToDoIt-Setup-<version>-x64.exe`；离线更新 ZIP 供已经安装且无法连接 GitHub Pages 的用户使用；在线仓库 ZIP 和清单用于审计、复现及回滚调查。

## 10. 用户安装、更新与卸载

### 10.1 首次安装

用户双击 `ToDoIt-Setup-<version>-x64.exe`，接受许可证并选择安装目录。默认目录为 `%LocalAppData%\Programs\ToDoIt`。安装器包含当前版本，不要求联网；首次启动仅在 `[InstallDir]/data/event.csv` 不存在时创建正式空表头。

### 10.2 在线更新

用户关闭主程序，从开始菜单打开“To Do It 维护工具”，选择“更新组件”。维护工具访问安装器固化的 GitHub Pages 地址，读取 `Updates.xml` 并比较组件版本；发现更高版本后下载、校验、安装，并在最后运行数据迁移器。当前方案不在主程序后台自动检查或静默安装更新。

### 10.3 完全离线更新

用户完整解压 `ToDoIt-OfflineUpdate-<version>-x64.zip`，关闭 To Do It，在解压目录运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\apply-update.ps1
```

自定义安装目录：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\apply-update.ps1 `
  -InstallDir "D:\Your\ToDoIt"
```

脚本仅把 ZIP 内 `repository/` 作为本次维护工具进程的临时 `file:///` 仓库，不保存网络地址、不访问 GitHub。

### 10.4 卸载

用户从开始菜单运行“To Do It 维护工具”并选择删除所有组件，或执行：

```powershell
& "$env:LOCALAPPDATA\Programs\ToDoIt\ToDoItMaintenanceTool.exe" purge
```

默认卸载保留 `[InstallDir]/data/`。重新安装到同一目录后会继续读取旧数据，并在需要时迁移；若用户要彻底删除，应先备份，再手工删除保留目录。

## 11. 每次发布的强制检查清单

- [ ] `CMakeLists.txt`、清单文件名、`appVersion`、包版本和 Git 标签完全一致；
- [ ] 新清单保留所有受支持旧架构，新增字段有明确缺省值，删除字段在 `removedFields` 明确列出，没有重命名已发布字段；
- [ ] `CsvEventRepository::supportedSchemaVersion`、表头、领域对象与目标 `eventSchema` 一致；
- [ ] 已在旧版真实结构的脱敏副本上测试迁移，并验证记录数、UUID、父子关系、备注与附件路径；
- [ ] 已验证迁移失败时原 CSV 不变，备份可恢复，更新事务失败；
- [ ] 安装载荷不含 `data/`，卸载后数据仍存在，重新安装可读；
- [ ] GitHub Pages 的 `Updates.xml` 及所有引用归档可下载；
- [ ] Release 附件齐全且 SHA-256 一致；
- [ ] Qt 动态链接，许可证与第三方通知齐全，未打包 SDK、头文件、编译器或调试文件；
- [ ] 在干净 Windows 10/11 验证安装、启动、在线/离线更新和卸载；
- [ ] 正式发布前完成可信代码签名和恶意软件扫描。

任何一项未通过都不应创建正式 GitHub Release。
