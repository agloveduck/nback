function nback_practice()
    triggerBox = [];
    try
        % Collect subject information
        subjectInfo = collectSubjectInfo();
        subjectID = subjectInfo.id;
        subjectGender = subjectInfo.gender;
        subjectAge = subjectInfo.age;

        % Initialize Biosemi Trigger Box (with simulation mode)
        triggerBox = initializeTriggerBox();
        
        % Initialize Psychtoolbox  
          PsychDefaultSetup(2);   
        Screen('Preference', 'SkipSyncTests', 1);
        
        % Screen setup、
        screenNumber = max(Screen('Screens'));
        [window, windowRect] = Screen('OpenWindow', screenNumber, [0 0 0]);
        
        % Get screen dimensions
        [screenWidth, screenHeight] = Screen('WindowSize', window);
        
        % Calculate adaptive font sizes based on screen height
        % Base calculation on screen height (more reliable than width)
        baseFontSize = round(screenHeight / 12);  % Increased from /20 to /12 for larger stimuli
        instructionFontSize = round(screenHeight / 30);  % Instruction font
        
        % Set minimum and maximum bounds
        baseFontSize = max(40, min(100, baseFontSize));  % Increased minimum from 24 to 40, max from 60 to 100
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
        
        filename = [dataDir subjectID '_nback_practice_data.csv'];
        
        % Create file header if file doesn't exist
        if ~exist(filename, 'file')
            header = {'SubjectID', 'Gender', 'Age', 'BlockType', 'BlockNumber', 'TrialNumber', ...
                     'Stimulus', 'IsTarget', 'Response', 'RT', 'Correct', 'VAS_Baseline', 'VAS_PostBlock', 'Timestamp'};
            writecell(header, filename);
        end
        
        % Experiment parameters - PRACTICE VERSION
        letters = ['B','C','D','F','G','H','J','K','L','M','N','P','Q','R','S','T','V','W','X','Z'];
        blockTypes = [0, 1, 2];  % Only 3 blocks (one of each type)
        
        % Assign random target letter for 0-back block
        targetLetter = letters(randi(length(letters)));
        
        % Experiment instructions - use adaptive font size
        Screen('TextSize', window, instructionFontSize);
        
        instructions = sprintf(['Welcome to the N-back PRACTICE experiment!\n\n' ...
                                 'This is a shortened practice version (3 blocks, 20 trials each).\n\n' ...
                                 '0-back: Press LEFT arrow for target letter, RIGHT arrow for non-target.\n\n' ...
                                 '1-back: Press LEFT arrow when current matches previous, RIGHT arrow otherwise.\n\n' ...
                                 '2-back: Press LEFT arrow when current matches two trials back, RIGHT arrow otherwise.\n\n\n' ...
                                 'Press SPACE to continue.']);
        
        DrawFormattedText(window, instructions, 'center', 'center', [255 255 255]);
        Screen('Flip', window);
        
        % Restore font size for stimuli
        Screen('TextSize', window, baseFontSize);
        
        % Wait for SPACE key
        KbWait();
        
        % Collect baseline VAS rating before experiment starts
        baselineVAS = getVASRatingMouse(window, xCenter, yCenter, triggerBox, 30, 31);
        
        % Send marker: Experiment start
        sendTrigger(triggerBox, 1);
        
        % Main experiment loop
        for blockNum = 1:length(blockTypes)
            blockType = blockTypes(blockNum);
            
            % Send marker: Block start, each practice block uses a unique code (11–13)
            blockStartCode = 10 + blockNum;
            sendTrigger(triggerBox, blockStartCode);
            
            % Block instructions with increased line spacing
            Screen('TextSize', window, instructionFontSize);
            if blockType == 0
                blockInstructions = sprintf(['0-BACK PRACTICE BLOCK\n\n\n' ...
                                              'Target letter: %s\n\n\n' ...
                                              'Press LEFT arrow for target, RIGHT arrow for non-target.\n\n\n' ...
                                              'Press SPACE to start.'], targetLetter);
            else
                switch blockType
                    case 1
                        blockInstructions = sprintf(['1-BACK PRACTICE BLOCK\n\n\n' ...
                                                      'Press LEFT arrow when current matches previous.\n\n\n' ...
                                                      'Press RIGHT arrow otherwise.\n\n\n' ...
                                                      'Press SPACE to start.']);
                    case 2
                        blockInstructions = sprintf(['2-BACK PRACTICE BLOCK\n\n\n' ...
                                                      'Press LEFT arrow when current matches two trials back.\n\n\n' ...
                                                      'Press RIGHT arrow otherwise.\n\n\n' ...
                                                      'Press SPACE to start.']);
                end
            end
            
            DrawFormattedText(window, blockInstructions, 'center', 'center', [255 255 255]);
            Screen('Flip', window);
            Screen('TextSize', window, baseFontSize);  % Restore stimulus font size
            KbWait(); % Block instructions still use spacebar
            
            % Run block - PRACTICE VERSION with 20 trials
            if blockType == 0
                blockData = runNbackBlockPractice(window, xCenter, yCenter, blockType, letters, targetLetter, triggerBox);
            else
                blockData = runNbackBlockPractice(window, xCenter, yCenter, blockType, letters, [], triggerBox);
            end
            
            % Show feedback after each block
            Screen('TextSize', window, instructionFontSize);
            accuracy = mean(blockData.correctResponses) * 100;
            validRTs = blockData.responseTimes(~isnan(blockData.responseTimes));
            if ~isempty(validRTs)
                avgRT = mean(validRTs) * 1000;  % Convert to milliseconds
                feedbackMsg = sprintf(['Block %d completed!\n\n\n' ...
                                         'Accuracy: %.1f%%\n\n' ...
                                         'Average RT: %.0f ms\n\n\n' ...
                                         'Press SPACE to continue.'], blockNum, accuracy, avgRT);
            else
                feedbackMsg = sprintf(['Block %d completed!\n\n\n' ...
                                         'Accuracy: %.1f%%\n\n' ...
                                         'Average RT: N/A\n\n\n' ...
                                         'Press SPACE to continue.'], blockNum, accuracy);
            end
            DrawFormattedText(window, feedbackMsg, 'center', 'center', [255 255 255]);
            Screen('Flip', window);
            Screen('TextSize', window, baseFontSize);  % Restore stimulus font size
            KbWait();
            KbReleaseWait([], 2);
            
            % Collect VAS rating after each block
            vasRating = getVASRatingMouse(window, xCenter, yCenter, triggerBox, 40 + blockType, 50 + blockType);
            
            % Send marker: Block end, each practice block uses a unique code (21–23)
            blockEndCode = 20 + blockNum;
            sendTrigger(triggerBox, blockEndCode);
            
            % Save data with baseline VAS and post-block VAS
            saveBlockData(filename, subjectID, subjectGender, subjectAge, ...
                         blockType, blockNum, blockData, baselineVAS, vasRating);
        end
        
        % End experiment
        endMessage = 'Practice completed! Thank you for your participation.';
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
    dlgtitle = 'Subject Information - PRACTICE';
    dims = [1 35; 1 35; 1 35];
    definput = {'PRACTICE', '', ''};
    
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
    % VAS image path - look in current directory
    vasImagePath = 'VAS.png';
    
    try
        % Read image
        [vasImage, ~, alpha] = imread(vasImagePath);
        
        % Get screen dimensions
        [screenWidth, screenHeight] = Screen('WindowSize', window);
        
        % Get image dimensions
        [imageHeight, imageWidth, ~] = size(vasImage);
        
        % Calculate scaling to fit screen while maintaining aspect ratio
        widthRatio = (screenWidth * 0.85) / imageWidth;
        heightRatio = (screenHeight * 0.85) / imageHeight;
        scale = min(widthRatio, heightRatio);
        
        newWidth = imageWidth * scale;
        newHeight = imageHeight * scale;
        
        % Calculate position to center image
        xPos = (screenWidth - newWidth) / 2;
        yPos = (screenHeight - newHeight) / 2;
        
        % Create texture
        if ~isempty(alpha)
            rgbaImage = cat(3, vasImage, alpha);
            vasTexture = Screen('MakeTexture', window, rgbaImage);
        else
            vasTexture = Screen('MakeTexture', window, vasImage);
        end
        
        % Display image until SPACE is pressed
        spacePressed = false;
        while ~spacePressed
            Screen('DrawTexture', window, vasTexture, [], [xPos, yPos, xPos+newWidth, yPos+newHeight]);
            % DrawFormattedText(window, 'Press SPACE to continue', 'center', screenHeight - 100, [255 255 255]);
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
        
        % Display alternative text
        spacePressed = false;
        while ~spacePressed
            DrawFormattedText(window, sprintf('VAS Rating Scale Press SPACE to continue'), 'center', 'center', [255 255 255]);
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
    % Mouse selection for VAS rating
    
    [screenWidth, screenHeight] = Screen('WindowSize', window);
    
    % Adaptive font size for VAS
    vasFontSize = round(screenHeight / 25);
    vasFontSize = max(20, min(40, vasFontSize));
    
    % Scale parameters
    scaleWidth = screenWidth * 0.6;
    scaleHeight = 20;
    scaleY = yCenter + 100;
    scaleX1 = xCenter - scaleWidth/2;
    scaleX2 = xCenter + scaleWidth/2;
    
    % Initialize rating
    vasRating = 50;
    ratingSelected = false;
    
    ShowCursor('Arrow');
    
    shouldSendTrigger = nargin >= 6 && ~isempty(triggerBox) && ~isempty(startMarkerCode) && ~isempty(submitMarkerCode);
    if shouldSendTrigger
        sendTrigger(triggerBox, startMarkerCode);
    end
    
    while ~ratingSelected
        [x, y, buttons] = GetMouse(window);
        
        % Check for ESC key
        [~, ~, keyCode] = KbCheck;
        if keyCode(KbName('ESCAPE'))
            sca;
            error('Experiment terminated by user');
        end
        
        % Update rating if mouse is near scale
        if y > scaleY - 50 && y < scaleY + 50 && x >= scaleX1 && x <= scaleX2
            vasRating = round((x - scaleX1) / scaleWidth * 100);
            vasRating = max(0, min(100, vasRating));
            
            % Confirm selection on mouse click
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
        
        % Draw interface
        Screen('FillRect', window, [0 0 0]);
        Screen('TextSize', window, vasFontSize);
        
        DrawFormattedText(window, 'Please rate your mental state (0-100)', 'center', yCenter - 200, [255 255 255]);
        
        % Draw scale
        Screen('DrawLine', window, [255 255 255], scaleX1, scaleY, scaleX2, scaleY, 3);
        
        % Draw ticks
        for i = 0:10:100
            tickX = scaleX1 + (i/100) * scaleWidth;
            Screen('DrawLine', window, [255 255 255], tickX, scaleY - 10, tickX, scaleY + 10, 2);
            
            if mod(i, 20) == 0
                DrawFormattedText(window, num2str(i), tickX - 10, scaleY + 20, [255 255 255]);
            end
        end
        
        % Draw current selection marker
        markerX = scaleX1 + (vasRating/100) * scaleWidth;
        Screen('DrawLine', window, [255 255 255], markerX, scaleY - 30, markerX, scaleY + 30, 4);
        
        % Show current rating
        ratingText = sprintf('Current rating: %d', vasRating);
        DrawFormattedText(window, ratingText, 'center', scaleY + 100, [255 255 255]);
        
        DrawFormattedText(window, 'Click on the scale to select your rating', 'center', scaleY + 150, [255 255 255]);
        
        Screen('Flip', window);
    end
    
    HideCursor();
