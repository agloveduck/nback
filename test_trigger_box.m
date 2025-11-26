% Biosemi Trigger Box 测试脚本
% 快速测试trigger发送功能（无需运行完整实验）

function test_trigger_box()
    fprintf('========================================\n');
    fprintf('Biosemi Trigger Box 测试脚本\n');
    fprintf('========================================\n\n');
    
    % 初始化trigger box
    fprintf('1. 初始化Trigger Box...\n');
    triggerBox = initializeTriggerBox();
    pause(1);
    
    % 测试各类marker
    fprintf('\n2. 测试发送marker...\n\n');
    
    % 实验开始
    fprintf('发送: 实验开始 (Code 1)\n');
    sendTrigger(triggerBox, 1);
    pause(0.5);
    
    % Block开始
    fprintf('发送: 0-back Block开始 (Code 10)\n');
    sendTrigger(triggerBox, 10);
    pause(0.5);
    
    % 刺激markers
    fprintf('发送: 0-back 非目标刺激 (Code 100)\n');
    sendTrigger(triggerBox, 100);
    pause(0.3);
    
    fprintf('发送: 0-back 目标刺激 (Code 101)\n');
    sendTrigger(triggerBox, 101);
    pause(0.3);
    
    fprintf('发送: 1-back 目标刺激 (Code 111)\n');
    sendTrigger(triggerBox, 111);
    pause(0.3);
    
    % 反应markers
    fprintf('发送: 左键正确反应 (Code 201)\n');
    sendTrigger(triggerBox, 201);
    pause(0.5);
    
    fprintf('发送: 右键正确反应 (Code 211)\n');
    sendTrigger(triggerBox, 211);
    pause(0.5);
    
    % Block结束
    fprintf('发送: 0-back Block结束 (Code 20)\n');
    sendTrigger(triggerBox, 20);
    pause(0.5);
    
    % 实验结束
    fprintf('发送: 实验结束 (Code 255)\n');
    sendTrigger(triggerBox, 255);
    pause(0.5);
    
    % 关闭
    fprintf('\n3. 关闭Trigger Box...\n');
    closeTriggerBox(triggerBox);
    
    fprintf('\n========================================\n');
    fprintf('测试完成！\n');
    fprintf('请检查 trigger_markers.log 查看所有marker\n');
    fprintf('========================================\n');
end

%% ========== 以下函数从 nback_practice.m 复制 ==========

function triggerBox = initializeTriggerBox()
    triggerBox = struct();
    triggerBox.simulationMode = true;  % 测试时使用模拟模式
    triggerBox.port = [];
    triggerBox.logFile = 'trigger_markers.log';
    
    % 创建/清空日志文件
    fid = fopen(triggerBox.logFile, 'w');
    fprintf(fid, 'Timestamp,MarkerCode,Description\n');
    fclose(fid);
    
    if triggerBox.simulationMode
        fprintf('\n=== TRIGGER BOX: SIMULATION MODE ===\n');
        fprintf('Markers will be logged to: %s\n', triggerBox.logFile);
        fprintf('====================================\n\n');
    else
        try
            portList = serialportlist("available");
            
            if isempty(portList)
                warning('No serial ports found. Switching to simulation mode.');
                triggerBox.simulationMode = true;
                return;
            end
            
            fprintf('Available serial ports:\n');
            for i = 1:length(portList)
                fprintf('%d: %s\n', i, portList(i));
            end
            
            portName = portList(1);
            
            triggerBox.port = serialport(portName, 115200);
            configureTerminator(triggerBox.port, "CR/LF");
            triggerBox.port.DataBits = 8;
            triggerBox.port.Parity = 'none';
            triggerBox.port.StopBits = 1;
            triggerBox.port.Timeout = 1;
            
            pause(0.5);
            
            fprintf('\n=== TRIGGER BOX: HARDWARE MODE ===\n');
            fprintf('Connected to: %s\n', portName);
            fprintf('Baud rate: 115200\n');
            fprintf('==================================\n\n');
            
        catch ME
            warning('Failed to initialize hardware: %s\nSwitching to simulation mode.', ME.message);
            triggerBox.simulationMode = true;
            triggerBox.port = [];
        end
    end
end

function sendTrigger(triggerBox, markerCode)
    timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF');
    description = getMarkerDescription(markerCode);
    
    if triggerBox.simulationMode
        fprintf('[%s] Marker %d: %s\n', timestamp, markerCode, description);
        
        fid = fopen(triggerBox.logFile, 'a');
        fprintf(fid, '%s,%d,%s\n', timestamp, markerCode, description);
        fclose(fid);
        
    else
        try
            write(triggerBox.port, uint8(markerCode), 'uint8');
            pause(0.01);
            write(triggerBox.port, uint8(0), 'uint8');
            
            fid = fopen(triggerBox.logFile, 'a');
            fprintf(fid, '%s,%d,%s\n', timestamp, markerCode, description);
            fclose(fid);
            
        catch ME
            warning('Failed to send trigger %d: %s', markerCode, ME.message);
        end
    end
end

function closeTriggerBox(triggerBox)
    if ~triggerBox.simulationMode && ~isempty(triggerBox.port)
        try
            write(triggerBox.port, uint8(0), 'uint8');
            pause(0.1);
            delete(triggerBox.port);
            fprintf('\nTrigger box connection closed.\n');
        catch ME
            warning('Error closing trigger box: %s', ME.message);
        end
    else
        fprintf('\nSimulation mode ended. Markers logged to: %s\n', triggerBox.logFile);
    end
end

function description = getMarkerDescription(markerCode)
    switch markerCode
        case 1
            description = 'Experiment Start';
        case 10
            description = 'Block Start: 0-back';
        case 11
            description = 'Block Start: 1-back';
        case 12
            description = 'Block Start: 2-back';
        case 20
            description = 'Block End: 0-back';
        case 21
            description = 'Block End: 1-back';
        case 22
            description = 'Block End: 2-back';
        case 100
            description = 'Stimulus: 0-back non-target';
        case 101
            description = 'Stimulus: 0-back target';
        case 110
            description = 'Stimulus: 1-back non-target';
        case 111
            description = 'Stimulus: 1-back target';
        case 120
            description = 'Stimulus: 2-back non-target';
        case 121
            description = 'Stimulus: 2-back target';
        case 200
            description = 'Response: LEFT incorrect';
        case 201
            description = 'Response: LEFT correct';
        case 210
            description = 'Response: RIGHT incorrect';
        case 211
            description = 'Response: RIGHT correct';
        case 255
            description = 'Experiment End';
        otherwise
            description = 'Unknown marker';
    end
end
