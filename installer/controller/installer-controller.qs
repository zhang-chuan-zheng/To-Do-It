var todoitDataRemovalHandled = false;

function Controller()
{
    // Keep installation per-user and writable. The target page stays visible,
    // so a user may still choose a different directory.
    var localAppData = installer.environmentVariable("LOCALAPPDATA");
    if (localAppData !== "" && installer.isInstaller()) {
        installer.setValue("TargetDir",
                           localAppData.replace(/\\/g, "/") + "/Programs/ToDoIt");
    }

    installer.setValue("ToDoIt.PreserveUserData", "true");
    installer.setValue("ToDoIt.PurgeConfirmed", "false");
    gui.setSettingsButtonEnabled(false);

    // The package has one required component. Hiding these two pages prevents
    // empty selection screens without changing update or uninstall semantics.
    if (installer.isInstaller()) {
        installer.setDefaultPageVisible(QInstaller.ComponentSelection, false);
        if (systemInfo.productType === "windows")
            installer.setDefaultPageVisible(QInstaller.StartMenuSelection, false);
    }

    installer.uninstallationFinished.connect(
        this, Controller.prototype.handleUninstallationFinished);
}

function setPageHeading(pageId, title, subtitle)
{
    var page = gui.pageById(pageId);
    if (page === null)
        return;

    page.title = title;
    page.subTitle = subtitle;
}

function setChildText(page, objectName, value)
{
    if (page === null)
        return;

    var child = gui.findChild(page, objectName);
    if (child !== null)
        child.text = value;
}

function setStandardButtons(pageId, forwardText)
{
    gui.setWizardPageButtonText(pageId, buttons.BackButton, "返回");
    gui.setWizardPageButtonText(pageId, buttons.CancelButton, "取消");
    if (forwardText !== "") {
        gui.setWizardPageButtonText(pageId, buttons.NextButton, forwardText);
        gui.setWizardPageButtonText(pageId, buttons.CommitButton, forwardText);
    }
}

Controller.prototype.DynamicWelcomeWidgetCallback = function()
{
    var page = gui.pageByObjectName("DynamicWelcomeWidget");
    if (page !== null) {
        page.title = "欢迎";
        page.subTitle = "开始安装 To Do It @TODOIT_VERSION@";
    }
}

Controller.prototype.IntroductionPageCallback = function()
{
    setPageHeading(QInstaller.Introduction,
                   "您想进行什么操作？",
                   "选择更新、管理安装或卸载");
    setStandardButtons(QInstaller.Introduction, "继续");

    var page = gui.pageWidgetByObjectName("IntroductionPage");
    if (page === null)
        return;

    setChildText(page, "MessageLabel",
                 "To Do It " + installer.value("ProductVersion") + " 安装与维护");
    setChildText(page, "UpdaterRadioButton",
                 "检查更新    从已配置的 GitHub 更新仓库获取最新版本");
    setChildText(page, "PackageManagerRadioButton",
                 "管理安装    检查或重新部署可用程序组件");
    setChildText(page, "UninstallerRadioButton",
                 "卸载 To Do It    移除程序，并可选择是否保留用户数据");
}

Controller.prototype.LicenseAgreementPageCallback = function()
{
    setPageHeading(QInstaller.LicenseCheck,
                   "许可协议",
                   "请阅读并接受以下许可条款");
    setStandardButtons(QInstaller.LicenseCheck, "下一步");

    var page = gui.pageWidgetByObjectName("LicenseAgreementPage");
    if (page === null)
        return;

    setChildText(page, "LicenseInfoLabel",
                 "To Do It 使用 GNU Lesser General Public License v3。必须同意后才能继续安装。");
    setChildText(page, "AcceptLicenseLabel", "我已阅读并同意许可协议");

    var checkBox = gui.findChild(page, "AcceptLicenseCheckBox");
    if (checkBox !== null) {
        checkBox.visible = true;
        checkBox.enabled = true;
        checkBox.minimumHeight = 38;
    }

    var browser = gui.findChild(page, "LicenseTextBrowser");
    if (browser !== null)
        browser.minimumHeight = 330;
}

Controller.prototype.TargetDirectoryPageCallback = function()
{
    setPageHeading(QInstaller.TargetDirectory,
                   "选择安装位置",
                   "应用、用户事项与设置将保存在此目录下");
    setStandardButtons(QInstaller.TargetDirectory, "下一步");

    var page = gui.pageWidgetByObjectName("TargetDirectoryPage");
    setChildText(page, "MessageLabel",
                 "请选择 To Do It 的安装目录。更新和默认卸载不会覆盖或删除 data/event.csv。");
}

