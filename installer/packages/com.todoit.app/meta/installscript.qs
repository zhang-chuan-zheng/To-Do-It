function Component()
{
    component.addStopProcessForUpdateRequest("ToDoIt.exe");
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
    // can roll back the package operations while the migrator restores its
    // own event.csv backup.
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
