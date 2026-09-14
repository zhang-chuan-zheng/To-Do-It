# Effects

放置圆角遮罩、轻量材质和与 Windows 原生磨砂层配合的 QML 内容效果。`GlassSurface.qml` 统一绘制石墨主题的透明 tint 与细描边；`PopupGlassBackground.qml` 只在下拉框、调色盘、附件选择器和打赏弹层等高层浮层中截取并模糊 `MainPage`，避免底层文字穿透影响阅读。应用内效果不替代 Windows 桌面 Acrylic/DWM，也不在每个事项字段中执行实时高斯模糊。
