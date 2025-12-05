change:
1.将行为数据保存到当前目录下以被试名为文件夹名的目录下，exptrigger_markers.log也保存到该目录下
2. 实验开始marker放到了vas填写前  %% ==================== 发送 “实验开始” Marker ====================
        % 1 = Experiment Start
        sendTrigger(triggerBox, 1);
3.blockTypes = [0, 0, 0, 1, 1, 1, 2, 2, 2]; % 共 9 个 block但是是不是发送triger应该每个block不同，方便切？
现在同一等级的back的3个block发的trigger是一样的: % 发送 block 开始 marker：0-back(10), 1-back(11), 2-back(12)
            sendTrigger(triggerBox, 10 + blockType);，后续想切每个block是不是block开始和结束时的triger不一样比较好

4.人口学信息再加一个左利手右利手
5.有必要对不同等级n back 每个trial target和非target的marker进行区分吗？现在是这样：
n = 0：非 target：100 + 0*10 + 0 = 100 target：100 + 0*10 + 1 = 101
n = 1：非 target：100 + 1*10 + 0 = 110 target：100 + 1*10 + 1 = 111
n = 2：非 target：120 target：121
如果把所有trial的刺激呈现marker都统一成一个，可以吗

