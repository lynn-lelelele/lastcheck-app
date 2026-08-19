/// 场景预设：添加常去地点时按类型自动生成常用物品。
/// 对应小程序版 data/presets.js，社区可通过 PR 扩充。
class ScenePreset {
  final String key;
  final String label;
  final List<String> items;
  const ScenePreset(this.key, this.label, this.items);
}

const sceneTypes = <ScenePreset>[
  ScenePreset('home', '家', ['钥匙', '手机', '钱包', '工卡', '充电器', '雨伞']),
  ScenePreset('office', '公司', ['工卡', '电脑', '充电器', '耳机', '雨伞']),
  ScenePreset('hotel', '酒店', ['房卡', '身份证', '充电器', '洗漱包', '票据']),
  ScenePreset('restaurant', '饭店', ['手机', '钱包', '外套', '雨伞']),
  ScenePreset('gym', '健身房', ['毛巾', '换洗衣物', '水杯', '耳机', '健身卡']),
];
