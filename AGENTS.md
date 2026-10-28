# AGENTS.md — Mihomote

> [!IMPORTANT]
> **本文件必须始终与项目的真实状态保持同步。**
> 任何改变了架构、目录结构、依赖、约定、命令或进度的改动，都必须在**同一个 commit** 里更新本文件的对应章节（尤其是「2. 当前进度」）。
> 开始任何任务前先读一遍本文件；结束任务前检查本文件是否仍然准确。发现本文件与代码不一致时，以代码为准并立即修正本文件。

---

## 1. 项目概述

**Mihomote**（Mihomo + Remote）是一个使用 Flutter 构建的跨平台 **Mihomo 远程控制面板**，设计语言为 **Material 3 Expressive（M3E）**。

- **定位：纯远程面板。** 通过 Mihomo 的 external-controller（RESTful API + WebSocket）连接一个已经在运行的内核（本机 / 路由器 / 服务器）。**不内置、不托管、不启动内核**。架构上为将来可能的「本地内核」模块留出空间（API 层与后端配置解耦），但目前不做。
- **多后端：** 可保存多个后端（URL + secret），一键切换；切换后所有依赖当前后端的数据自动重建。
- **平台：** Android、iOS、macOS、Windows、Linux、Web。**移动端与桌面端体验同等重要**；Web 端以 **WASM**（`flutter build web --wasm`）为目标。
- **语言：** 简体中文 + English（gen-l10n）。

---

## 2. 当前进度

> 每次提交都要更新这一节。完成项打勾并写清楚落在哪里，新发现的问题写进「已知问题 / 技术债」。

最后更新：2026-10-29

### 已完成
- [x] Flutter 项目脚手架（6 个平台）、依赖选型（第 3 节）、各平台网络权限配置（§3.4）
- [x] AGENTS.md / CLAUDE.md
- [x] **M0 基础设施**
  - 主题：`lib/app/app.dart`，由 `MaterialApp.router` 加 `M3ETheme` 组成；动态取色加种子色兜底；主题模式支持跟随系统、浅色、深色
  - 路由与自适应导航：`lib/app/router.dart`、`lib/app/shell/`
    - 导航形态：底栏 / 收起的 Rail / 展开的 Rail
    - 窄屏下设置页全屏显示，带返回按钮
    - Android 返回键：非概览页先回到概览，概览页再退出
  - 中英文案：`lib/l10n/`
  - API 层：`lib/core/mihomo/`，包括 `MihomoApi` 接口、`MihomoClient`、`MockMihomoApi` 和各模型
  - 后端管理：`lib/core/backends/`、`lib/features/backends/`
    - 欢迎页
    - 添加 / 编辑 / 删除 / 切换后端
    - 连接测试
  - 测试：
    - 模型解析、地址规范化、策略组排序
    - 架构规则测试 `test/architecture_test.dart`：自动拦截 §3.1 / §3.3 禁止的 import，并检查 `core/mihomo` 不依赖 UI 层
    - 页面冒烟测试 `test/app/pages_smoke_test.dart`：用 mock 后端，在窄屏（402×874）和宽屏（1280×820）下渲染所有页面，有任何异常即失败
- [x] **M1 核心页面**
  - 概览：实时速率曲线、累计流量、内存、连接数、模式切换按钮组、快捷操作
  - 代理：
    - 策略组卡片（按组类型使用不同的 MaterialShape），折叠时显示每个成员的延迟色点
    - 节点网格，点击即选择
    - 组测速；单节点测速通过长按或右键触发
- [x] **M2 基础版**
  - 连接：实时列表、搜索、单连接速率、详情（自适应 bottom sheet / side sheet）、断开 / 全部断开、暂停
  - 规则：规则列表加搜索；规则集列表，可更新
  - 日志：实时流、等级筛选、暂停、清空、搜索
- [x] **M3 部分**：设置页
  - 后端管理
  - 主题模式、动态取色、种子色、语言
  - allow-lan、IPv6、日志等级（菜单形式）
  - 关于
- [x] **验证**（mock 数据）：
  - Web（Debug，DDC）：窄屏和宽屏
  - iOS 26.3 模拟器（Aonsoku Dev）：主要页面、设置、深色模式、后端菜单
  - 编译通过：`flutter build macos --debug`、`flutter build web --wasm`
  - `flutter test`：36 个测试全部通过

