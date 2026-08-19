import '../models/place.dart';

/// 场景化提醒文案：根据地点名称关键词生成有温度的提醒话术。
/// 对应小程序版 services/messageService.js。
String buildLeaveMessage(Place place, List<String> pendingItems) {
  final name = place.name;
  final itemText = pendingItems.isEmpty
      ? '别忘了检查随身物品'
      : '别忘了带：${pendingItems.join('、')}';

  if (RegExp(r'酒店|宾馆|民宿|客栈').hasMatch(name)) {
    return '检测到您离开「$name」，是在旅游吗？$itemText';
  }
  if (RegExp(r'公司|大厦|办公|写字楼|科技园').hasMatch(name)) {
    return '检测到您离开「$name」，去上班吗？$itemText';
  }
  if (RegExp(r'健身|游泳|运动|瑜伽').hasMatch(name)) {
    return '运动结束，$itemText';
  }
  if (RegExp(r'饭店|餐厅|火锅|烧烤|咖啡').hasMatch(name)) {
    return '离开「$name」，$itemText';
  }
  if (RegExp(r'家|小区|公寓|花园|苑|里').hasMatch(name)) {
    return '出门顺利！$itemText';
  }
  return '检测到您离开「$name」，$itemText';
}
