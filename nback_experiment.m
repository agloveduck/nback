    function nback_experiment()
    % 主实验函数：完整的 0/1/2-back 实验流程入口
    % 包含：被 试信息采集、屏幕/Trigger 初始化、9 个 block 的 N-back 实验、
    %       每个 block 前后 VAS、行为数据 & VAS 保存到 CSV、触发器日志等。
    
    triggerBox = [];
    try
        %% ================= 被试信息 ====================
        % 弹窗让被试输入 ID / 性别 / 年龄，并做基本合法性检查
        subjectInfo = collectSubjectInfo();
        subjectID = subjectInfo.id;
        subjectGender = subjectInfo.gender;
        subjectAge = subjectInfo.age;
        subjectHandedness = subjectInfo.handedness;
        
        %% ================= Trigger 盒初始化 & 数据目录 ====================
        % 为当前被试创建独立数据目录 ./<SubjectID>/
        dataDir = fullfile(pwd, subjectID);
        if ~exist(dataDir, 'dir')
            mkdir(dataDir);
        end
        
        % 这里会：
        %   1. 在被试目录下创建日志文件 exptrigger_markers.log
        %   2. 尝试打开指定串口（默认 COM6）
        %   3. 决定是 硬件模式 还是 仿真模式
        triggerBox = initializeTriggerBox(dataDir);
        
        %% ================= Psychtoolbox 屏幕初始化 ====================
        PsychDefaultSetup(2);
        % 跳过同步测试（开发/调试时方便，正式实验建议关闭或检查）
        Screen('Preference', 'SkipSyncTests', 1);
        
        % 打开屏幕：选择编号最大的屏幕（通常是外接显示器）
        screenNumber = max(Screen('Screens'));
        [window, windowRect] = Screen('OpenWindow', screenNumber, [0 0 0]); % 黑色背景
        
        % 获取屏幕尺寸（像素）
        [screenWidth, screenHeight] = Screen('WindowSize', window);
        
        %% ================= 自适应字体大小 ====================
        % 刺激字母使用较大的字号
        baseFontSize = round(screenHeight / 12);
        % 说明文字用较小字号
        instructionFontSize = round(screenHeight / 30);
        
        % 限制字号上下界，避免过大或过小
        baseFontSize = max(40, min(100, baseFontSize));
        instructionFontSize = max(18, min(36, instructionFontSize));
        
        % 设置字体（先设成刺激用字号）
        Screen('TextSize', window, baseFontSize);
        Screen('TextFont', window, 'Arial');
        Screen('TextColor', window, [255 255 255]);  % 白字
        
        % 居中坐标
        [xCenter, yCenter] = RectCenter(windowRect);
        
        %% ==================== 行为数据保存设置 ====================
        % 所有行为数据保存到该被试的专属目录 dataDir (= ./<SubjectID>/)
        filename = fullfile(dataDir, [subjectID '_expnback_data.csv']);
        
        % 若文件不存在，先写表头
        if ~exist(filename, 'file')
            header = {'SubjectID', 'Gender', 'Age', 'Handedness', 'BlockType', 'BlockNumber', 'TrialNumber', ...
                      'Stimulus', 'IsTarget', 'Response', 'RT', 'Correct', ...
                      'VAS_Baseline', 'VAS_PostBlock', 'Timestamp'};
            writecell(header, filename);
        end
        
        %% ==================== 实验参数 ====================
        % 刺激字母集合（去掉容易混淆的 A/E/I/O/U 等）
        letters = ['B','C','D','F','G','H','J','K','L','M','N','P','Q','R','S','T','V','W','X','Z'];
        % block 序列：0-back ×3，1-back ×3，2-back ×3
        blockTypes = [0, 0, 0, 1, 1, 1, 2, 2, 2]; % 共 9 个 block
        
        % 为三个 0-back block 随机分配不同的 target 字母
        targetLetters = letters(randperm(length(letters), 3));
        
        %% ==================== 实验说明 ====================
        % 使用说明字号
        Screen('TextSize', window, instructionFontSize);
        
        instructions = ['Welcome to the N-back experiment!\n\n' ...
                       'You will complete 9 blocks of trials (120 trials each).\n\n' ...
                       '0-back: Press LEFT arrow for the target letter, RIGHT arrow for non-target letters.\n\n' ...
                       '1-back: Press LEFT arrow when the current letter matches the previous one, RIGHT arrow otherwise.\n\n' ...
                       '2-back: Press LEFT arrow when the current letter matches the one from two trials back, RIGHT arrow otherwise.\n\n\n' ...
                       'Press SPACE to continue.'];
        
        DrawFormattedText(window, instructions, 'center', 'center', [255 255 255]);
        Screen('Flip', window);
        
        % 恢复刺激字号（后面呈现字母）
        Screen('TextSize', window, baseFontSize);
        
        % 等待按任意键（这里不区分具体键）
        KbWait();
         %% ==================== 发送 “实验开始” Marker ====================
        % 1 = Experiment Start
        sendTrigger(triggerBox, 1);

        %% ==================== 基线 VAS 评分（实验开始前） ====================
        % 直接显示 VAS 刻度并评分 0–100（鼠标拖动并点击）
        % 并发送 VAS Baseline 开始/提交 marker（30/31）
        baselineVAS = getVASRatingMouse(window, xCenter, yCenter, triggerBox, 30, 31);
        
       
        
        %% ==================== 主实验循环：9 个 Block ====================
        for blockNum = 1:length(blockTypes)
            blockType = blockTypes(blockNum);   % 0 / 1 / 2
            
            % 发送 block 开始 marker：每个 block 使用不同的编码（Block 1–9: 11–19）
            blockStartCode = 10 + blockNum;
            sendTrigger(triggerBox, blockStartCode);
            
            % ========= Block 说明 =========
            Screen('TextSize', window, instructionFontSize);
            if blockType == 0
                % 0-back：每个 block 对应一个特定 target 字母
                targetLetterIndex = ceil(blockNum/3);  % 1,2,3
                targetLetter = targetLetters(targetLetterIndex);
                blockInstructions = sprintf( ...
                    '0-BACK BLOCK %d/3\n\n\nTarget letter: %s\n\n\nPress LEFT arrow for target, RIGHT arrow for non-target.\n\n\nPress SPACE to start.', ...
                    targetLetterIndex, targetLetter);
            else
                % 1-back & 2-back：不再给具体字母，只给规则
                switch blockType
                    case 1
                        % ceil((blockNum-3)/3) 也是 1/2/3
                        blockInstructions = sprintf( ...
                            '1-BACK BLOCK %d/3\n\n\nPress LEFT arrow when current matches previous.\n\n\nPress RIGHT arrow otherwise.\n\n\nPress SPACE to start.', ...
                            ceil((blockNum-3)/3));
                    case 2
                        blockInstructions = sprintf( ...
                            '2-BACK BLOCK %d/3\n\n\nPress LEFT arrow when current matches two trials back.\n\n\nPress RIGHT arrow otherwise.\n\n\nPress SPACE to start.', ...
                            ceil((blockNum-6)/3));
                end
            end
            
            DrawFormattedText(window, blockInstructions, 'center', 'center', [255 255 255]);
            Screen('Flip', window);
            Screen('TextSize', window, baseFontSize);  % 刺激字号
            % 等待 SPACE（这里 KbWait 不区分键）
            KbWait();
            
            % ========= 运行该 block 的 N-back 实验 =========
            if blockType == 0
                % 0-back：需要传入 targetLetter
                blockData = runNbackBlockExperiment(window, xCenter, yCenter, blockType, letters, targetLetter, triggerBox);
            else
                % 1/2-back：无需 targetLetter 参数
                blockData = runNbackBlockExperiment(window, xCenter, yCenter, blockType, letters, [], triggerBox);
            end
            
            % ========= block 后 VAS 评分（疲劳程度） =========
            % startMarker = 40/41/42，submitMarker = 50/51/52
            vasRating = getVASRatingMouse(window, xCenter, yCenter, triggerBox, 40 + blockType, 50 + blockType);
            
            % ========= 发送 block 结束 marker =========
            % 每个 block 使用不同的编码（Block 1–9: 21–29）
            blockEndCode = 20 + blockNum;
            sendTrigger(triggerBox, blockEndCode);
            
            % ========= 将该 block 的所有 trial 数据写入 CSV =========
            saveBlockData(filename, subjectID, subjectGender, subjectAge, subjectHandedness, ...
                         blockType, blockNum, blockData, baselineVAS, vasRating);
        end
        
        %% ==================== 实验结束提示 ====================
        endMessage = 'Experiment completed! Thank you for your participation.';
        DrawFormattedText(window, endMessage, 'center', 'center', [255 255 255]);
        Screen('Flip', window);
        
        % 发送“实验结束” marker：255
        sendTrigger(triggerBox, 255);
        
        WaitSecs(3);
        
        % 清理 trigger、关闭屏幕
        closeTriggerBox(triggerBox);
        sca;
        
    catch ME
        % 如果中间出错，也要尽量把 trigger 和屏幕关掉
        closeTriggerBox(triggerBox);
        sca;
        rethrow(ME);
    end
