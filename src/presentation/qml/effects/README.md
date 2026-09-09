# Effects

放置圆角遮罩、动效以及与 Windows 原生磨砂层配合的 QML 内容效果。`GlassSurface.qml` 只绘制 tint、描边和高光，不捕获桌面，也不冒充 Acrylic/DWM 模糊；`PopupGlassBackground.qml` 只为应用内下拉弹层截取并模糊 `MainPage` 的对应区域，再叠加深色石墨遮罩，保证选项与下层内容清晰分离。应用内弹层模糊不替代 Windows 桌面 Acrylic/DWM。

