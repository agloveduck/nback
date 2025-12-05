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
6.这段代码是否可以简化，是不是实际上起作用的是triggerBox.port = serial(portName, 'BaudRate', 115200, 'DataBits', 8, ...
                'Parity', 'none', 'StopBits', 1, 'Timeout', 1);
            fopen(triggerBox.port);portName为电脑实际端口号：
try
            % 枚举当前可用串口
            portList = serialportlist("available");

            if isempty(portList)
                % 没找到串口 → 切换到仿真模式
                warning('No serial ports found. Switching to simulation mode.');
                triggerBox.simulationMode = true;
                return;
            end

            fprintf('Available serial ports:\n');
            for i = 1:length(portList)
                fprintf('%d: %s\n', i, char(portList(i)));
            end

            % 默认期望端口名
            desiredPortName = 'COM6';
            availablePorts = cellstr(portList);
            if any(strcmpi(availablePorts, desiredPortName))
                portName = desiredPortName;
            else
                portName = availablePorts{1};
                if ~strcmpi(portName, desiredPortName)
                    fprintf('Desired port %s unavailable. Using %s instead.\n', desiredPortName, portName);
                end
            end

            % 注意：这里用的是旧的 serial 接口，而不是 serialport
            triggerBox.port = serial(portName, 'BaudRate', 115200, 'DataBits', 8, ...
                'Parity', 'none', 'StopBits', 1, 'Timeout', 1);
            fopen(triggerBox.port);

            pause(0.5);

            fprintf('\n=== TRIGGER BOX: HARDWARE MODE ===\n');
            fprintf('Connected to: %s\n', portName);
            fprintf('Baud rate: 115200\n');
            fprintf('==================================\n\n');
        catch ME
            % 初始化串口失败 → 切换到仿真模式，清理已开的端口
            warning('Failed to initialize hardware: %s\nSwitching to simulation mode.', ME.message);
            triggerBox.simulationMode = true;
            if ~isempty(triggerBox.port)
                try
                    fclose(triggerBox.port);
                    delete(triggerBox.port);
                catch
                end
            end
            triggerBox.port = [];
        end
7. 去掉 VAS 图片说明
