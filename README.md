# Mihomote

Material 3 Expressive 风格的跨平台 **Mihomo 远程控制面板**，基于 Flutter，支持 Android、iOS、macOS、Windows、Linux 和 Web（WASM）。

Mihomote 通过 Mihomo 的 external-controller（RESTful API + WebSocket）连接已经在运行的内核，可以保存多个后端（本机、路由器、服务器）并一键切换。

## 功能

- **概览**：实时速率曲线、累计流量、内存、连接数、代理模式切换、常用操作（清空 DNS / Fake-IP 缓存、重载配置、更新 GEO）
- **代理**：策略组卡片、节点选择、组测速和单节点测速
- **连接**：实时连接列表，可搜索、查看详情、断开
- **规则**：规则列表、规则集更新
- **日志**：实时日志，可按等级筛选、暂停、搜索
- **设置**：后端管理、主题（动态取色 / 种子色 / 深浅色）、语言、内核选项

## 开发

```bash
flutter pub get
flutter run -d macos          # Debug 构建的欢迎页可以选择「Mock 数据」，不需要真实内核
flutter test
flutter build web --wasm
```

开发约定、架构说明和当前进度见 [AGENTS.md](AGENTS.md)。
