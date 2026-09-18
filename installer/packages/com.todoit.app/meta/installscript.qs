var welcomePageAdded = false;
var uninstallPageAdded = false;

function Component()
{
    component.addStopProcessForUpdateRequest("ToDoIt.exe");
    component.loaded.connect(this, Component.prototype.componentLoaded);
}

Component.prototype.componentLoaded = function()
{
    if (installer.isInstaller()) {
        installer.setDefaultPageVisible(QInstaller.Introduction, false);
        installer.setDefaultPageVisible(QInstaller.ComponentSelection, false);
        if (systemInfo.productType === "windows")
            installer.setDefaultPageVisible(QInstaller.StartMenuSelection, false);

        welcomePageAdded = installer.addWizardPage(
            component, "WelcomeWidget", QInstaller.Introduction);
        if (!welcomePageAdded)
            installer.setDefaultPageVisible(QInstaller.Introduction, true);
    }

    var introduction = gui.pageById(QInstaller.Introduction);
    if (introduction !== null) {
        introduction.packageManagerCoreTypeChanged.connect(
            this, Component.prototype.maintenanceModeChanged);
    }
    this.syncUninstallOptionsPage();
}

Component.prototype.maintenanceModeChanged = function()
{
    this.syncUninstallOptionsPage();
}

Component.prototype.syncUninstallOptionsPage = function()
{
    if (installer.isUninstaller() && !uninstallPageAdded) {
        uninstallPageAdded = installer.addWizardPage(
            component, "UninstallOptionsWidget", QInstaller.ReadyForInstallation);
        if (uninstallPageAdded) {
            var widget = gui.pageWidgetByObjectName("DynamicUninstallOptionsWidget");
            if (widget !== null) {
                var keepRadio = gui.findChild(widget, "KeepDataRadio");
                var deleteRadio = gui.findChild(widget, "DeleteDataRadio");
                if (keepRadio !== null) {
                    keepRadio.toggled.connect(
                        this, Component.prototype.keepDataToggled);
                    keepRadio.checked = true;
                }
                if (deleteRadio !== null) {
                    deleteRadio.toggled.connect(
                        this, Component.prototype.deleteDataToggled);
                }
                widget.complete = true;
            }
            installer.setValue("ToDoIt.PreserveUserData", "true");
            installer.setValue("ToDoIt.PurgeConfirmed", "false");
        }
    } else if (!installer.isUninstaller() && uninstallPageAdded) {
        installer.removeWizardPage(component, "UninstallOptionsWidget");
        uninstallPageAdded = false;
        installer.setValue("ToDoIt.PreserveUserData", "true");
        installer.setValue("ToDoIt.PurgeConfirmed", "false");
    }
}

Component.prototype.keepDataToggled = function(checked)
{
    if (!checked)
        return;
    installer.setValue("ToDoIt.PreserveUserData", "true");
    installer.setValue("ToDoIt.PurgeConfirmed", "false");
}

Component.prototype.deleteDataToggled = function(checked)
{
    if (!checked)
        return;
    installer.setValue("ToDoIt.PreserveUserData", "false");
    installer.setValue("ToDoIt.PurgeConfirmed", "false");
}

Component.prototype.createOperations = function()
{
    component.createOperations();

    if (!(component.installationRequested() || component.updateRequested()))
        return;

    component.addOperation(
        "CreateShortcut",
        "@TargetDir@/ToDoIt.exe",
        "@StartMenuDir@/To Do It.lnk"
    );
    component.addOperation(
        "CreateShortcut",
        "@TargetDir@/ToDoItMaintenanceTool.exe",
        "@StartMenuDir@/To Do It 维护工具.lnk"
    );

    // Keep migration as the final install/update operation. If it fails, IFW
    // rolls back package operations while the migrator restores its own CSV
    // backup and records the failure without logging private event content.
    var mode = component.updateRequested() ? "update" : "install";
    component.addOperation(
        "Execute",
        "@TargetDir@/ToDoItMigrator.exe",
        "--data-dir", "@TargetDir@/data",
        "--manifest", "@TargetDir@/release-manifest.json",
        "--mode", mode,
        "workingdirectory=@TargetDir@",
        "errormessage=用户数据校验或迁移失败。安装已中止；请保留 data 目录并查看 data/logs/update-history.jsonl。"
    );
}