end


%% =============== 子函数：被试信息输入 ===============
function subjectInfo = collectSubjectInfo()
    % 用 inputdlg 弹窗收集主试编号、性别、年龄、利手
    
    prompt = {'Subject ID:', 'Gender (M/F):', 'Age:', 'Handedness (L/R):'};
    dlgtitle = 'Subject Information';
    dims = [1 35; 1 35; 1 35; 1 35];
    definput = {'', '', '', 'R'};
    
    answer = inputdlg(prompt, dlgtitle, dims, definput);
    
    if isempty(answer)
        error('Subject information input was cancelled.');
    end
    
    % 被试 ID
    subjectInfo.id = answer{1};
    if isempty(subjectInfo.id)
        error('Subject ID cannot be empty.');
    end
    
    % 性别：只接受 M/F
    subjectInfo.gender = upper(strtrim(answer{2}));
    if ~ismember(subjectInfo.gender, {'M', 'F'})
        error('Gender must be M or F.');
    end
    
    % 年龄：1–120
    subjectInfo.age = str2double(answer{3});
    if isnan(subjectInfo.age) || subjectInfo.age <= 0 || subjectInfo.age > 120
        error('Age must be a valid number between 1 and 120.');
    end
    
    % 利手：只接受 L/R
    subjectInfo.handedness = upper(strtrim(answer{4}));
    if ~ismember(subjectInfo.handedness, {'L', 'R'})
        error('Handedness must be L or R.');
    end