### 进行中 / 下一步
- [ ] 连接真实的 Mihomo 内核联调（目前只用 mock 数据验证过）
- [ ] 在 Android、Windows、Linux、macOS 上实际运行检查（目前实际运行过的只有 iOS 模拟器和 Web；macOS 只验证了编译）
- [ ] iOS 上 emoji 显示为方块（见已知问题）
- [ ] 连接页：排序选项
- [ ] 规则启停（`PATCH /rules/disable`）
- [ ] 代理集（Provider）管理页面
- [ ] 内核操作：重启、升级
- [ ] M4 打磨：宽屏列表-详情双栏、键盘快捷键、右键菜单

### 路线图
- **M4 打磨：** 代理集（Provider）管理、键盘快捷键、右键菜单、列表-详情双栏、动效细节、无障碍、Web 作为 `external-ui` 部署时自动识别同源后端
- **M5 发布：** 图标与启动屏、各平台打包、CI（analyze / test / `build web --wasm`）

### 已知问题 / 技术债
- secret 以明文存在 SharedPreferences 里（Web 上就是 localStorage）。之后评估 `flutter_secure_storage`，需要注意 macOS 钥匙串 entitlement 以及 Web/WASM 的兼容性。
- `M3EMaterialApp` 不支持 Router，`lib/app/app.dart` 里复刻了它的行为（§3.2）。升级 `material_3_expressive` 时要对照检查。
- `M3EResolvedTheme` 读取父级 Theme 时没有建立依赖，主题过渡动画期间不会重建，结果会出现深色卡片配浅色背景的情况。因此 `themeAnimationDuration` 设为 0，主题即时切换。上游修复后可以恢复过渡动画。
- `M3EAppBar` 的 `actions` 是在**宽度不受限**的 Row 中布局的。放进 actions 的组件不能用 `Expanded`，也不能依赖 `maxWidth`（`BackendSwitcher` 已经处理了这种情况）。
- iOS 26.3 模拟器上，Flutter 的系统字体回落失效，中文和 emoji 都显示成方块。
  - 中文：已在 `lib/app/theme/fonts.dart` 显式指定 `fontFamilyFallback`（苹方等）解决。
  - emoji：按名称指定 `Apple Color Emoji` 也无效，目前仍显示方块。待真机确认，或升级 Flutter 后复测。
  - Web 不受影响。
- M3E 组件的布局约束（违反时会触发布局断言，导致整页空白；新增页面要靠冒烟测试兜底）：
  - 外层不能用 `IntrinsicHeight` 包住 `M3EButtonGroup` 等内部使用 `LayoutBuilder` 的组件。
  - `M3ESegmentedButton` 必须拿到有界宽度，不能放进横向滚动视图。
- Riverpod：Notifier 的 `build()` 里调用 `ref.listen(..., fireImmediately: true)` 时，回调不能读 `state`，因为此时 build 还没返回。需要初始值时，在 build 里用 `ref.read` 计算出来再返回。
- `flutter run -d web-server --wasm` 在 Debug 模式下加载不了（请求 `main.dart.mjs` 时返回 404）。处理方式：
  - 调试 WASM：用 `flutter run -d chrome --wasm`
  - 预览：用非 wasm 的 web-server
  - 验证 WASM：用 `flutter build web --wasm`

---

## 3. 技术栈与关键决策