end

function blockData = runNbackBlockPractice(window, xCenter, yCenter, n, letters, targetLetter, triggerBox)
    % PRACTICE VERSION - Reduced trials
    nTrials = 20;  % Reduced from 120 to 20
    nTargets = max(1, round(nTrials * 0.2));  % Ensure 20% target rate
    stimulusTime = 0.5;
    responseTime = 2.5;  % Response window duration
    trialDuration = 3.0;  % Fixed total duration per trial (3 seconds)
    
    shouldSendTrigger = nargin >= 7 && ~isempty(triggerBox);
    leftArrowKeyCode = KbName('LeftArrow');
    rightArrowKeyCode = KbName('RightArrow');
    
    % Generate stimulus sequence
    if n == 0
        [stimuli, isTarget] = generateStimulusSequence(letters, nTrials, nTargets, n, targetLetter);
    else
        [stimuli, isTarget] = generateStimulusSequence(letters, nTrials, nTargets, n);
    end
    
    % Initialize response data
    responses = cell(1, nTrials);  % Store recorded key labels for each trial
    responseTimes = nan(1, nTrials);
    correctResponses = zeros(1, nTrials);
    
    % Show fixation at the beginning of the block
    DrawFormattedText(window, '+', 'center', 'center', [255 255 255]);
    Screen('Flip', window);
    WaitSecs(1);  % 1 second fixation before block starts
    
    % Trial loop
    for trial = 1:nTrials
        trialStartTime = GetSecs;  % Record trial start time
        
        % Check for ESC key
        [~, ~, keyCode] = KbCheck;
        if keyCode(KbName('ESCAPE'))
            sca;
            error('Experiment terminated by user');
        end
        
        % Stimulus presentation
        DrawFormattedText(window, stimuli{trial}, 'center', 'center', [255 255 255]);
        stimOnset = Screen('Flip', window);
        
        % Send marker: Stimulus onset
        % Marker code: 100 + (n*10) + isTarget
        % 0-back non-target: 100, 0-back target: 101
        % 1-back non-target: 110, 1-back target: 111
        % 2-back non-target: 120, 2-back target: 121
        markerCode = 100 + (n * 10) + isTarget(trial);
        if shouldSendTrigger
            sendTrigger(triggerBox, markerCode);
        end
        
        % Combined stimulus display + response window
        responseWindowEnd = stimOnset + stimulusTime + responseTime;
        responseMade = false;
        screenCleared = false;  % Track if screen has been cleared
        
        % Check for response during entire period (stimulus + response window)
        while GetSecs < responseWindowEnd
            % Clear screen after stimulus duration (exactly at 0.5s)
            if ~screenCleared && GetSecs >= stimOnset + stimulusTime
                Screen('Flip', window);
                screenCleared = true;
            end
            
            [keyIsDown, ~, keyCode] = KbCheck;
            
            if keyIsDown
                if keyCode(KbName('ESCAPE'))
                    sca;
                    error('Experiment terminated by user');
                elseif keyCode(leftArrowKeyCode)
                    if ~responseMade
                        responseMade = true;
                        responses{trial} = 'LEFT';
                        responseTimes(trial) = GetSecs - stimOnset;
                        correctResponses(trial) = isTarget(trial);
                        if shouldSendTrigger
                            sendTrigger(triggerBox, 200 + correctResponses(trial));
                        end
                    end
                elseif keyCode(rightArrowKeyCode)
                    if ~responseMade
                        responseMade = true;
                        responses{trial} = 'RIGHT';
                        responseTimes(trial) = GetSecs - stimOnset;
                        correctResponses(trial) = ~isTarget(trial);
                        if shouldSendTrigger
                            sendTrigger(triggerBox, 210 + correctResponses(trial));
                        end
                    end
                else
                    if ~responseMade
                        responseMade = true;
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
                            sendTrigger(triggerBox, 220);
                        end
                    end
                end
            end
        end
        
        % If no response was made, mark as incorrect
        if ~responseMade
            responses{trial} = 'NONE';
            correctResponses(trial) = 0;
            if shouldSendTrigger
                sendTrigger(triggerBox, 221);
            end
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
    
    if n == 0
        if nargin < 5 || isempty(targetLetter)
            error('Target letter must be provided for 0-back.');
        end
        nonTargetLetters = setdiff(letters, targetLetter, 'stable');
        if isempty(nonTargetLetters)
            error('Letter pool must contain non-target options for 0-back.');
        end
    else
        targetLetter = letters(randi(length(letters)));
    end
    
    for i = 1:nTrials
        if n == 0
            stimuli{i} = nonTargetLetters(randi(length(nonTargetLetters)));
        else
            if i > n
                availableLetters = setdiff(letters, stimuli{i - n}, 'stable');
                stimuli{i} = availableLetters(randi(length(availableLetters)));
            else
                stimuli{i} = letters(randi(length(letters)));
            end
        end
    end
    
    targetCount = 0;
    attempts = 0;
    maxAttempts = 1000;
    
    while targetCount < nTargets && attempts < maxAttempts
        if n == 0
            pos = randi([1, nTrials]);
            if ~isTarget(pos)
                stimuli{pos} = targetLetter;
                isTarget(pos) = true;
                targetCount = targetCount + 1;
            end
        else
            pos = randi([n + 1, nTrials]);
            if ~isTarget(pos) && ~strcmp(stimuli{pos}, stimuli{pos - n})
                stimuli{pos} = stimuli{pos - n};
                isTarget(pos) = true;
                targetCount = targetCount + 1;
            end
        end
        attempts = attempts + 1;
    end
    
    if targetCount < nTargets
        for i = nTrials:-1:1
            if ~isTarget(i)
                if n == 0
                    stimuli{i} = targetLetter;
                elseif i > n
                    stimuli{i} = stimuli{i - n};
                else
                    continue;
                end
                isTarget(i) = true;
                targetCount = targetCount + 1;
                if targetCount >= nTargets
                    break;
                end
            end
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
        dataToWrite{trial, 12} = vasBaseline;  % Baseline VAS (collected before experiment)
        dataToWrite{trial, 13} = vasPostBlock;  % Post-block VAS (collected after this block)
        dataToWrite{trial, 14} = timestamp;
    end
    
    % Append data to file   
    writecell(dataToWrite, filename, 'WriteMode', 'append');