end


%% =============== 子函数：显示 VAS 图片 ===============
function showVASImage(window, dataDir, xCenter, yCenter)
    % 尝试读取 VAS.png，并按屏幕大小缩放后居中显示
    % 被试按 SPACE 键继续；按 ESC 终止实验。
    
    vasImagePath = 'VAS.png';
    
    try
        [vasImage, ~, alpha] = imread(vasImagePath);
        
        [screenWidth, screenHeight] = Screen('WindowSize', window);
        [imageHeight, imageWidth, ~] = size(vasImage);
        
        % 缩放到屏幕宽/高 85% 以内
        widthRatio = (screenWidth * 0.85) / imageWidth;
        heightRatio = (screenHeight * 0.85) / imageHeight;
        scale = min(widthRatio, heightRatio);
        
        newWidth = imageWidth * scale;
        newHeight = imageHeight * scale;
        
        xPos = (screenWidth - newWidth) / 2;
        yPos = (screenHeight - newHeight) / 2;
        
        % 如果有 alpha 通道，转为 RGBA
        if ~isempty(alpha)
            rgbaImage = cat(3, vasImage, alpha);
            vasTexture = Screen('MakeTexture', window, rgbaImage);
        else
            vasTexture = Screen('MakeTexture', window, vasImage);
        end
        
        % 循环直到按 SPACE 才退出
        spacePressed = false;
        while ~spacePressed
            Screen('DrawTexture', window, vasTexture, [], [xPos, yPos, xPos+newWidth, yPos+newHeight]);
            Screen('Flip', window);
            
            [~, ~, keyCode] = KbCheck;
            if keyCode(KbName('ESCAPE'))
                Screen('Close', vasTexture);
                sca;
                error('Experiment terminated by user');
            elseif keyCode(KbName('space'))
                spacePressed = true;
            end
            
            WaitSecs(0.01);
        end
        
        Screen('Close', vasTexture);
        
    catch ME
        % 如果加载图片失败，则用简单的文本提示代替
        warning('Could not load VAS image: %s', ME.message);
        fprintf('Tried to load image from: %s\n', vasImagePath);
        
        spacePressed = false;
        while ~spacePressed
            DrawFormattedText(window, ...
                'VAS Rating Scale\n\nPress SPACE to continue', ...
                'center', 'center', [255 255 255]);
            Screen('Flip', window);
            
            [~, ~, keyCode] = KbCheck;
            if keyCode(KbName('ESCAPE'))
                sca;
                error('Experiment terminated by user');
            elseif keyCode(KbName('space'))
                spacePressed = true;
            end
            
            WaitSecs(0.01);
        end
    end
