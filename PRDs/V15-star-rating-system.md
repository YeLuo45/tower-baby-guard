# V15: 星星评分系统

## 目标
实现关卡完成后的3星评分系统，包括结算界面、星星计算逻辑、持久化存储、world_select星星显示更新。

## 需求

### 1. Victory Screen（结算界面）
- 创建 `victory_screen.tscn` + `victory_screen.gd`
- 显示：关卡名称、总波数、剩余生命、通关时间
- 显示：获得的星星（1-3颗，基于表现）
- 按钮：「返回世界选择」
- 显示「恭喜通关！」或「获得X颗星」

### 2. 星星计算逻辑
- 3星：通关时剩余生命 ≥ 15
- 2星：通关时剩余生命 ≥ 10
- 1星：通关时剩余生命 > 0
- 记录到 persistence（按 world_scene_key 存储）

### 3. Persistence 扩展
- 新增 `level_stars: Dictionary` 存储每个关卡的最高星星
- Key格式：`"world_%d_scene_%d"` 如 `"world_0_scene_0"`
- Value: 0-3 的整数
- 保存到 ConfigFile 的 `level_stars` section
- 读取时若已有更高星星则保留（不覆盖）

### 4. World Select 星星显示
- `_load_world_scenes()` 从 Persistence 加载各关卡星星
- 显示每个场景按钮旁的星星（★/☆）
- 显示世界总星星进度（X/9）

### 5. 游戏流程接入
- `game.gd`: 监听 `GameState.victory` 信号 → 显示 victory_screen
- 胜利时调用 `_calculate_and_save_stars()` 计算星星并存入 persistence
- 结算完成后 `get_tree().change_scene_to_file("res://src/scenes/world_select.tscn")`

## 技术方案

### 星星计算规则（基于 lives 剩余）
| 剩余生命 | 星星 |
|---------|------|
| ≥ 15 | ★★★ (3星) |
| 10-14 | ★★☆ (2星) |
| 1-9 | ★☆☆ (1星) |
| 0 (失败) | 无结算 |

### Persistence 数据结构
```
level_stars = {
    "world_0_scene_0": 3,  # 世界1第1关：3星
    "world_0_scene_1": 2,  # 世界1第2关：2星
    ...
}
```

## 修改文件清单
1. `src/scenes/victory_screen.gd` - 新建
2. `src/scenes/victory_screen.tscn` - 新建
3. `src/systems/persistence_system.gd` - 新增 level_stars 存储
4. `src/scenes/game.gd` - 接入 victory 信号
5. `src/scenes/world_select.gd` - 从 persistence 加载星星显示

## 验收标准
- 通关后显示胜利界面，显示获得的星星数量
- 星星数据持久化，退出重进后 world_select 显示正确
- 重复挑战时若新星星更高则更新（保留最高记录）
- 「返回世界选择」按钮正确返回 world_select.tscn