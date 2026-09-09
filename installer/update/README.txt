To Do It offline update
=======================

1. Close To Do It.
2. Open PowerShell in this extracted folder.
3. For the default install location, run:

   .\apply-update.ps1

4. For a custom install location, run:

   .\apply-update.ps1 -InstallDir "D:\Your\ToDoIt"

The script gives the installed Qt maintenance tool this folder's local
repository for this run only. It never contacts the network. The component
update invokes ToDoItMigrator before completion; event.csv is backed up and
validated, and an unsupported schema blocks the update without overwriting it.
