        function nback_experiment()
    triggerBox = [];
    try
        % Collect subject information
        subjectInfo = collectSubjectInfo();
        subjectID = subjectInfo.id;
        subjectGender = subjectInfo.gender;
        subjectAge = subjectInfo.age;
        
        % Initialize Biosemi trigger box
        triggerBox = initializeTriggerBox();
        
        % Initialize Psychtoolbox
        PsychDefaultSetup(2);
        Screen('Preference', 'SkipSyncTests'  , 1);
        
        % Screen setup
        screenNumber = max(Screen('Screens'));  
        [window, windowRect] = Screen('OpenWindow', screenNumber, [0 0 0]);
          
        % Get screen dimensions
        [screenWidth, screenHeight] = Screen('WindowSize', window);
        
        % Calculate adaptive font sizes base d on screen height
        baseFontSize = round(screenHeight / 12);
        instructionFontSize = round(screenHeight / 30);
        
        % Set minimum and maximum bounds
        baseFontSize = max(40, min(100, baseFontSize));
        instructionFontSize = max(18, min(36, instructionFontSize));
        
        % Text settings
        Screen('TextSize', window, baseFontSize);
        Screen('TextFont', window, 'Arial');
        Screen('TextColor', window, [255 255 255]);
        
        % Get screen center
        [xCenter, yCenter] = RectCenter(windowRect);
        
        % Data storage setup
        dataDir = './';  % Save to current directory
        if ~exist(dataDir, 'dir')
            mkdir(dataDir);
        end
        
        filename = [dataDir subjectID '_nback_data.csv'];
        
        % Create file header if file doesn't exist
        if ~exist(filename, 'file')
            header = {'SubjectID', 'Gender', 'Age', 'BlockType', 'BlockNumber', 'TrialNumber', ...
                     'Stimulus', 'IsTarget', 'Response', 'RT', 'Correct', 'VAS_Baseline', 'VAS_PostBlock', 'Timestamp'};
            writecell(header, filename);
        end
        
        % Experiment parameters
        letters = ['B','C','D','F','G','H','J','K','L','M','N','P','Q','R','S','T','V','W','X','Z'];
        blockTypes = [0, 0, 0, 1, 1, 1, 2, 2, 2]; % 9 blocks total
        
        % Assign random target letters for 0-back blocks
        targetLetters = letters(randperm(length(letters), 3));
        
        % Experiment instructions - use adaptive font size
        Screen('TextSize', window, instructionFontSize);
        
        instructions = ['Welcome to the N-back experiment!\n\n' ...
                       'You will complete 9 blocks of trials (120 trials each).\n\n' ...
                       '0-back: Press LEFT arrow for the target letter, RIGHT arrow for non-target letters.\n\n' ...
                       '1-back: Press LEFT arrow when the current letter matches the previous one, RIGHT arrow otherwise.\n\n' ...
                       '2-back: Press LEFT arrow when the current letter matches the one from two trials back, RIGHT arrow otherwise.\n\n\n' ...
                       'Press SPACE to continue.'];
        
        DrawFormattedText(window, instructions, 'center', 'center', [255 255 255]);
        Screen('Flip', window);
        
        % Restore font size for stimuli
        Screen('TextSize', window, baseFontSize);
        
        % Wait for SPACE key
        KbWait();
        
        % Collect baseline VAS rating before experiment starts
        showVASImage(window, dataDir, xCenter, yCenter);
        baselineVAS = getVASRatingMouse(window, xCenter, yCenter, triggerBox, 30, 31);
        
        % Send marker: Experiment start
        sendTrigger(triggerBox, 1);
        
        % Main experiment loop
        for blockNum = 1:length(blockTypes)
            blockType = blockTypes(blockNum);
            
            % Send marker: Block start (10 + blockType)
            sendTrigger(triggerBox, 10 + blockType);
            
            % Block instructions with increased line spacing
            Screen('TextSize', window, instructionFontSize);
            if blockType == 0
                targetLetterIndex = ceil(blockNum/3);
                targetLetter = targetLetters(targetLetterIndex);
                blockInstructions = sprintf('0-BACK BLOCK %d/3\n\n\nTarget letter: %s\n\n\nPress LEFT arrow for target, RIGHT arrow for non-target.\n\n\nPress SPACE to start.', ...
                                           targetLetterIndex, targetLetter);
            else
                switch blockType
                    case 1
                        blockInstructions = sprintf('1-BACK BLOCK %d/3\n\n\nPress LEFT arrow when current matches previous.\n\n\nPress RIGHT arrow otherwise.\n\n\nPress SPACE to start.', ceil((blockNum-3)/3));
                    case 2
                        blockInstructions = sprintf('2-BACK BLOCK %d/3\n\n\nPress LEFT arrow when current matches two trials back.\n\n\nPress RIGHT arrow otherwise.\n\n\nPress SPACE to start.', ceil((blockNum-6)/3));
                end
            end
            
            DrawFormattedText(window, blockInstructions, 'center', 'center', [255 255 255]);
            Screen('Flip', window);
            Screen('TextSize', window, baseFontSize);  % Restore stimulus font size
            KbWait(); % Block instructions still use spacebar
            
            % Run block
            if blockType == 0
                blockData = runNbackBlockExperiment(window, xCenter, yCenter, blockType, letters, targetLetter, triggerBox);
            else
                blockData = runNbackBlockExperiment(window, xCenter, yCenter, blockType, letters, [], triggerBox);
            end
            
            % Collect VAS rating after each block
            showVASImage(window, dataDir, xCenter, yCenter);
            vasRating = getVASRatingMouse(window, xCenter, yCenter, triggerBox, 40 + blockType, 50 + blockType);
            
            % Send marker: Block end (20 + blockType)
            sendTrigger(triggerBox, 20 + blockType);
            
            % Save data with baseline VAS and post-block VAS
            saveBlockData(filename, subjectID, subjectGender, subjectAge, ...
                         blockType, blockNum, blockData, baselineVAS, vasRating);
        end
        
        % End experiment
        endMessage = 'Experiment completed! Thank you for your participation.';
        DrawFormattedText(window, endMessage, 'center', 'center', [255 255 255]);
        Screen('Flip', window);
        
        % Send marker: Experiment end
        sendTrigger(triggerBox, 255);
        
        WaitSecs(3);
        
        % Clean up
        closeTriggerBox(triggerBox);
        sca;
        
    catch ME
        closeTriggerBox(triggerBox);
        sca;
        rethrow(ME);
    end
