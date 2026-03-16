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

  Counselor({
    required this.id,
    required this.name,
    required this.description,
    required this.specialty,
    required this.icon,
    required this.model,
    required this.promptAssetPath,
  });

  Future<String> getSystemPrompt() async {
    return await rootBundle.loadString(promptAssetPath);
  }
}

final List<Counselor> counselors = [
  Counselor(
    id: '1',
    name: 'Paul',
    description: '通用问题解答',
    specialty: '擅长精神分析的咨询师',
    icon: Icons.psychology,
    model: 'GPT-4',
    promptAssetPath: 'assets/prompts/paul.md',
  ),
  Counselor(
    id: '2',
    name: 'Claude',
    description: '深度对话与思考',
    specialty: '擅长哲学思辨与情感支持',
    icon: Icons.auto_stories,
    model: 'Claude',
    promptAssetPath: 'assets/prompts/claude.md',
  ),
  Counselor(
    id: '3',
    name: 'Emma',
    description: '职业规划指导',
    specialty: '专注于个人成长与职业发展',
    icon: Icons.trending_up,
    model: 'GPT-3.5',
    promptAssetPath: 'assets/prompts/emma.md',
  ),
  Counselor(
    id: '4',
    name: 'Sophie',
    description: '情感关系咨询',
    specialty: '擅长人际关系与情感问题',
    icon: Icons.favorite,
    model: 'Claude',
    promptAssetPath: 'assets/prompts/sophie.md',
  ),
  Counselor(
    id: '5',
    name: 'David',
    description: '压力管理专家',
    specialty: '专注焦虑与压力疏导',
    icon: Icons.spa,
    model: 'GPT-4',
    promptAssetPath: 'assets/prompts/david.md',
  ),
  Counselor(
    id: '6',
    name: 'Luna',
    description: '创造力启发',
    specialty: '激发创意与灵感',
    icon: Icons.lightbulb,
    model: 'GPT-4',
    promptAssetPath: 'assets/prompts/luna.md',
  ),
  Counselor(
    id: '7',
    name: 'Freud',
    description: '精神动力学派',
    specialty: '深度心理分析与人格成长',
    icon: Icons.memory,
    model: 'GPT-4',
    promptAssetPath: 'assets/prompts/freud.md',
  ),
  Counselor(
    id: '8',
    name: 'Carl',
    description: '人本主义流派',
    specialty: '自我接纳与个人成长',
    icon: Icons.accessibility_new,
    model: 'Claude',
    promptAssetPath: 'assets/prompts/carl.md',
  ),
  Counselor(
    id: '9',
    name: 'Aaron',
    description: '认知行为流派',
    specialty: '认知重构与行为改变',
    icon: Icons.psychology_alt,
    model: 'GPT-4',
    promptAssetPath: 'assets/prompts/aaron.md',
  ),
  Counselor(
    id: '10',
    name: 'Maya',
    description: '后现代主义流派',
    specialty: '叙事重构与意义创造',
    icon: Icons.stars,
    model: 'Claude',
    promptAssetPath: 'assets/prompts/maya.md',
  ),
  Counselor(
    id: '11',
    name: 'Virginia',
    description: '家庭系统流派',
    specialty: '家庭关系与系统治疗',
    icon: Icons.family_restroom,
    model: 'GPT-4',
    promptAssetPath: 'assets/prompts/virginia.md',
  ),
  Counselor(
    id: '12',
    name: 'Viktor',
    description: '存在主义疗法',
    specialty: '意义追寻与存在探索',
    icon: Icons.explore,
    model: 'Claude',
    promptAssetPath: 'assets/prompts/viktor.md',
  ),
  Counselor(
    id: '13',
    name: 'Fritz',
    description: '完形疗法',
    specialty: '觉察训练与整体整合',
    icon: Icons.blur_on,
    model: 'GPT-4',
    promptAssetPath: 'assets/prompts/fritz.md',
  ),
];
