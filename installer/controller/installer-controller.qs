function Controller()
{
    // Use a per-user writable default. The target page remains visible so the
    // user may choose another directory; event.csv will live below that target.
    var localAppData = installer.environmentVariable("LOCALAPPDATA");
    if (localAppData !== "") {
        installer.setValue("TargetDir",
                           localAppData.replace(/\\/g, "/") + "/Programs/ToDoIt");
    }
}