end

function subjectInfo = collectSubjectInfo()
    % Collect subject information via dialog
    prompt = {'Subject ID:', 'Gender (M/F):', 'Age:'};
    dlgtitle = 'Subject Information';
    dims = [1 35; 1 35; 1 35];
    definput = {'', '', ''};
    
    answer = inputdlg(prompt, dlgtitle, dims, definput);
    
    if isempty(answer)
        error('Subject information input was cancelled.');
    end
    
    % Extract and validate input
    subjectInfo.id = answer{1};
    if isempty(subjectInfo.id)
        error('Subject ID cannot be empty.');
    end
    
    subjectInfo.gender = upper(answer{2});
    if ~ismember(subjectInfo.gender, {'M', 'F'})
        error('Gender must be M or F.');
    end
    
    subjectInfo.age = str2double(answer{3});
    if isnan(subjectInfo.age) || subjectInfo.age <= 0 || subjectInfo.age > 120
        error('Age must be a valid number between 1 and 120.');
    end
end

function showVASImage(window, dataDir, xCenter, yCenter)
    vasImagePath = 'VAS.png';
    
    try
        [vasImage, ~, alpha] = imread(vasImagePath);
        
        [screenWidth, screenHeight] = Screen('WindowSize', window);
        
        [imageHeight, imageWidth, ~] = size(vasImage);
        
        widthRatio = (screenWidth * 0.85) / imageWidth;
        heightRatio = (screenHeight * 0.85) / imageHeight;
        scale = min(widthRatio, heightRatio);
        
        newWidth = imageWidth * scale;
        newHeight = imageHeight * scale;
        
        xPos = (screenWidth - newWidth) / 2;
        yPos = (screenHeight - newHeight) / 2;
        
        if ~isempty(alpha)
            rgbaImage = cat(3, vasImage, alpha);
            vasTexture = Screen('MakeTexture', window, rgbaImage);
        else
            vasTexture = Screen('MakeTexture', window, vasImage);
        end
        
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
        warning('Could not load VAS image: %s', ME.message);
        fprintf('Tried to load image from: %s\n', vasImagePath);
        
        spacePressed = false;
        while ~spacePressed
            DrawFormattedText(window, 'VAS Rating Scale\n\nPress SPACE to continue', 'center', 'center', [255 255 255]);
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

