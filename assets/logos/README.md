# Logos

保存软件 Logo 与 Windows 应用图标资源约定。界面使用 `app.svg`，Windows EXE 和 Qt IFW 安装器使用多尺寸 `app.ico`；构建配置与打包脚本均先查找 `custom/` 中的同名文件，缺失时回退到 `default/`。
