# Styles

Qt Quick 不使用网页 CSS/QSS 作为主要样式机制。本目录现有 `Theme`、`Metrics`、`Typography`、`Motion`、`IconCatalog` 五个单例，统一石墨主题颜色、圆角、字号、间距、拖拽/重排动画和资源 URL；业务组件不得复制这些常量。保留 `useVariant()` 作为未来主题扩展接口，但当前界面不加载液态玻璃效果，也不提供运行时主题切换控件。