end


%% =============== 子函数：鼠标方式 VAS 打分 ===============
function vasRating = getVASRatingMouse(window, xCenter, yCenter, triggerBox, startMarkerCode, submitMarkerCode)
    % 画一条 0–100 的水平刻度线，被试用鼠标移动并点击确定评分。
    % 若传入 startMarkerCode/submitMarkerCode，则在开始和提交时发送 marker。
    
    [screenWidth, screenHeight] = Screen('WindowSize', window);
    
    vasFontSize = round(screenHeight / 25);
    vasFontSize = max(20, min(40, vasFontSize));
    
    % 刻度条宽度为屏幕宽度的 60%，高度 20 像素
    scaleWidth = screenWidth * 0.6;
    scaleHeight = 20;
    scaleY = yCenter + 100;            % 刻度条纵向位置
    scaleX1 = xCenter - scaleWidth/2;  % 左端
    scaleX2 = xCenter + scaleWidth/2;  % 右端
    
    vasRating = 50;          % 初始评分设为中间 50
    ratingSelected = false;  % 是否已点击确认评分
    
    ShowCursor('Arrow');     % 显示鼠标指针
    
    % 判断是否需要发送 trigger（即是否有 triggerBox 和 marker code）
    shouldSendTrigger = nargin >= 6 && ~isempty(triggerBox) && ...
                        ~isempty(startMarkerCode) && ~isempty(submitMarkerCode);
    if shouldSendTrigger
        % VAS 开始 marker
        sendTrigger(triggerBox, startMarkerCode);
    end
    
    % 循环直到被试点击刻度条完成评分
    while ~ratingSelected
        [x, y, buttons] = GetMouse(window);
        
        % ESC 随时终止实验
        [~, ~, keyCode] = KbCheck;
        if keyCode(KbName('ESCAPE'))
            sca;
            error('Experiment terminated by user');
        end
        
        % 如果鼠标在刻度条附近，更新当前 rating 值
        if y > scaleY - 50 && y < scaleY + 50 && x >= scaleX1 && x <= scaleX2
            vasRating = round((x - scaleX1) / scaleWidth * 100);
            vasRating = max(0, min(100, vasRating));
            
            % 左键按下：确认评分
            if buttons(1)
                ratingSelected = true;
                if shouldSendTrigger
                    % VAS 提交 marker
                    sendTrigger(triggerBox, submitMarkerCode);
                end
                confirmationText = sprintf('You selected: %d', vasRating);
                Screen('FillRect', window, [0 0 0]);
                DrawFormattedText(window, confirmationText, 'center', 'center', [255 255 255]);
                Screen('Flip', window);
                WaitSecs(0.5);
                break;
            end
        end
        
        % === 绘制界面 ===
        Screen('FillRect', window, [0 0 0]);
        Screen('TextSize', window, vasFontSize);
        
        DrawFormattedText(window, 'Please rate your mental state (0-100)', ...
                          'center', yCenter - 200, [255 255 255]);
        
        % 画主刻度线
        Screen('DrawLine', window, [255 255 255], scaleX1, scaleY, scaleX2, scaleY, 3);
        
        % 画刻度和数字
        for i = 0:10:100
            tickX = scaleX1 + (i/100) * scaleWidth;
            Screen('DrawLine', window, [255 255 255], tickX, scaleY - 10, tickX, scaleY + 10, 2);
            
            if mod(i, 20) == 0
                DrawFormattedText(window, num2str(i), tickX - 10, scaleY + 20, [255 255 255]);
            end
        end
        
        % 当前 rating 对应位置画一条竖线
        markerX = scaleX1 + (vasRating/100) * scaleWidth;
        Screen('DrawLine', window, [255 255 255], markerX, scaleY - 30, markerX, scaleY + 30, 4);
        
        % 显示当前分数
        ratingText = sprintf('Current rating: %d', vasRating);
        DrawFormattedText(window, ratingText, 'center', scaleY + 100, [255 255 255]);
        
        DrawFormattedText(window, 'Click on the scale to select your rating', ...
                          'center', scaleY + 150, [255 255 255]);
        
        Screen('Flip', window);
    end
    
    HideCursor();