function vasRating = getVASRatingMouse(window, xCenter, yCenter, triggerBox, startMarkerCode, submitMarkerCode)
    [screenWidth, screenHeight] = Screen('WindowSize', window);
    
    vasFontSize = round(screenHeight / 25);
    vasFontSize = max(20, min(40, vasFontSize));
    
    scaleWidth = screenWidth * 0.6;
    scaleHeight = 20;
    scaleY = yCenter + 100;
    scaleX1 = xCenter - scaleWidth/2;
    scaleX2 = xCenter + scaleWidth/2;
    
    vasRating = 50;
    ratingSelected = false;
    
    ShowCursor('Arrow');
    
    shouldSendTrigger = nargin >= 6 && ~isempty(triggerBox) && ~isempty(startMarkerCode) && ~isempty(submitMarkerCode);
    if shouldSendTrigger
        sendTrigger(triggerBox, startMarkerCode);
    end
    
    while ~ratingSelected
        [x, y, buttons] = GetMouse(window);
        
        [~, ~, keyCode] = KbCheck;
        if keyCode(KbName('ESCAPE'))
            sca;
            error('Experiment terminated by user');
        end
        
        if y > scaleY - 50 && y < scaleY + 50 && x >= scaleX1 && x <= scaleX2
            vasRating = round((x - scaleX1) / scaleWidth * 100);
            vasRating = max(0, min(100, vasRating));
            
            if buttons(1)
                ratingSelected = true;
                if shouldSendTrigger
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
        
        Screen('FillRect', window, [0 0 0]);
        Screen('TextSize', window, vasFontSize);
        
        DrawFormattedText(window, 'Please rate your mental state (0-100)', 'center', yCenter - 200, [255 255 255]);
        
        Screen('DrawLine', window, [255 255 255], scaleX1, scaleY, scaleX2, scaleY, 3);
        
        for i = 0:10:100
            tickX = scaleX1 + (i/100) * scaleWidth;
            Screen('DrawLine', window, [255 255 255], tickX, scaleY - 10, tickX, scaleY + 10, 2);
            
            if mod(i, 20) == 0
                DrawFormattedText(window, num2str(i), tickX - 10, scaleY + 20, [255 255 255]);
            end
        end
        
        markerX = scaleX1 + (vasRating/100) * scaleWidth;
        Screen('DrawLine', window, [255 255 255], markerX, scaleY - 30, markerX, scaleY + 30, 4);
        
        ratingText = sprintf('Current rating: %d', vasRating);
        DrawFormattedText(window, ratingText, 'center', scaleY + 100, [255 255 255]);
        
        DrawFormattedText(window, 'Click on the scale to select your rating', 'center', scaleY + 150, [255 255 255]);
        
        Screen('Flip', window);
    end
    
    HideCursor();
end