| 领域 | 选择 | 备注 |
|---|---|---|
| Flutter / Dart | Flutter 3.47.x stable / Dart 3.13 | `environment.sdk: ^3.13.5` |
| Material 库 | [`material_ui`](https://pub.dev/packages/material_ui)（官方拆分出的 Material 包） | **禁止** `package:flutter/material.dart`，见 3.1 |
| M3E 组件 | [`material_3_expressive`](https://pub.dev/packages/material_3_expressive) | 社区包，见 3.2 |
| 形状 / 动效 | `material_new_shapes`（MaterialShapes / 形变）、`motor`（弹簧物理） | M3E 包也依赖这两个 |
| 动态取色 | `dynamic_color` | 由 `M3ETheme(dynamicColoring: true)` 使用 |
| 状态管理 | `flutter_riverpod` 3.x | **不使用代码生成** |
| 路由 | `go_router` 18.x | `StatefulShellRoute.indexedStack` |
| HTTP | `dio` | REST |
| WebSocket | `web_socket_channel` | traffic / memory / logs / connections |
| 本地存储 | `shared_preferences`（`SharedPreferencesWithCache`） | 后端配置、应用设置 |
| 国际化 | `flutter_localizations` + gen-l10n + `intl` | 生成代码提交到 `lib/l10n/gen/` |
| 图标 | Material Icons（`uses-material-design`）+ `cupertino_icons` | 后者被依赖间接引用，缺了会导致图标缺失 |
| 测试 | `flutter_test`、`shared_preferences_platform_interface`（dev） | 冒烟测试中使用内存版 SharedPreferences |

新增依赖前必须确认：① 支持全部 6 个平台；② **兼容 WASM**（pub.dev 上有 “WASM ready” 标记，或已确认不依赖 `dart:html` / `dart:io`）；③ 不和 `material_ui` 冲突（不能间接要求 app 使用 `flutter/material.dart` 的类型）。加完依赖后同步更新上表。

### 3.1 Material 库：`material_ui`（硬性规则）
- Flutter 官方已将 Material 库从框架拆分为独立包 `material_ui`，M3 Expressive 只在这个包里继续开发。它和 `package:flutter/material.dart` 是**两套不同的类型**（`ThemeData`、`MaterialLocalizations` 等），混用会导致主题和本地化查找失败。
- 统一使用 `import 'package:material_ui/material_ui.dart';`（它已经 re-export 了 `package:flutter/widgets.dart`）。
- **禁止** `import 'package:flutter/material.dart'` 和 `import 'package:flutter/cupertino.dart'`（如确实需要 Cupertino，用 `cupertino_ui`）。
- `package:flutter/foundation.dart`、`services.dart`、`scheduler.dart`、`gestures.dart`、`rendering.dart`、`widgets.dart` 等非 Material 的框架库可以正常使用。
- 本地化 delegates 使用 **material_ui** 提供的 `GlobalMaterialLocalizations.delegates`，再加上 `AppLocalizations.delegate`。**不要**使用 gen-l10n 生成的 `AppLocalizations.localizationsDelegates`，因为它里面是框架版的 Material delegate。
- 同时 import `material_ui` 和 `material_new_shapes` 时会有命名冲突：`import 'package:material_ui/material_ui.dart' hide CornerRounding, RoundedPolygon;`

### 3.2 M3 Expressive 组件：`material_3_expressive`
- 有对应的 `M3E*` 组件时优先使用：`M3ENavigationBar`、`M3ENavigationRail`、`M3EAppBar`、`M3EButton`、`M3EIconButton`、`M3EButtonGroup`、`M3ESegmentedButton`、`M3ESplitButton`、`M3EFab` / `M3EExtendedFab` / `M3EFabMenu`、`M3EToolbar`、`M3ECard`、`M3EListItem` / `M3EList`、`M3EChip`、`M3ETextField`、`M3ESwitch`、`M3ESlider`、`M3ELoadingIndicator`、`M3EProgressIndicator`、`M3EDialog`、`M3EBottomSheet`、`M3ESideSheet`、`M3ESnackbar`、`M3ETooltip`、`M3ESearchBar` 等。
- 读取 M3E token（颜色、字体、形状、间距、动效）用 `M3ETheme.of(context)`；`Theme.of(context)` 也能拿到投影过来的 `ColorScheme` 和 `TextTheme`。
- **`M3EMaterialApp` 不支持 Router。** 本项目在 `lib/app/app.dart` 中用 `MaterialApp.router` 加 `M3ETheme`（adaptive scope）复刻了它的行为。不要改回 `M3EMaterialApp`；升级 M3E 包时要对照它的实现检查是否需要同步。
- 风险：这是单人维护的社区包。官方 `material_ui` 补齐某个 M3E 组件后（可跟踪 [flutter#168813](https://github.com/flutter/flutter/issues/168813)），优先迁回官方实现。遇到组件 bug 时，先在 `lib/shared/widgets/` 里做局部封装或绕过，不要直接 fork。

### 3.3 Web / WASM
- 目标构建：`flutter build web --wasm`，每个涉及依赖或平台代码的改动都要验证它能编译通过。
- 共享代码里**禁止** import `dart:io`、`dart:html`、`dart:js`、`dart:js_util`。平台判断用 `kIsWeb` / `defaultTargetPlatform`；确实需要平台专属实现时用条件导入（`if (dart.library.js_interop) ... if (dart.library.io) ...`）。
- 浏览器限制：
  - **CORS**：Mihomo 默认 `external-controller-cors.allow-origins: ['*']`；用户若改过配置，需要把面板的 origin 加进去。
  - **混合内容**：HTTPS 页面无法访问 `http://` 控制器。
  - **Private Network Access**：公网页面访问内网地址需要 Mihomo 的 `allow-private-network: true`（默认开启）。
  - **WebSocket 无法设置 Header**：所有平台统一用 `?token=<secret>` 鉴权。
- 部署：Web 构建产物可以直接作为 Mihomo 的 `external-ui`（同源访问，没有 CORS 和混合内容问题）。

### 3.4 平台配置（已在原生工程中设置，改动时注意保留）
- **macOS**：`DebugProfile.entitlements` 和 `Release.entitlements` 都要有 `com.apple.security.network.client`（沙盒下访问网络必需）。
- **Android**：主 `AndroidManifest.xml` 声明 `INTERNET` 权限，并设置 `android:usesCleartextTraffic="true"`（控制器通常是局域网里的明文 HTTP）。
- **iOS**：`Info.plist` 里配置 `NSAppTransportSecurity > NSAllowsArbitraryLoads`（明文 HTTP）和 `NSLocalNetworkUsageDescription`（访问局域网设备）。

---

## 4. 目录结构

```
lib/
├── main.dart                 # 入口：初始化 SharedPreferences，挂载 ProviderScope
├── app/                      # 应用级装配
│   ├── app.dart              # MaterialApp.router + M3ETheme（替代 M3EMaterialApp）
│   ├── router.dart           # go_router 配置、路由路径常量、ShellBranch 索引
│   ├── shell/                # adaptive_shell（底栏 / Rail）、page_scaffold（页面骨架 + M3E 折叠大标题栏）、
│   │                         # backend_switcher（后端切换器）、shell_scope（页面获取 shell 信息）
│   └── theme/                # 种子色预设与动态取色支持判断、语义色（延迟好/中/差、上下行）
├── core/                     # 与具体页面无关的基础能力
│   ├── mihomo/               # Mihomo API 层：MihomoApi 接口、REST/WebSocket 实现、模型、异常（不依赖 Flutter UI）
│   │   └── mock/             # MockMihomoApi：开发用 mock 数据与模拟实时流
│   ├── backends/             # 后端配置模型、持久化、当前后端与 MihomoClient 的 provider
│   ├── settings/             # 应用设置（主题模式、动态取色、种子色、语言）
│   ├── state/                # 跨页面共享的 provider：版本、运行配置（乐观更新）、traffic / memory / connections 流
│   └── storage/              # SharedPreferences provider
├── features/                 # 按功能划分：每个功能目录下有 *_page.dart、*_providers.dart、widgets/
│   ├── overview/             # 概览
│   ├── proxies/              # 代理
│   ├── connections/          # 连接
│   ├── rules/                # 规则
│   ├── logs/                 # 日志
│   ├── settings/             # 设置
│   └── backends/             # 欢迎页、后端添加/编辑/切换 UI
├── shared/                   # 跨功能复用
│   ├── l10n.dart             # context.l10n 扩展
│   ├── layout/               # WindowSizeClass 断点、pageGutter（内容最大宽度与两侧留白）
│   ├── utils/                # 格式化（字节、速率、时长）等
│   └── widgets/              # 状态视图（加载 / 空 / 错误 + describeError）、搜索框
└── l10n/                     # app_en.arb（模板）、app_zh.arb；gen/ 为生成代码（勿手改）
test/                         # 单元测试 / widget 测试（目录结构与 lib/ 对应）
```

---

## 5. 架构约定

### 5.1 分层与依赖方向
`features/*` → `core/*` → `core/mihomo`（纯 API）。`app/` 负责把它们装配起来。
- `core/mihomo` 只依赖 `dio`、`web_socket_channel` 和 Dart / foundation，**不依赖 Riverpod 和任何 Widget**，方便测试和复用。
- `features` 之间不要互相 import 页面内部实现；需要共享的东西下沉到 `core/` 或 `shared/`。

### 5.2 状态管理（Riverpod 3，无代码生成）
- 使用 `Provider`、`NotifierProvider`、`AsyncNotifierProvider`、`StreamProvider` 等手写 provider，provider 定义在对应目录的 `*_providers.dart` 里。
- **当前后端**：`activeBackendProvider` 决定 `mihomoClientProvider`。所有依赖后端数据的 provider 都必须 `ref.watch(mihomoClientProvider)`，这样切换后端时会自动重建、自动断开旧的 WebSocket。
- 不要在 Widget 里直接创建 `MihomoClient`、`Dio` 或 `WebSocketChannel`。
- 实时流（traffic / memory / logs / connections）由 provider 持有。页面放在 `StatefulShellRoute.indexedStack` 里，切换 tab 时页面不会销毁，所以流也会保持连接（概览图因此能连续）。离开时需要释放资源的流使用 `autoDispose`。
- 用户操作（选择节点、切换模式等）走 Notifier 方法，并在本地做乐观更新，失败时回滚并提示。

### 5.3 路由
- `go_router` 使用 `StatefulShellRoute.indexedStack`，分支顺序为：概览、代理、连接、规则、日志、设置（索引 0–5）。
- 窄屏下设置不在底栏里，而是通过顶栏齿轮按钮进入；这时隐藏底栏并显示返回按钮，返回到上一个主页面。宽屏下设置是侧边栏的第 6 项。
- 还没有任何后端时，重定向到欢迎页 `/welcome`。
- 路由路径统一定义在 `lib/app/router.dart` 的常量里，不要在别处手写字符串。

### 5.4 Mihomo API 层
- `MihomoApi` 是抽象接口，有两个实现：`MihomoClient`（真实实现，封装全部 REST 端点和 WebSocket 流，鉴权方式见第 7 节）和 `MockMihomoApi`（见 5.5）。UI 和 provider 只依赖 `MihomoApi`。
- 错误统一转换为 `MihomoException`（带 `kind`：network / unauthorized / notFound / server / timeout / unknown），UI 根据 `kind` 显示本地化文案。
- 模型手写为不可变类加 `fromJson`。对缺失字段要宽容，因为不同 Mihomo 版本返回的字段有差异；未知枚举值落到 `unknown`，不能抛异常。
- 新增或修改端点时，要同时更新 `MihomoApi` 接口、两个实现以及 `test/` 里的解析测试。

### 5.5 开发数据（mock data）
- 开发和测试都用**应用内的 mock 数据**：`lib/core/mihomo/mock/` 里的 `MockMihomoApi` 提供示例的策略组、节点、规则、连接，并模拟实时流（流量、内存、日志、连接），对选择节点、切换模式等操作也会在内存中生效。
- Debug 构建里，欢迎页和后端列表会提供「Mock 数据」后端（`BackendProfile.isMock`），Release 构建中不显示。
- **不要**搭建模拟服务器或其他额外的开发服务；需要新的场景时，扩充 mock 数据即可。
- mock 数据的 JSON 形状要和真实 Mihomo 响应一致（走同一套 `fromJson`），这样它也能作为解析测试的 fixture。

---

## 6. UI / UX 规范（M3 Expressive）

### 6.1 自适应布局（移动端与桌面端同等重要）
| 窗口宽度 | 导航 | 内容布局 |
|---|---|---|
| < 600（compact） | 底部 `M3ENavigationBar`（概览 / 代理 / 连接 / 规则 / 日志）；顶栏放后端切换器和设置按钮 | 单栏；详情用 bottom sheet |
| 600–839（medium） | `M3ENavigationRail` 收起态（菜单按钮展开为 modal） | 单栏或网格 |
| ≥ 840（expanded） | `M3ENavigationRail` 展开态（可收起） | 列表-详情双栏；详情用 side sheet |

- 断点只在 `lib/shared/layout/` 里定义，其他地方通过 `WindowSizeClass` 判断，**不要**到处写死 `MediaQuery.width > 600`。
- 布局按「可用宽度」决定，而不是按平台决定：手机横屏、平板、桌面窄窗口、浏览器都要能用。

### 6.2 输入方式适配
- **触屏**：点击目标不小于 48dp；次要操作放进长按菜单或 bottom sheet；列表支持下拉刷新。
- **鼠标 / 键盘（桌面与 Web）**：要有 hover 状态和 tooltip；右键菜单与长按菜单提供同一组操作；可见滚动条；关键信息（IP、域名、规则）可以选中复制；键盘可以完成全部操作（焦点顺序、快捷键：`Ctrl/Cmd+1…6` 切换页面，`Ctrl/Cmd+F` 或 `/` 搜索，`Ctrl/Cmd+R` 刷新——计划中）。

### 6.3 颜色
- 默认开启动态取色：Android 12+ 跟随壁纸，macOS / Windows 跟随系统强调色，其余平台用种子色兜底。设置里可以关闭动态取色并选择种子色预设（`lib/app/theme/`）。
- **禁止硬编码颜色**，一律用 `ColorScheme` 的角色色（`primary`、`secondaryContainer`、`surfaceContainerHigh`……）。语义色（延迟好 / 中 / 差、上行 / 下行）通过 `lib/app/theme/` 里的 helper 获取，并 harmonize 到当前主色。

### 6.4 形状、动效与反馈
- 多用 M3E 的大圆角和 MaterialShapes（cookie、clover、sunny、pill 等）表达层级和个性，例如策略组图标、延迟徽章、空状态插图；按压形变交给 M3E 组件处理。
- 动画优先用**弹簧**（`motor` 的 `MaterialSpringMotion.*`，或 M3E 组件自带的动效）。只有颜色、透明度这类非空间属性的过渡可以用 duration + curve。
- 等待时间不确定时用 `M3ELoadingIndicator`（会变形的指示器）；能量化进度时用 `M3EProgressIndicator`（可选 wavy 样式）。
- 实时数字（速率、延迟、流量）使用等宽数字 `FontFeature.tabularFigures()`，避免数字变化时跳动。

### 6.5 文案与国际化
- 所有用户可见文本都必须走 l10n：在 `lib/l10n/app_en.arb`（模板，带 `@key` 描述）和 `app_zh.arb` 中**同时**添加，然后运行 `flutter gen-l10n`。在代码里通过 `context.l10n.xxx` 获取。
- 文案风格：中文简洁口语化，不用「您」；英文用 Sentence case。
- 技术名词（Selector、URLTest、DIRECT、GEOIP 等）和代理 / 规则名称原样展示，不翻译。

### 6.6 无障碍
- 只有图标的按钮必须有 `tooltip` 或 `semanticLabel`；颜色不能是唯一的信息载体（延迟同时显示数字）；支持系统字体缩放，布局不能因此溢出。

---

## 7. Mihomo API 备忘

- **鉴权**：REST 使用 `Authorization: Bearer <secret>`；WebSocket 使用查询参数 `?token=<secret>`。
- **主要端点**（详见 [官方文档](https://wiki.metacubex.one/en/api/)）：

| 方法 | 路径 | 用途 |
|---|---|---|
| GET | `/version` | `{ "meta": true, "version": "v1.x" }`，用于连接测试 |
| GET / PATCH | `/configs` | 读取 / 局部修改配置（`{"mode":"rule"}` 等） |
| PUT | `/configs?force=true` | 重载配置（body：`{"path": ""}` 或 `{"payload": ""}`） |
| POST | `/configs/geo` · `/restart` · `/upgrade` · `/upgrade/ui` | 更新 GEO / 重启内核 / 升级内核 / 升级面板 |
| GET | `/proxies` · `/proxies/{name}` | 全部代理与策略组 |
| PUT / DELETE | `/proxies/{group}` | 选择节点 `{"name": "..."}` / 清除固定选择 |
| GET | `/proxies/{name}/delay?url=&timeout=` | 单节点测速，返回 `{"delay": 123}` |
| GET | `/group/{name}/delay?url=&timeout=` | 策略组测速，返回 `{节点名: 延迟}` |
| GET / PUT | `/providers/proxies[/{name}]` · `.../healthcheck` | 代理集 / 更新 / 健康检查 |
| GET / PUT | `/providers/rules[/{name}]` | 规则集 / 更新 |
| GET | `/rules` | 规则列表 |
| PATCH | `/rules/disable` | 启用 / 停用规则 `{"<index>": true}`（较新版本） |
| WS | `/connections?interval=1000` | 连接快照流；`DELETE /connections[/{id}]` 断开连接 |
| WS | `/traffic` | `{"up": B/s, "down": B/s, "upTotal"?, "downTotal"?}` |
| WS | `/memory` | `{"inuse": B, "oslimit": B}`，第一条可能是 0 |
| WS | `/logs?level=info` | `{"type": "info", "payload": "..."}` |
| GET | `/dns/query?name=&type=` | DNS 查询 |
| POST | `/cache/dns/flush` · `/cache/fakeip/flush` | 清空 DNS / Fake-IP 缓存 |

- **注意点**：
  - 策略组类型有 `Selector`、`URLTest`、`Fallback`、`LoadBalance`、`Relay`。只有 `Selector` 可以随意手动选择；较新版本允许固定 `URLTest` / `Fallback` 的选择，用 `DELETE` 取消固定。
  - `history` 里最后一项是最近一次测速结果，`delay == 0` 表示超时或失败。
  - 策略组的展示顺序以 `GLOBAL.all` 为准（也就是配置文件里的顺序）；`hidden: true` 的组默认不展示。
  - 默认测速 URL：`https://www.gstatic.com/generate_204`，超时 5000ms；组自带 `testUrl` 时优先使用它。

---

## 8. 常用命令

```bash
flutter pub get
flutter gen-l10n                      # 修改 ARB 后重新生成 lib/l10n/gen/
dart format lib test                  # 提交前格式化
flutter analyze                       # 必须 0 issue
flutter test                          # 必须全部通过
flutter run -d macos                  # 桌面调试（Debug 下可选「Mock 数据」后端）
flutter run -d chrome --wasm          # Web（WASM）调试
flutter run -d web-server --web-port=8686   # 浏览器预览（不支持 --wasm，见已知问题）；.claude/launch.json 中的 web-debug
flutter build web --wasm              # 验证 WASM 构建
flutter build ios --simulator --debug # 模拟器包（Debug 才有 Mock 数据入口），再 xcrun simctl install
```

---

## 9. 代码风格

- 遵循 `analysis_options.yaml`（`flutter_lints` + 额外规则），`dart format` 使用默认配置。
- 文件名 `snake_case.dart`；一个文件一个公开 Widget，私有小组件可以放在同一个文件里。
- 标识符和代码注释用英文；面向用户的文案走 l10n；文档（本文件、README）用中文。
- 优先 `const` 和 `final`；避免使用 `!`，除非能证明非空；不要吞掉异常（至少要 `debugPrint` 或向 UI 暴露错误）。
- 注释写「为什么」，不写「做了什么」；公共 API 写简短的 `///` 文档。
- **不要手改生成文件**（`lib/l10n/gen/`）。

---

## 10. 提交规范

- 格式：`<type>: <summary>`，例如 `feat: add proxy group list`、`fix: reconnect traffic stream after backend switch`。
- `type` 取值：`feat` · `fix` · `refactor` · `perf` · `style` · `docs` · `test` · `build` · `ci` · `chore` · `revert`。
- `summary` 用英文、小写开头、祈使语气、句末不加句号，不超过 72 个字符；需要时在正文里说明动机和取舍。
- 一个 commit 只做一件事。提交前 `flutter analyze` 必须 0 issue，`flutter test` 必须全部通过。
- **改动影响到本文件描述的内容时，必须在同一个 commit 里更新 AGENTS.md**（尤其是「当前进度」）。

---

## 11. Agent 工作守则

1. 开始前先读本文件，尤其是「当前进度」和硬性规则（3.1、3.3）。
2. 不确定的产品或设计决策先问用户，不要自行扩大范围（例如不要加入本地内核管理）。
3. 新增依赖前按第 3 节的清单检查兼容性，并在技术栈表里写明理由。
4. 验证要求：
   - 至少跑 `flutter analyze` 和 `flutter test`（其中包含窄屏 / 宽屏的页面冒烟测试；新增页面要加进 `test/app/pages_smoke_test.dart`）；
   - UI 改动要分别在窄屏（< 600）和宽屏（≥ 840）下检查；
   - 涉及依赖或平台代码的改动要跑 `flutter build web --wasm`；
   - iOS 模拟器上的点按、截图等交互检查，交给 Antigravity CLI 处理以节省 token：用 Gemini Flash 模型加 iosef MCP，复用已有的「Aonsoku Dev」模拟器。命令形如 `agy -p "<任务>" --model gemini-3.8-flash-medium --mode auto --sandbox`，要求它输出简短的文字报告，并把截图存成文件。
5. 完成后更新「当前进度」，按提交规范提交。