end


%% =============== 子函数：单个 Block 的 N-back 实验（实验版本） ===============
function blockData = runNbackBlockExperiment(window, xCenter, yCenter, n, letters, targetLetter, triggerBox)
    % 对应一个 block 的 N-back 任务：
    %   nTrials=120，每 trial 持续 3 s（0.5 s 刺激 + 2.5 s 响应）
    %   target 比例约 20%
    %   按 Left/RightArrow 响应，并根据是否 target 判定正确性
    %   同时发送刺激/反应 marker
    
    % ----------- 参数设置 -----------
    nTrials = 120;
    nTargets = max(1, round(nTrials * 0.2));  % ~20% target
    stimulusTime = 0.5;  % 刺激呈现时间
    responseTime = 2.5;  % 刺激消失后响应时间
    trialDuration = 3.0; % 整个 trial 固定 3 s
    
    if nargin < 6
        targetLetter = [];
    end
    shouldSendTrigger = nargin >= 7 && ~isempty(triggerBox);
    
    leftArrowKeyCode = KbName('LeftArrow');
    rightArrowKeyCode = KbName('RightArrow');
    
    % ----------- 生成刺激序列（字母 + 是否 target） -----------
    if n == 0
        [stimuli, isTarget] = generateStimulusSequence(letters, nTrials, nTargets, n, targetLetter);
    else
        [stimuli, isTarget] = generateStimulusSequence(letters, nTrials, nTargets, n);
    end
    
    % 初始化行为数据
    responses = cell(1, nTrials);        % 存储 'LEFT'/'RIGHT'/其他
    responseTimes = nan(1, nTrials);     % RT（相对刺激呈现时间）
    correctResponses = zeros(1, nTrials);% 0/1 正确性
    
    % Block 开始前，先展示 1 秒 fixation
    DrawFormattedText(window, '+', 'center', 'center', [255 255 255]);
    Screen('Flip', window);
    WaitSecs(1);
    
    % ----------- Trial 循环 -----------
    for trial = 1:nTrials
        trialStartTime = GetSecs;
        
        % 每个 trial 开始先检查是否按 ESC 终止实验
        [~, ~, keyCode] = KbCheck;
        if keyCode(KbName('ESCAPE'))
            sca;
            error('Experiment terminated by user');
        end
        
        % ---- 刺激呈现 ----
        DrawFormattedText(window, stimuli{trial}, 'center', 'center', [255 255 255]);
        stimOnset = Screen('Flip', window);  % 记录刺激呈现时间
        
        % 发送刺激 marker：100/101/110/111/120/121
        if shouldSendTrigger
            markerCode = 100 + (n * 10) + double(isTarget(trial));
            sendTrigger(triggerBox, markerCode);
        end
        
        % ---- 刺激呈现 + 响应窗口合并 ----
        responseWindowEnd = stimOnset + stimulusTime + responseTime;
        responseMade = false;
        screenCleared = false;
        
        while GetSecs < responseWindowEnd
            % 刺激呈现 stimulusTime 秒后清屏
            if ~screenCleared && GetSecs >= stimOnset + stimulusTime
                Screen('Flip', window);
                screenCleared = true;
            end
            
            [keyIsDown, ~, keyCode] = KbCheck;
            
            if keyIsDown
                if keyCode(KbName('ESCAPE'))
                    % ESC 终止实验
                    sca;
                    error('Experiment terminated by user');
                elseif keyCode(leftArrowKeyCode)
                    % LEFT 响应
                    if ~responseMade
                        responseMade = true;
                        responses{trial} = 'LEFT';
                        responseTimes(trial) = GetSecs - stimOnset;
                        % 正确性：target trial 按 LEFT 才是正确
                        correctResponses(trial) = isTarget(trial);
                        if shouldSendTrigger
                            % 200=LEFT incorrect, 201=LEFT correct
                            sendTrigger(triggerBox, 200 + correctResponses(trial));
                        end
                    end
                elseif keyCode(rightArrowKeyCode)
                    % RIGHT 响应
                    if ~responseMade
                        responseMade = true;
                        responses{trial} = 'RIGHT';
                        responseTimes(trial) = GetSecs - stimOnset;
                        % 非 target trial 按 RIGHT 才是正确
                        correctResponses(trial) = ~isTarget(trial);
                        if shouldSendTrigger
                            % 210=RIGHT incorrect, 211=RIGHT correct
                            sendTrigger(triggerBox, 210 + correctResponses(trial));
                        end
                    end
                else
                    % 按了其他键（无效按键）
                    if ~responseMade
                        responseMade = true;
                        % 把按键名处理为字符串（比如 'A' -> 'INVALID_A'）
                        pressedKeyIndex = find(keyCode, 1);
                        pressedKeyName = KbName(pressedKeyIndex);
                        if iscell(pressedKeyName)
                            pressedKeyName = pressedKeyName{1};
                        end
                        if isa(pressedKeyName, 'string')
                            pressedKeyName = char(pressedKeyName);
                        end
                        sanitizedKeyName = 'UNKNOWN';
                        if ischar(pressedKeyName)
                            sanitizedKeyName = upper(strrep(pressedKeyName, ' ', '_'));
                        end
                        responses{trial} = ['INVALID_' sanitizedKeyName];
                        responseTimes(trial) = GetSecs - stimOnset;
                        correctResponses(trial) = 0;
                        if shouldSendTrigger
                            % 220 = Invalid key
                            sendTrigger(triggerBox, 220);
                        end
                    end
                end
            end
        end
        
        % 如果整个响应窗口内都没按键
        if ~responseMade
            responses{trial} = 'NONE';
            correctResponses(trial) = 0;
            if shouldSendTrigger
                % 221 = No response
                sendTrigger(triggerBox, 221);
            end
        end
        
        % ---- 保证 trial 总时长固定为 3 s ----
        trialEndTime = trialStartTime + trialDuration;
        while GetSecs < trialEndTime
            WaitSecs(0.001);
        end
    end
    
    % ----------- 整理输出结构 -----------
    blockData = struct();
    blockData.stimuli = stimuli;
    blockData.isTarget = isTarget;
    blockData.responses = responses;
    blockData.responseTimes = responseTimes;
    blockData.correctResponses = correctResponses;
