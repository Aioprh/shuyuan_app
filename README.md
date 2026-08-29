# 书源仓库(Android)

一个安卓端书源浏览工具。数据来自 <https://www.yckceo.com/yuedu/shuyuan/index.html> 书源分享站,支持**书源浏览、搜索过滤、一键复制 / 分享书源 JSON**,数据在运行时实时在线拉取。

## 功能

复刻 www.yckceo.com 书源分享站,App 内搞定浏览、导入与发布:

- **书源**:书源列表瀑布流,向下滑动自动加载下一页;顶部搜索框按标题/作者/标签模糊过滤
- **书源合集 / 订阅源合集**:组合书源、组合订阅源浏览(「合集」Tab 内切换)
- **订阅源**:RSS 订阅源浏览(「订阅源」Tab)
- **详情页**:展示完整 JSON,一键复制、分享,内置导入「阅读」App 指引
- **批量导出**:书源列表可多选「批量导出」,一次复制多条书源 JSON
- **新建 / 发布**:提交书源 / 订阅源 JSON(需登录站点帐号)
- **我的**:Gitee 登录入口、地址发布页(防丢)、主题相关、规则教程、关于

底部导航:书源 · 合集 · 订阅源 · 新建 · 我的(数据运行时实时在线拉取)

## 技术栈

- Flutter(本项目用 Flutter 3.47.2 构建)
- 依赖:`http`(网络)、`html`(列表页解析)、`share_plus`(系统分享)
- 数据接口:
  - 列表页: `/yuedu/shuyuan/index.html?page=N`(解析 `div.ylist` 卡片)
  - 单条书源: `/yuedu/shuyuan/json/id/{id}.json`(标准书源数组 JSON)

## 环境准备

1. 安装 Flutter SDK(建议稳定版),加入 PATH
2. 安装 Android SDK 与 JDK 17
3. 执行 `flutter doctor` 确认 Android toolchain 就绪

## 构建

```bash
flutter pub get
flutter run          # 调试运行(需连接/启用模拟器或真机)
flutter build apk --release   # 构建发布 APK
```

产物路径:`build/app/outputs/flutter-apk/app-release.apk`

## 应用图标

- 源图:`assets/icon/ic_launcher.png`(1024×1024 满幅方图)
- 已按各密度生成 `mipmap-*` 下的 `ic_launcher.png`、`ic_launcher_foreground.png`,并配置自适应图标 `mipmap-anydpi-v26/ic_launcher.xml`
- 背景色:`values/colors.xml` 中 `ic_launcher_background`
- 重新生成:用 `flutter_launcher_icons` 指向 `assets/icon/ic_launcher.png`,或直接用 PIL 缩放到各密度即可

## 项目结构

```
lib/
  main.dart                   # 应用入口 + 底部导航主框架
  models/source_item.dart     # 通用条目模型(书源/合集/订阅源)
  services/api_service.dart   # 抓取 / 详情 / 批量导出 / 发布
  pages/source_list_page.dart # 通用列表页(搜索/滚动/多选导出)
  pages/detail_page.dart      # 详情(JSON 展示 + 复制 + 分享)
  pages/collections_page.dart # 合集(书源合集/订阅源合集)
  pages/rss_page.dart         # 订阅源
  pages/publish_page.dart     # 新建 / 发布
  pages/profile_page.dart     # 我的(登录/工具/关于)
test/
  widget_test.dart            # 冒烟测试
```

## 说明与已知点

- 打包默认通过修改模板 AGP 版本为 `8.11.1`,以兼容当前 Flutter 的 Gradle 插件(见 `android/settings.gradle.kts`)
- `gradle-wrapper.properties` 的发行版地址指向腾讯镜像,如需更换改回 `services.gradle.org` 即可
- 上线分发前建议:替换正式签名、更换 `applicationId`、设计图标与启动页