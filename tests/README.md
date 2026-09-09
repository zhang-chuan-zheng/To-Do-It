# Tests

当前包含应用壳契约测试和更新协调器数据安全测试。更新测试使用临时目录覆盖 v1 备份/只读校验、拒绝无版本 CSV，以及首次安装不提前创建 `event.csv`。本批次只写入测试源码，尚未编译或执行。

当前只包含 `framework/AppShellControllerTest.cpp`，用于验证应用壳控制器的元数据和框架就绪契约。后续测试按 `domain`、`application`、`infrastructure`、`presentation` 与 `qml` 分目录扩展，并只使用合成数据。
