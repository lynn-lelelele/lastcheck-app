# LastCheck · 出门别忘（App 版）

> 主动式出门提醒 App：离开任意场所（家 / 公司 / 酒店 / 健身房…），自动推送该场所的「携带清单」。
> 健忘的人不会主动打开 App，所以一切由系统主动触发——**比你自己更早知道你要出门了**。

Flutter 实现，Android 优先。同源的小程序版见 [lynn-lelelele/lastcheck](https://github.com/lynn-lelelele/lastcheck)。

## 功能

- **系统地理围栏**：每个常去地点注册为系统围栏（Android GeofencingClient / iOS CLCircularRegion），**App 被杀也会由系统唤醒触发**
- **本地通知**：离开围栏 → 查该地点未确认项 → 生成拟人化文案 → 弹系统通知（零服务器）
- **高德地图选点**：真实中国地图瓦片 + GCJ-02 坐标对齐，点哪落哪，自动反查地址
- **场所模板库**：家/公司/酒店/饭店/健身房一键套用，支持编辑物品；可建自定义清单
- **引导问卷**：3 问完成首次配置（常去哪 / 怕忘什么 / 是否开启自动提醒）
- **手动打卡降级**：不开定位也能用（"我出门了"）

## 技术栈

| 层 | 选型 |
|---|---|
| UI | Flutter 3.47 / Material 3，思源黑体（Source Han Sans SC） |
| 地图 | flutter_map + 高德在线瓦片（免 key），GCJ-02 转换在 `lib/core/gcj.dart` |
| 围栏 | native_geofence（系统级，支持被杀唤醒、开机重注册） |
| 通知 | flutter_local_notifications（Android 13+ 权限引导） |
| 定位 | geolocator |
| 存储 | shared_preferences（本地优先，暂不云同步） |

## 目录结构

```text
lib/
├── main.dart               # 入口 + 引导/主壳路由
├── theme.dart              # 颜色 / 主题 / 悬浮岛装饰系统
├── app_services.dart       # 服务容器 + ServicesScope + 全局事件
├── core/                   # 纯逻辑（gcj 坐标转换）
├── data/                   # presets（场景模板默认数据）
├── models/                 # Place 等数据模型
├── repositories/           # localRepo（存储抽象）
├── services/               # place/checklist/message/notification/geofence/geo
├── screens/                # guide/checklist/places/templates/settings/location_picker/main_shell
└── widgets/                # island_header / name_sheet / item_editor_sheet
```

## 本地构建

```bash
# 国内网络建议先配置镜像
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

flutter pub get
flutter build apk --release   # 产物在 build/app/outputs/flutter-apk/
```

> 注：Gradle 已配置阿里云 Maven + 腾讯云 Gradle 镜像（`android/settings.gradle.kts`、`gradle-wrapper.properties`）。
> release 当前关闭了 R8 混淆（内存原因），发布前需重开。

## 路线图

- [x] M1 原型：引导 / 场所 / 模板 / 清单 / 打卡
- [x] M1.5 分层架构：services / repositories / core
- [x] M2 自动触发：系统围栏 + 本地通知（真机验收中）
- [ ] M3 智能：天气联动、忘带统计、习惯学习、POI 识别
- [ ] M4 发布：签名、R8、上架

## License

[MIT](LICENSE)