function blockData = runNbackBlockExperiment(window, xCenter, yCenter, n, letters, targetLetter, triggerBox)
    % EXPERIMENT VERSION
    nTrials = 120;
    nTargets = max(1, round(nTrials * 0.2));
    stimulusTime = 0.5;
    responseTime = 2.5;
    trialDuration = 3.0;
    
    if nargin < 6
        targetLetter = [];
    end
    shouldSendTrigger = nargin >= 7 && ~isempty(triggerBox);
    
    % Generate stimulus sequence
    if n == 0
        [stimuli, isTarget] = generateStimulusSequence(letters, nTrials, nTargets, n, targetLetter);
    else
        [stimuli, isTarget] = generateStimulusSequence(letters, nTrials, nTargets, n);
    end
    
    % Initialize response data
    responses = cell(1, nTrials);
    responseTimes = nan(1, nTrials);
    correctResponses = zeros(1, nTrials);
    
    % Show fixation at the beginning of the block
    DrawFormattedText(window, '+', 'center', 'center', [255 255 255]);
    Screen('Flip', window);
    WaitSecs(1);
    
    % Trial loop
    for trial = 1:nTrials
        trialStartTime = GetSecs;
        
        % Check for ESC key
        [~, ~, keyCode] = KbCheck;
        if keyCode(KbName('ESCAPE'))
            sca;
            error('Experiment terminated by user');
        end
        
        % Stimulus presentation
        DrawFormattedText(window, stimuli{trial}, 'center', 'center', [255 255 255]);
        stimOnset = Screen('Flip', window);
        
        if shouldSendTrigger
            markerCode = 100 + (n * 10) + double(isTarget(trial));
            sendTrigger(triggerBox, markerCode);
        end
        
        % Combined stimulus display + response window
        responseWindowEnd = stimOnset + stimulusTime + responseTime;
        responseMade = false;
        screenCleared = false;
        
        while GetSecs < responseWindowEnd
            if ~screenCleared && GetSecs >= stimOnset + stimulusTime
                Screen('Flip', window);
                screenCleared = true;
            end
            
            [keyIsDown, ~, keyCode] = KbCheck;
            
            if keyIsDown
                if keyCode(KbName('ESCAPE'))
                    sca;
                    error('Experiment terminated by user');
                elseif keyCode(KbName('LeftArrow'))
                    if ~responseMade
                        responseMade = true;
                        responses{trial} = 'LEFT';
                        responseTimes(trial) = GetSecs - stimOnset;
                        correctResponses(trial) = isTarget(trial);
                        if shouldSendTrigger
                            sendTrigger(triggerBox, 200 + correctResponses(trial));
                        end
                    end
                elseif keyCode(KbName('RightArrow'))
                    if ~responseMade
                        responseMade = true;
                        responses{trial} = 'RIGHT';
                        responseTimes(trial) = GetSecs - stimOnset;
                        correctResponses(trial) = ~isTarget(trial);
                        if shouldSendTrigger
                            sendTrigger(triggerBox, 210 + correctResponses(trial));
                        end
                    end
                end
            end
        end
        
        if ~responseMade
            responses{trial} = '';
            correctResponses(trial) = 0;
        end
        
        % Wait until fixed trial duration is reached
        trialEndTime = trialStartTime + trialDuration;
        while GetSecs < trialEndTime
            WaitSecs(0.001);
        end
    end
    
    % Organize block data
    blockData = struct();
    blockData.stimuli = stimuli;
    blockData.isTarget = isTarget;
    blockData.responses = responses;
    blockData.responseTimes = responseTimes;
    blockData.correctResponses = correctResponses;
end

function [stimuli, isTarget] = generateStimulusSequence(letters, nTrials, nTargets, n, targetLetter)
    stimuli = cell(1, nTrials);
    isTarget = false(1, nTrials);
    
    nonTargetLetters = [];
    if n == 0
        if nargin < 5 || isempty(targetLetter)
            error('Target letter must be provided for 0-back.');
        end
        nonTargetLetters = setdiff(letters, targetLetter, 'stable');
        if isempty(nonTargetLetters)
            error('Letter pool must contain non-target options for 0-back.');
        end
    end
    
    % Generate all trials with non-target letters first
    for i = 1:nTrials
        if n > 0 && i > n
            % Avoid accidental targets in n-back
            possibleLetters = setdiff(letters, stimuli{i-n});
            stimuli{i} = possibleLetters(randi(length(possibleLetters)));
        else
            if n == 0
                stimuli{i} = nonTargetLetters(randi(length(nonTargetLetters)));
            else
                stimuli{i} = letters(randi(length(letters)));
            end
        end
    end

    % --- TARGET INSERTION ---
    % Get all valid positions for targets
    if n == 0
        validPositions = 1:nTrials;
    else
        validPositions = (n+1):nTrials;
    end
    
    % Ensure no existing targets are in the chosen positions for n-back
    if n > 0
        isClash = true(1, length(validPositions));
        for i = 1:length(validPositions)
            pos = validPositions(i);
            % A clash occurs if the letter at pos is already the same as pos-n
            if ~strcmp(stimuli{pos}, stimuli{pos-n})
                isClash(i) = false;
            end
        end
        validPositions = validPositions(~isClash);
    end

    % Randomly select positions for targets
    if length(validPositions) < nTargets
        warning('Could not generate the requested number of targets. Generated %d instead of %d.', length(validPositions), nTargets);
        nTargets = length(validPositions);
    end
    
    targetPositions = validPositions(randperm(length(validPositions), nTargets));
    
    % Insert targets
    for i = 1:length(targetPositions)
        pos = targetPositions(i);
        isTarget(pos) = true;
        if n == 0
            stimuli{pos} = targetLetter;
        else
            stimuli{pos} = stimuli{pos-n};
        end
    end
