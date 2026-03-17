import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Counselor {
  final String id;
  final String name;
  final String description;
  final String specialty;
  final IconData icon;
  final String model;
  final String promptAssetPath;
  final String bustImagePath;
  final String headImagePath;

  Counselor({
    required this.id,
    required this.name,
    required this.description,
    required this.specialty,
    required this.icon,
    required this.model,
    required this.promptAssetPath,
    required this.bustImagePath,
    required this.headImagePath,
  });

  Future<String> getSystemPrompt() async {
    return await rootBundle.loadString(promptAssetPath);
  }
}

final List<Counselor> counselors = [
  Counselor(
    id: '1',
    name: '张伟',
    description: '通用问题解答',
    specialty: '擅长精神分析的咨询师',
    icon: Icons.psychology,
    model: 'GPT-4',
    promptAssetPath: 'assets/prompts/zhangwei.md',
    bustImagePath: 'assets/busts/male_1.png',
    headImagePath: 'assets/busts/male_1_head.png',
  ),
  Counselor(
    id: '2',
    name: '晓雅',
    description: '深度对话与思考',
    specialty: '擅长哲学思辨与情感支持',
    icon: Icons.auto_stories,
    model: 'Claude',
    promptAssetPath: 'assets/prompts/xiaoya.md',
    bustImagePath: 'assets/busts/female_1.png',
    headImagePath: 'assets/busts/female_1_head.png',
  ),
  Counselor(
    id: '3',
    name: '思远',
    description: '职业规划指导',
    specialty: '专注于个人成长与职业发展',
    icon: Icons.trending_up,
    model: 'GPT-3.5',
    promptAssetPath: 'assets/prompts/siyuan.md',
    bustImagePath: 'assets/busts/male_2_7.png',
    headImagePath: 'assets/busts/male_2_7_head.png',
  ),
  Counselor(
    id: '4',
    name: '雨婷',
    description: '情感关系咨询',
    specialty: '擅长人际关系与情感问题',
    icon: Icons.favorite,
    model: 'Claude',
    promptAssetPath: 'assets/prompts/yuting.md',
    bustImagePath: 'assets/busts/female_2.png',
    headImagePath: 'assets/busts/female_2_head.png',
  ),
  Counselor(
    id: '5',
    name: '李强',
    description: '压力管理专家',
    specialty: '专注焦虑与压力疏导',
    icon: Icons.spa,
    model: 'GPT-4',
    promptAssetPath: 'assets/prompts/liqiang.md',
    bustImagePath: 'assets/busts/male_2_8.png',
    headImagePath: 'assets/busts/male_2_8_head.png',
  ),
  Counselor(
    id: '6',
    name: '灵儿',
    description: '创造力启发',
    specialty: '激发创意与灵感',
    icon: Icons.lightbulb,
    model: 'GPT-4',
    promptAssetPath: 'assets/prompts/linger.md',
    bustImagePath: 'assets/busts/female_3.png',
    headImagePath: 'assets/busts/female_3_head.png',
  ),
  Counselor(
    id: '7',
    name: '慧敏',
    description: '精神动力学派',
    specialty: '深度心理分析与人格成长',
    icon: Icons.memory,
    model: 'GPT-4',
    promptAssetPath: 'assets/prompts/huimin.md',
    bustImagePath: 'assets/busts/female_4.png',
    headImagePath: 'assets/busts/female_4_head.png',
  ),
  Counselor(
    id: '8',
    name: '心怡',
    description: '人本主义流派',
    specialty: '自我接纳与个人成长',
    icon: Icons.accessibility_new,
    model: 'Claude',
    promptAssetPath: 'assets/prompts/xinyi.md',
    bustImagePath: 'assets/busts/female_5.png',
    headImagePath: 'assets/busts/female_5_head.png',
  ),
  Counselor(
    id: '9',
    name: '梦琪',
    description: '认知行为流派',
    specialty: '认知重构与行为改变',
    icon: Icons.psychology_alt,
    model: 'GPT-4',
    promptAssetPath: 'assets/prompts/mengqi.md',
    bustImagePath: 'assets/busts/female_6.png',
    headImagePath: 'assets/busts/female_6_head.png',
  ),
  Counselor(
    id: '10',
    name: '若雪',
    description: '后现代主义流派',
    specialty: '叙事重构与意义创造',
    icon: Icons.stars,
    model: 'Claude',
    promptAssetPath: 'assets/prompts/ruoxue.md',
    bustImagePath: 'assets/busts/female_7.png',
    headImagePath: 'assets/busts/female_7_head.png',
  ),
  Counselor(
    id: '11',
    name: '玉兰',
    description: '家庭系统流派',
    specialty: '家庭关系与系统治疗',
    icon: Icons.family_restroom,
    model: 'GPT-4',
    promptAssetPath: 'assets/prompts/yulan.md',
    bustImagePath: 'assets/busts/female_8.png',
    headImagePath: 'assets/busts/female_8_head.png',
  ),
  Counselor(
    id: '12',
    name: '雅琳',
    description: '存在主义疗法',
    specialty: '意义追寻与存在探索',
    icon: Icons.explore,
    model: 'Claude',
    promptAssetPath: 'assets/prompts/yalin.md',
    bustImagePath: 'assets/busts/female_2_1.png',
    headImagePath: 'assets/busts/female_2_1_head.png',
  ),
  Counselor(
    id: '13',
    name: '诗涵',
    description: '完形疗法',
    specialty: '觉察训练与整体整合',
    icon: Icons.blur_on,
    model: 'GPT-4',
    promptAssetPath: 'assets/prompts/shihan.md',
    bustImagePath: 'assets/busts/female_2_2.png',
    headImagePath: 'assets/busts/female_2_2_head.png',
  ),
];