Controller.prototype.ReadyForInstallationPageCallback = function()
{
    var title = "准备安装";
    var subtitle = "确认后开始复制程序文件并初始化数据目录";
    var actionText = "开始安装";

    if (installer.isUpdater()) {
        title = "准备更新";
        subtitle = "更新前将校验 event.csv 架构，需要迁移时先创建完整备份";
        actionText = "开始更新";
    } else if (installer.isUninstaller()) {
        title = "准备卸载";
        subtitle = "确认程序和用户数据的处理方式";
        actionText = "继续卸载";
    } else if (installer.isPackageManager()) {
        title = "准备管理安装";
        subtitle = "确认要应用的程序组件变化";
        actionText = "应用更改";
    }

    setPageHeading(QInstaller.ReadyForInstallation, title, subtitle);
    setStandardButtons(QInstaller.ReadyForInstallation, actionText);

    var page = gui.pageWidgetByObjectName("ReadyForInstallationPage");
    if (page !== null) {
        if (installer.isUninstaller()) {
            var preserve = installer.value("ToDoIt.PreserveUserData") !== "false";
            setChildText(page, "RemoveAllMsgLabel",
                         preserve
                         ? "将删除应用程序，但保留 event.csv、配置、备份和更新日志。"
                         : "将删除应用程序和全部用户数据。此操作无法撤销。");
        } else if (installer.isUpdater()) {
            setChildText(page, "InstallMsgLabel",
                         "更新内容将写入现有安装目录；event.csv 仅在架构变化且验证成功时迁移。");
        } else {
            setChildText(page, "InstallMsgLabel",
                         "To Do It 将安装到：" + installer.value("TargetDir"));
        }
    }

    if (installer.isUninstaller()
            && installer.value("ToDoIt.PreserveUserData") === "false"
            && installer.value("ToDoIt.PurgeConfirmed") !== "true") {
        var answer = QMessageBox.question(
            "todoit.confirmPurgeData",
            "确认永久删除用户数据",
            "继续后将永久删除 data 目录中的 event.csv、备注、附件关联、配置、备份和日志。\n\n"
                + "此操作无法撤销。是否确认删除？",
            QMessageBox.Yes | QMessageBox.No,
            QMessageBox.No);

        if (answer === QMessageBox.Yes) {
            installer.setValue("ToDoIt.PurgeConfirmed", "true");
        } else {
            installer.setValue("ToDoIt.PreserveUserData", "true");
            installer.setValue("ToDoIt.PurgeConfirmed", "false");
            var options = gui.pageWidgetByObjectName("DynamicUninstallOptionsWidget");
            if (options !== null) {
                var keepRadio = gui.findChild(options, "KeepDataRadio");
                if (keepRadio !== null)
                    keepRadio.checked = true;
            }
        }
    }
}

Controller.prototype.PerformInstallationPageCallback = function()
{
    var title = "正在安装";
    var subtitle = "正在部署 To Do It 及完整 Qt 运行环境，请勿关闭窗口";
    if (installer.isUpdater()) {
        title = "正在更新";
        subtitle = "正在校验程序包、迁移数据并提交更新";
    } else if (installer.isUninstaller()) {
        title = "正在卸载";
        subtitle = "正在移除应用程序文件";
    } else if (installer.isPackageManager()) {
        title = "正在应用更改";
        subtitle = "正在检查并部署程序组件";
    }
    setPageHeading(QInstaller.PerformInstallation, title, subtitle);
    gui.setWizardPageButtonText(QInstaller.PerformInstallation,
                                buttons.CancelButton, "取消");
}

Controller.prototype.FinishedPageCallback = function()
{
    var title = "安装完成";
    var subtitle = "To Do It 已准备就绪";
    var message = "To Do It 已成功安装。您可以立即启动应用。";

    if (installer.isUpdater()) {
        title = "更新完成";
        subtitle = "程序与数据结构已经安全更新";
        message = "To Do It 已更新到最新版本。event.csv 与用户设置已保留。";
    } else if (installer.isUninstaller()) {
        title = "卸载完成";
        subtitle = "To Do It 已从此计算机移除";
        message = installer.value("ToDoIt.PreserveUserData") === "false"
                ? "应用程序与用户数据已删除。"
                : "应用程序已删除；event.csv、配置、备份和日志仍保留在原安装目录。";
    } else if (installer.isPackageManager()) {
        title = "更改完成";
        subtitle = "程序组件已经处理完成";
        message = "To Do It 的程序组件更改已经完成。";
    }

    setPageHeading(QInstaller.InstallationFinished, title, subtitle);
    gui.setWizardPageButtonText(QInstaller.InstallationFinished,
                                buttons.FinishButton, "完成");

    var page = gui.pageWidgetByObjectName("FinishedPage");
    setChildText(page, "MessageLabel", message);
    setChildText(page, "RunItCheckBox", "启动 To Do It");
}

Controller.prototype.DynamicUninstallOptionsWidgetCallback = function()
{
    var page = gui.pageByObjectName("DynamicUninstallOptionsWidget");
    if (page !== null) {
        page.title = "卸载选项";
        page.subTitle = "选择是否保留事项、设置与备份";
    }
}

Controller.prototype.handleUninstallationFinished = function()
{
    if (todoitDataRemovalHandled
            || installer.value("ToDoIt.PreserveUserData") !== "false"
            || installer.value("ToDoIt.PurgeConfirmed") !== "true") {
        return;
    }
    todoitDataRemovalHandled = true;

    var targetDir = installer.value("TargetDir").replace(/\\/g, "/").replace(/\/+$/, "");
    if (targetDir === "" || targetDir.length < 4) {
        QMessageBox.critical(
            "todoit.invalidPurgePath",
            "用户数据未删除",
            "安装目录无效。为保护其他文件，安装器拒绝删除数据。",
            QMessageBox.Ok);
        return;
    }

    var dataDir = targetDir + "/data";
    var escapedDataDir = dataDir.replace(/'/g, "''");
    var command = "$ErrorActionPreference='Stop'; $p='" + escapedDataDir
            + "'; if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Recurse -Force }";
    var result = installer.execute(
        "powershell.exe",
        ["-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass",
         "-Command", command]);

    if (result.length < 2 || Number(result[1]) !== 0) {
        QMessageBox.critical(
            "todoit.purgeFailed",
            "用户数据删除失败",
            "应用程序已经卸载，但 data 目录未能完全删除。请在确认备份后手工处理：\n"
                + dataDir,
            QMessageBox.Ok);
    }
}