end

function saveBlockData(filename, subjectID, gender, age, blockType, ...
                      blockNum, blockData, vasBaseline, vasPostBlock)
    % Save data function
    
    nTrials = length(blockData.stimuli);
    timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
    dataToWrite = cell(nTrials, 14);
    
    for trial = 1:nTrials
        dataToWrite{trial, 1} = subjectID;
        dataToWrite{trial, 2} = gender;
        dataToWrite{trial, 3} = age;
        dataToWrite{trial, 4} = blockType;
        dataToWrite{trial, 5} = blockNum;
        dataToWrite{trial, 6} = trial;
        dataToWrite{trial, 7} = blockData.stimuli{trial};
        dataToWrite{trial, 8} = blockData.isTarget(trial);
        dataToWrite{trial, 9} = blockData.responses{trial};
        if isnan(blockData.responseTimes(trial))
            dataToWrite{trial, 10} = 'NaN';
        else
            dataToWrite{trial, 10} = blockData.responseTimes(trial);
        end
        dataToWrite{trial, 11} = blockData.correctResponses(trial);
        dataToWrite{trial, 12} = vasBaseline;
        dataToWrite{trial, 13} = vasPostBlock;
        dataToWrite{trial, 14} = timestamp;
    end
    
    % Append data to file
    writecell(dataToWrite, filename, 'WriteMode', 'append');
end

function triggerBox = initializeTriggerBox()
    triggerBox = struct();
    triggerBox.simulationMode = true;
    triggerBox.port = [];
    triggerBox.logFile = 'trigger_markers.log';
    triggerBox.logFileId = -1;

    headerFileId = fopen(triggerBox.logFile, 'w');
    if headerFileId == -1
        error('Unable to create trigger log file: %s', triggerBox.logFile);
    end
    fprintf(headerFileId, 'Timestamp,MarkerCode,Description\n');
    fclose(headerFileId);

    triggerBox.logFileId = fopen(triggerBox.logFile, 'a');
    if triggerBox.logFileId == -1
        error('Unable to open trigger log file for appending: %s', triggerBox.logFile);
    end

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
                fprintf('%d: %s\n', i, char(portList(i)));
            end

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

            triggerBox.port = serial(portName, 'BaudRate', 115200, 'DataBits', 8, ...
                'Parity', 'none', 'StopBits', 1, 'Timeout', 1);
            fopen(triggerBox.port);

            pause(0.5);

            fprintf('\n=== TRIGGER BOX: HARDWARE MODE ===\n');
            fprintf('Connected to: %s\n', portName);
            fprintf('Baud rate: 115200\n');
            fprintf('==================================\n\n');
        catch ME
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

function sendTrigger(triggerBox, markerCode)
    timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF');
    description = getMarkerDescription(markerCode);

    if triggerBox.simulationMode || isempty(triggerBox.port)
        fprintf('[%s] Marker %d: %s\n', timestamp, markerCode, description);
    else
        try
            fwrite(triggerBox.port, markerCode, 'uint8');
            pause(0.01);
            fwrite(triggerBox.port, 0, 'uint8');
        catch ME
            warning('Failed to send trigger %d: %s', markerCode, ME.message);
        end
    end

    if isfield(triggerBox, 'logFileId') && triggerBox.logFileId ~= -1
        fprintf(triggerBox.logFileId, '%s,%d,%s\n', timestamp, markerCode, description);
        try
            if exist('fflush', 'builtin') || exist('fflush', 'file')
                fflush(triggerBox.logFileId);
            else
                fseek(triggerBox.logFileId, 0, 'cof');
            end
        catch
            % If the environment does not support fflush/fseek, continue without forcing a flush
        end
    end
end

function closeTriggerBox(triggerBox)
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
        case 255
            description = 'Experiment End';
        otherwise
            description = 'Unknown marker';
    end
end