end


%% =============== 子函数：生成 N-back 刺激序列 ===============
function [stimuli, isTarget] = generateStimulusSequence(letters, nTrials, nTargets, n, targetLetter)
    % 根据 N-back 规则生成一个长度为 nTrials 的字母序列和 target 标记。
    % 对于 0-back：将所有 trial 先填满非 target 字母，再随机选位置插入目标字母。
    % 对于 1/2-back：先生成不包含“自然 n-back target”的序列，再随机选合法位置插入 target。
    
    stimuli = cell(1, nTrials);
    isTarget = false(1, nTrials);
    
    nonTargetLetters = [];
    if n == 0
        % 0-back：必须指定 targetLetter
        if nargin < 5 || isempty(targetLetter)
            error('Target letter must be provided for 0-back.');
        end
        % 非 target 字母集合
        nonTargetLetters = setdiff(letters, targetLetter, 'stable');
        if isempty(nonTargetLetters)
            error('Letter pool must contain non-target options for 0-back.');
        end
    end
    
    % ========== 先生成一个非 target 序列 ==========
    for i = 1:nTrials
        if n > 0 && i > n
            % 对于 1/2-back，从第 n+1 个 trial 开始，避免出现自然 target
            % 通过从字母集里排除 stimuli{i-n}
            possibleLetters = setdiff(letters, stimuli{i-n});
            stimuli{i} = possibleLetters(randi(length(possibleLetters)));
        else
            if n == 0
                % 0-back：一开始全部用非 target 字母填充
                stimuli{i} = nonTargetLetters(randi(length(nonTargetLetters)));
            else
                % 1/2-back 的前 n 个 trial：无约束随机
                stimuli{i} = letters(randi(length(letters)));
            end
        end
    end

    % ========== 再选位置插入目标 ==========
    % 对于 0-back，所有 trial 都可以成为 target
    % 对于 1/2-back，只有从第 n+1 个 trial 开始才有 n-back 关系
    if n == 0
        validPositions = 1:nTrials;
    else
        validPositions = (n+1):nTrials;
    end
    
    % 如果是 1/2-back，进一步筛掉“已经自然符合 n-back”的位置，避免重复插入
    if n > 0
        isClash = true(1, length(validPositions));
        for i = 1:length(validPositions)
            pos = validPositions(i);
            % 如果当前字母和 pos-n 的字母不同，则这里还不是 target，可以用来插入
            if ~strcmp(stimuli{pos}, stimuli{pos-n})
                isClash(i) = false;
            end
        end
        validPositions = validPositions(~isClash);
    end

    % 如果合法位置数量 < 目标数，发 warning 并调整 nTargets
    if length(validPositions) < nTargets
        warning('Could not generate the requested number of targets. Generated %d instead of %d.', ...
                length(validPositions), nTargets);
        nTargets = length(validPositions);
    end
    
    % 随机选出若干位置作为 target
    targetPositions = validPositions(randperm(length(validPositions), nTargets));
    
    % 在这些位置插入 target
    for i = 1:length(targetPositions)
        pos = targetPositions(i);
        isTarget(pos) = true;
        if n == 0
            % 0-back：把字母改为固定的 targetLetter
            stimuli{pos} = targetLetter;
        else
            % 1/2-back：把该位置字母改为 pos-n 位置的字母
            stimuli{pos} = stimuli{pos-n};
        end
    end
