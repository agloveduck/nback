# Biosemi Trigger Box 集成说明

## 概述
代码已集成Biosemi Trigger Interface Box支持，通过串口发送marker到打标盒，再经由光纤传输到Biosemi EEG系统的status channel。

## Marker编码方案

### 实验控制标记
- **1**: 实验开始
- **255**: 实验结束

### Block标记
- **10**: 0-back block开始
- **11**: 1-back block开始
- **12**: 2-back block开始
- **20**: 0-back block结束
- **21**: 1-back block结束
- **22**: 2-back block结束

### 刺激标记
- **100**: 0-back 非目标刺激
- **101**: 0-back 目标刺激
- **110**: 1-back 非目标刺激
- **111**: 1-back 目标刺激
- **120**: 2-back 非目标刺激
- **121**: 2-back 目标刺激

### 反应标记
- **200**: 左键反应（错误）
- **201**: 左键反应（正确）
- **210**: 右键反应（错误）
- **211**: 右键反应（正确）

## 使用方法

### 1. 模拟模式（默认）
当前代码默认运行在**模拟模式**，无需实际硬件连接。

**特点：**
- 所有marker会输出到控制台
- 同时记录到 `trigger_markers.log` 文件
- 适合测试和调试

**运行：**
```matlab
nback_practice()
```

### 2. 真实硬件模式

**前提条件：**
1. 连接Biosemi Trigger Interface Box到电脑USB端口
2. 确认串口驱动已安装（FTDI或CH340驱动）
3. 光纤连接到Biosemi放大器

**切换到硬件模式：**

打开 `nback_practice.m`，找到 `initializeTriggerBox()` 函数（约第566行）：

```matlab
function triggerBox = initializeTriggerBox()
    triggerBox = struct();
    triggerBox.simulationMode = false;  % 改为 false 启用硬件
    ...
```

**配置串口（如需要）：**

在同一函数中，如果需要指定特定串口：

```matlab
% 查看可用端口后手动指定
portName = 'COM3';  % Windows示例
% 或
portName = '/dev/tty.usbserial-XXXXXXXX';  % Mac示例
```

**连接参数：**
- 波特率: 115200
- 数据位: 8
- 校验位: None
- 停止位: 1
- Marker持续时间: 10ms（自动发送reset）

## 验证Marker发送

### 查看日志文件
运行后检查 `trigger_markers.log`：
```
Timestamp,MarkerCode,Description
2025-11-25 14:30:15.123,1,Experiment Start
2025-11-25 14:30:20.456,10,Block Start: 0-back
2025-11-25 14:30:25.789,101,Stimulus: 0-back target
...
```

### 在Biosemi系统中验证
1. 打开Biosemi ActiView软件
2. 查看Status通道
3. 实验运行时，应能看到marker在status channel中显示

## 故障排除

### 找不到串口
**问题：** 运行时提示"No serial ports found"

**解决：**
1. 检查USB连接
2. 确认驱动安装（设备管理器中查看）
3. Mac系统：运行 `ls /dev/tty.*` 查看设备

### Marker未出现在EEG数据中
**检查清单：**
- [ ] 光纤正确连接到Biosemi放大器
- [ ] Biosemi系统正在recording状态
- [ ] Trigger box电源已打开
- [ ] 查看trigger_markers.log确认marker已发送

### 串口权限问题（Mac/Linux）
```bash
sudo chmod 666 /dev/tty.usbserial-XXXXXXXX
```

## 时间精度说明
- Marker发送紧跟在 `Screen('Flip')` 之后
- 刺激onset marker在屏幕刷新后立即发送（<1ms延迟）
- 反应marker在按键检测后立即发送

## 修改建议

### 自定义Marker编码
修改 `getMarkerDescription()` 函数来添加新的marker定义。

### 调整Marker持续时间
在 `sendTrigger()` 函数中修改：
```matlab
pause(0.01);  % 默认10ms，可调整为5-20ms
```

## 注意事项
1. 每次实验前确认trigger box连接状态
2. 建议先用模拟模式测试程序流程
3. 真实采集前，用短测试确认marker正常传输
4. 保留trigger_markers.log作为备份参考

## 技术支持
如有问题，检查：
1. `trigger_markers.log` - 确认程序发送了marker
2. 串口监视工具 - 确认串口数据传输
3. Biosemi ActiView - 确认EEG系统接收marker
