# AFG

AFG 是一个 macOS 应用，把常用的 Google 网页服务放进独立窗口，不依赖 Chrome。界面用 SwiftUI，网页用 WebKit，系统要求 macOS 15 或更高版本。

[English](README.md) | 简体中文

<div style="display: flex; gap: 16px; align-items: flex-start;">
  <img src="images/adf.png" style="width: 45%; height: auto;" />
  <img src="images/adf_settings.png" style="width: 45%; height: auto;" />
</div>

## 功能

### 启动台

- 31 个内置服务：YouTube、Gmail、Drive、Docs、Sheets、Slides、Calendar、Maps、Photos、Meet、Keep、Translate、News、Gemini 等
- 搜索、置顶、网格布局；右键可编辑或删除自定义服务
- 自定义 Web App：填写名称、网址和 SF Symbol，保存后自动抓取网站图标作为磁贴
- 右键「添加到启动台」会把启动器复制到 `/Applications`，Launchpad 会自动收录

### 服务窗口

- 每个服务一个窗口，登录状态由 WebKit 持久存储保存
- 每个窗口使用独立的 WebContent 进程池，一个页面崩溃不会拖死其他窗口
- 默认 Safari User-Agent，避免 Google 把嵌入式 WebView 判定为不安全浏览器；Docs、Sheets、Slides 自动切换为 Chrome UA，保证编辑器画布以 2x 渲染
- 工具栏：后退、前进、重新载入、主页、窗口置顶、打印、分享、下载、在浏览器中打开
- 载入进度、标题同步、窗口大小与位置记忆
- 鼠标滚轮滚动阻尼（0.5×，触控板和嵌套滚动区域不处理）

### 账号

- 多账号命名、默认账号、按服务指定账号（Google 的 `authuser` 和 `/u/N/`）
- 账号行尾菜单可退出登录；退出会在所有服务中同步退出，并把下一个账号设为默认

### 通知与角标

- 通知权限申请、按服务开关；前台也会显示横幅，点击通知打开对应服务
- 开启通知的服务会在后台保留一个隐藏页面，即使窗口没打开，收到新邮件也会通知。未读数来自页面标题；启动后的前 30 秒只更新角标，不会把已有未读再通知一遍
- 启动台磁贴显示未读数，Dock 图标显示未读总数；数字来自页面标题里的 `(N)`，阅读后减少，归零隐藏
- 打开服务时额外显示该服务的 Dock 图标（`AFGIconHost` 进程），关闭窗口后消失

### 脚本

- 官方脚本：通用广告隐藏、YouTube 去广告（隐藏广告位、跳过按钮、广告期间快进静音）
- 用户脚本：添加、编辑、启用、删除，支持导入 `.js` / JSON 和导出

### 其他

- English / 简体中文，默认 English；Google 页面会带上对应的 `hl` 参数
- 菜单栏图标、登录时启动、浅色/深色外观
- 网页下载保存到指定目录，下载窗口显示进度

## 系统要求

- macOS 15 或更高
- 当前构建为 Apple Silicon（arm64）
- 构建需要 Swift 6（Command Line Tools 即可，不需要完整 Xcode）

## 构建

```bash
make app    # 生成 build/AFG.app
make run    # 构建并打开
make dmg    # 生成 build/AFG-v0.1.0.dmg
```

版本号读取自 `Resources/Info.plist` 的 `CFBundleShortVersionString`，改完重新打包，DMG 文件名会自动跟着变；`CFBundleVersion` 是构建号。App 本身始终是 `AFG.app`。

`Makefile` 默认使用 `--disable-sandbox` 并把 SwiftPM 缓存放在 `.build/`，这是为了在受限环境里也能构建；普通终端直接 `swift build` 也可以。

## 打包

### 自己使用

`make app` 之后把 `build/AFG.app` 拖进 `/Applications` 即可。应用使用 ad-hoc 签名，在本机运行没有问题。

### DMG 内容

`make dmg` 会创建一个包含 `AFG.app` 和 `Applications` 快捷方式的磁盘映像，用户打开后把 App 拖进 Applications 即可。

## 数据位置

- 偏好设置：`~/Library/Preferences/dev.genwilliam.afg.plist`
- 图标、用户脚本、启动器：`~/Library/Application Support/AFG/`
- 下载：默认 `~/Downloads`，可在设置里修改

## 目录结构

| 文件                                        | 作用                                         |
| ------------------------------------------- | -------------------------------------------- |
| `Sources/AFG/AFGApp.swift`                  | App 入口、窗口生命周期、默认设置、URL Scheme |
| `Sources/AFG/Service.swift`                 | 服务模型与 31 个内置服务                     |
| `Sources/AFG/AppState.swift`                | 自定义服务、置顶、账号的持久化               |
| `Sources/AFG/LauncherView.swift`            | 启动台                                       |
| `Sources/AFG/ServiceEditor.swift`           | 添加/编辑 Web App                            |
| `Sources/AFG/WebWindowManager.swift`        | 服务窗口注册与复用                           |
| `Sources/AFG/WebWindowController.swift`     | 窗口、工具栏、加载、下载、打印、置顶         |
| `Sources/AFG/Downloads.swift`               | 下载记录与下载窗口                           |
| `Sources/AFG/OfficialScripts.swift`         | 内置广告拦截脚本                             |
| `Sources/AFG/UserScripts.swift`             | 用户脚本存储与编辑器                         |
| `Sources/AFG/ScriptSettingsSection.swift`   | 脚本设置页                                   |
| `Sources/AFG/AccountSettingsSection.swift`  | 账号设置页                                   |
| `Sources/AFG/AccountLogoutController.swift` | 退出指定 Google 账号                         |
| `Sources/AFG/NotificationManager.swift`     | 通知权限与未读数通知                         |
| `Sources/AFG/NotificationMonitor.swift`     | 通知用的后台页面监控                         |
| `Sources/AFG/UnreadStore.swift`             | 未读数与 Dock 角标                           |
| `Sources/AFG/SettingsView.swift`            | 设置窗口                                     |
| `Sources/AFG/StatusBarController.swift`     | 菜单栏                                       |
| `Sources/AFG/LoginItem.swift`               | 登录时启动                                   |
| `Sources/AFG/Localization.swift`            | 中英文文案                                   |
| `Sources/AFG/Prefs.swift`                   | 偏好键与默认值                               |
| `Sources/AFG/ServiceDockIcon.swift`         | 服务 Dock 图标宿主                           |
| `Sources/AFG/ServiceIconRenderer.swift`     | 按磁贴风格生成图标                           |
| `Sources/AFG/DockLauncher.swift`            | 拖到 Dock 的启动器                           |
| `Sources/AFG/LaunchpadInstaller.swift`      | 添加到启动台                                 |
| `Sources/AFG/ScrollDamping.swift`           | 滚动阻尼脚本                                 |
| `Sources/AFGIconHost/main.swift`            | 图标宿主进程                                 |