end


%% =============== 子函数：保存一个 Block 的行为数据 ===============
function saveBlockData(filename, subjectID, gender, age, handedness, blockType, ...
                      blockNum, blockData, vasBaseline, vasPostBlock)
    % 将当前 block 的 120 个 trial 行为数据写入 CSV 文件（append 模式）
    
    nTrials = length(blockData.stimuli);
    timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
    dataToWrite = cell(nTrials, 15);
    
    for trial = 1:nTrials
        dataToWrite{trial, 1} = subjectID;
        dataToWrite{trial, 2} = gender;
        dataToWrite{trial, 3} = age;
        dataToWrite{trial, 4} = handedness;
        dataToWrite{trial, 5} = blockType;
        dataToWrite{trial, 6} = blockNum;
        dataToWrite{trial, 7} = trial;
        dataToWrite{trial, 8} = blockData.stimuli{trial};
        dataToWrite{trial, 9} = blockData.isTarget(trial);
        dataToWrite{trial, 10} = blockData.responses{trial};
        if isnan(blockData.responseTimes(trial))
            dataToWrite{trial, 11} = 'NaN';
        else
            dataToWrite{trial, 11} = blockData.responseTimes(trial);
        end
        dataToWrite{trial, 12} = blockData.correctResponses(trial);
        dataToWrite{trial, 13} = vasBaseline;
        dataToWrite{trial, 14} = vasPostBlock;
        dataToWrite{trial, 15} = timestamp;
    end
    
    % 追加写入
    writecell(dataToWrite, filename, 'WriteMode', 'append');
end


%% =============== 子函数：Trigger Box 初始化 ===============
function triggerBox = initializeTriggerBox(dataDir)
    % 尝试初始化串口和触发器日志文件。
    % 若没有找到串口，则进入 simulationMode（只写日志，不发硬件）。
    % dataDir: 当前被试的数据目录，用于保存 exptrigger_markers.log
    
    if nargin < 1 || isempty(dataDir)
        dataDir = pwd;
    end
    if ~exist(dataDir, 'dir')
        mkdir(dataDir);
    end
    
    triggerBox = struct();
    triggerBox.simulationMode = false;       % 默认先假设有硬件，模拟时改成true
    triggerBox.port = [];
    triggerBox.logFile = fullfile(dataDir, 'exptrigger_markers.log');
    triggerBox.logFileId = -1;

    % 先创建/覆盖 log 文件，并写 header
    headerFileId = fopen(triggerBox.logFile, 'w');
    if headerFileId == -1
        error('Unable to create trigger log file: %s', triggerBox.logFile);
    end
    fprintf(headerFileId, 'Timestamp,MarkerCode,Description\n');
    fclose(headerFileId);

    % 以追加模式打开 log 文件
    triggerBox.logFileId = fopen(triggerBox.logFile, 'a');
    if triggerBox.logFileId == -1
        error('Unable to open trigger log file for appending: %s', triggerBox.logFile);
    end

    if triggerBox.simulationMode
        % 如果一开始就设为仿真模式（此处默认 false，所以不会进来）
        fprintf('\n=== TRIGGER BOX: SIMULATION MODE ===\n');
        fprintf('Markers will be logged to: %s\n', triggerBox.logFile);
        fprintf('====================================\n\n');
    else
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
    end
end


