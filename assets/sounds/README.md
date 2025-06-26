# 计算器音效资源

## 音效分类

### 按键音效 (Button Sounds)
- `click_soft.wav` - 柔和点击音（数字按键）
- `click_sharp.wav` - 清脆点击音（运算符按键）
- `click_special.wav` - 特殊音效（功能按键）

### 操作音效 (Action Sounds)
- `calculate.wav` - 计算完成音效
- `error.wav` - 错误提示音效
- `clear.wav` - 清除操作音效

### 主题音效包 (Theme Sound Packs)
- `cyberpunk/` - 赛博朋克主题音效包
  - `cyber_click.wav` - 电子音效点击
  - `cyber_beep.wav` - 电子蜂鸣音
  - `cyber_error.wav` - 电子错误音
  
- `nature/` - 自然主题音效包
  - `wood_tap.wav` - 木质敲击音
  - `water_drop.wav` - 水滴音效
  - `wind_chime.wav` - 风铃音效

- `minimal/` - 极简主题音效包
  - `soft_tick.wav` - 轻柔滴答音
  - `gentle_pop.wav` - 温和弹出音
  - `quiet_ding.wav` - 安静提示音

## 音效配置

每个主题可以配置不同触发器的音效：
- `buttonPress` - 按键按下
- `buttonRelease` - 按键释放  
- `calculation` - 计算完成
- `error` - 错误发生
- `clear` - 清除操作
- `themeChange` - 主题切换

## 文件格式
- 推荐格式：WAV (无损音质)
- 备选格式：MP3 (体积优化)
- 音频长度：0.1-1.0秒
- 采样率：44.1kHz
- 音量控制：可在配置中调节