end

%% ========== BIOSEMI TRIGGER BOX FUNCTIONS ==========

function triggerBox = initializeTriggerBox()
    % Initialize Biosemi Trigger Interface Box
    % Supports both real hardware and simulation mode
    
    triggerBox = struct();
    triggerBox.simulationMode = false;  % Set to false when using real hardware
    triggerBox.port = [];
    triggerBox.logFile = 'trigger_markers.log';
    triggerBox.logFileId = -1;
    
    % Create/clear log file
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
        % Real hardware initialization
        try
            % Find available serial ports
            portList = serialportlist("available");
            
            if isempty(portList)
                warning('No serial ports found. Switching to simulation mode.');
                triggerBox.simulationMode = true;
                return;
            end
            
            % Display available ports
            fprintf('Available serial ports:\n');
            for i = 1:length(portList)
                fprintf('%d: %s\n', i, char(portList(i)));
            end
            
            % You can manually specify the port here
            % For Biosemi Trigger Box, typically something like 'COM3' (Windows) or '/dev/tty.usbserial-XXX' (Mac)
            desiredPortName = 'COM6';
            availablePorts = cellstr(portList);
            if any(strcmpi(availablePorts, desiredPortName))
                portName = desiredPortName;  % Use preferred port when available
            else
                portName = availablePorts{1};  % Fallback to first available port
                if ~strcmpi(portName, desiredPortName)
                    fprintf('Desired port %s unavailable. Using %s instead.\n', desiredPortName, portName);
                end
            end
            
            % Configure serial port for Biosemi Trigger Box
            % Typical settings: 115200 baud, 8 data bits, no parity, 1 stop bit
            triggerBox.port = serial(portName, 'BaudRate', 115200, 'DataBits', 8, ...
                'Parity', 'none', 'StopBits', 1, 'Timeout', 1);
            fopen(triggerBox.port);
            
            % Test connection
            pause(0.5);  % Allow port to initialize
            
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
    % Send trigger marker to Biosemi box
    % markerCode: integer 0-255
    
    timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF');
    description = getMarkerDescription(markerCode);
    
    if triggerBox.simulationMode || isempty(triggerBox.port)
        % Simulation mode: log to file and console
        fprintf('[%s] Marker %d: %s\n', timestamp, markerCode, description);
    else
        % Real hardware: send via serial port
        try
            % Send marker code as byte
            fwrite(triggerBox.port, markerCode, 'uint8');
            
            % Optional: send reset code after short delay (common practice)
            pause(0.01);  % 10ms marker duration
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
    % Close trigger box connection
    
    if ~triggerBox.simulationMode && ~isempty(triggerBox.port)
        try
            % Send final reset
            fwrite(triggerBox.port, 0, 'uint8');
            pause(0.1);
            
            % Close port
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
    % Get human-readable description of marker code
    
    switch markerCode
        case 1
            description = 'Experiment Start';
        case 11
            description = 'Practice Block 1 Start: 0-back';
        case 12
            description = 'Practice Block 2 Start: 1-back';
        case 13
            description = 'Practice Block 3 Start: 2-back';
        case 21
            description = 'Practice Block 1 End: 0-back';
        case 22
            description = 'Practice Block 2 End: 1-back';
        case 23
            description = 'Practice Block 3 End: 2-back';
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