%% =============== 子函数：发送 Trigger（真正发给 BioSemi 的地方） ===============
function sendTrigger(triggerBox, markerCode)
    % 统一的 trigger 发送函数：
    %   1. 若有硬件，则通过串口发送一个 uint8 的 markerCode，然后再发 0 复位。
    %   2. 无硬件则在控制台打印并写入 log 文件。
    
    timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF');
    description = getMarkerDescription(markerCode);

    if triggerBox.simulationMode || isempty(triggerBox.port)
        % 仿真模式：只在命令行打印
        fprintf('[%s] Marker %d: %s\n', timestamp, markerCode, description);
    else
        % ========= 真正发给 BioSemi Trigger Box 的部分 =========
        try
            fwrite(triggerBox.port, markerCode, 'uint8');  % 发送 marker
            pause(0.01);                                   % 保持 10 ms
            fwrite(triggerBox.port, 0, 'uint8');           % 发送 0 清零
        catch ME
            warning('Failed to send trigger %d: %s', markerCode, ME.message);
        end
    end

    % 同时写入日志文件
    if isfield(triggerBox, 'logFileId') && triggerBox.logFileId ~= -1
        fprintf(triggerBox.logFileId, '%s,%d,%s\n', timestamp, markerCode, description);
        try
            % 尽量把缓冲区刷新到磁盘
            if exist('fflush', 'builtin') || exist('fflush', 'file')
                fflush(triggerBox.logFileId);
            else
                fseek(triggerBox.logFileId, 0, 'cof');
            end
        catch
            % 某些环境不支持 fflush/fseek 时忽略错误
        end
    end
end


%% =============== 子函数：关闭 Trigger Box ===============
function closeTriggerBox(triggerBox)
    % 关闭硬件端口、结束仿真提示，并关闭日志文件
    
    if ~isstruct(triggerBox) || isempty(triggerBox)
        return;
    end

    if ~triggerBox.simulationMode && ~isempty(triggerBox.port)
        try
            fwrite(triggerBox.port, 0, 'uint8');
            pause(0.1);
            fclose(triggerBox.port);
            delete(triggerBox.port);
            fprintf('\nTrigger box connection closed.\n');
        catch ME
            warning('Error closing trigger box: %s', ME.message);
        end
    else
        fprintf('\nSimulation mode ended. Markers logged to: %s\n', triggerBox.logFile);
    end

    if isfield(triggerBox, 'logFileId') && triggerBox.logFileId ~= -1
        fclose(triggerBox.logFileId);
    end
end


%% =============== 子函数：marker 码 → 文字描述 ===============
function description = getMarkerDescription(markerCode)
    % 根据 markerCode 返回文字描述，方便日志查看 & 事后对齐事件类型。
    
    switch markerCode
        case 1
            description = 'Experiment Start';
        case 11
            description = 'Block 1 Start: 0-back';
        case 12
            description = 'Block 2 Start: 0-back';
        case 13
            description = 'Block 3 Start: 0-back';
        case 14
            description = 'Block 4 Start: 1-back';
        case 15
            description = 'Block 5 Start: 1-back';
        case 16
            description = 'Block 6 Start: 1-back';
        case 17
            description = 'Block 7 Start: 2-back';
        case 18
            description = 'Block 8 Start: 2-back';
        case 19
            description = 'Block 9 Start: 2-back';
        case 21
            description = 'Block 1 End: 0-back';
        case 22
            description = 'Block 2 End: 0-back';
        case 23
            description = 'Block 3 End: 0-back';
        case 24
            description = 'Block 4 End: 1-back';
        case 25
            description = 'Block 5 End: 1-back';
        case 26
            description = 'Block 6 End: 1-back';
        case 27
            description = 'Block 7 End: 2-back';
        case 28
            description = 'Block 8 End: 2-back';
        case 29
            description = 'Block 9 End: 2-back';
        case 30
            description = 'VAS Start: Baseline';
        case 31
            description = 'VAS Submit: Baseline';
        case 40
            description = 'VAS Start: Post-block 0-back';
        case 41
            description = 'VAS Start: Post-block 1-back';
        case 42
            description = 'VAS Start: Post-block 2-back';
        case 50
            description = 'VAS Submit: Post-block 0-back';
        case 51
            description = 'VAS Submit: Post-block 1-back';
        case 52
            description = 'VAS Submit: Post-block 2-back';
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
        case 220
            description = 'Response: Invalid key';
        case 221
            description = 'Response: No response';
        case 255
            description = 'Experiment End';
        otherwise
            description = 'Unknown marker';
    end
end
