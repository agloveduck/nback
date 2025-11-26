      function nback_experiment()
    try
        % Collect sub  ject info rmation
        subjectInfo = collectSubjectInfo();
           subjectID = subjectInfo.id;
        subjectGender = subjectIn  fo.gender;
        subjectAge = subjectInfo.age;
        
        % Initialize Psyc   htoolbox
        PsychDefaultSetup(2);
        Screen('Preference', 'SkipSyncTests'  , 1);
        
        % Screen setup
        screenNumber = max(Screen('Screens   '));
        [window, windowRect] = Screen('OpenWindow', screenNumber, [0 0 0]);
          
        % Get screen dimensions
        [screenWidth, screenHeight] = Scr   een('WindowSize', window);
        
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
        baselineVAS = getVASRatingMouse(window, xCenter, yCenter);
        
        % Main experiment loop
        for blockNum = 1:length(blockTypes)
            blockType = blockTypes(blockNum);
            
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
                blockData = runNbackBlockExperiment(window, xCenter, yCenter, blockType, letters, targetLetter);
            else
                blockData = runNbackBlockExperiment(window, xCenter, yCenter, blockType, letters);
            end
            
            % Show feedback after each block
            Screen('TextSize', window, instructionFontSize);
            accuracy = mean(blockData.correctResponses) * 100;
            validRTs = blockData.responseTimes(~isnan(blockData.responseTimes));
            if ~isempty(validRTs)
                avgRT = mean(validRTs) * 1000;  % Convert to milliseconds
                feedbackMsg = sprintf('Block %d completed!\n\n\nAccuracy: %.1f%%\n\nAverage RT: %.0f ms\n\n\nPress SPACE to continue.', blockNum, accuracy, avgRT);
            else
                feedbackMsg = sprintf('Block %d completed!\n\n\nAccuracy: %.1f%%\n\nAverage RT: N/A\n\n\nPress SPACE to continue.', blockNum, accuracy);
            end
            DrawFormattedText(window, feedbackMsg, 'center', 'center', [255 255 255]);
            Screen('Flip', window);
            Screen('TextSize', window, baseFontSize);  % Restore stimulus font size
            KbWait();
            
            % Collect VAS rating after each block
            showVASImage(window, dataDir, xCenter, yCenter);
            vasRating = getVASRatingMouse(window, xCenter, yCenter);
            
            % Save data with baseline VAS and post-block VAS
            saveBlockData(filename, subjectID, subjectGender, subjectAge, ...
                         blockType, blockNum, blockData, baselineVAS, vasRating);
        end
        
        % End experiment
        endMessage = 'Experiment completed! Thank you for your participation.';
        DrawFormattedText(window, endMessage, 'center', 'center', [255 255 255]);
        Screen('Flip', window);
        WaitSecs(3);
        
        % Clean up
        sca;
        
    catch ME
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
            DrawFormattedText(window, 'Press SPACE to continue', 'center', screenHeight - 100, [255 255 255]);
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

function vasRating = getVASRatingMouse(window, xCenter, yCenter)
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
                confirmationText = sprintf('You selected: %d', vasRating);
                DrawFormattedText(window, confirmationText, 'center', 'center', [255 255 255]);
                Screen('Flip', window);
                WaitSecs(0.5);
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

function blockData = runNbackBlockExperiment(window, xCenter, yCenter, n, letters, targetLetter)
    % EXPERIMENT VERSION
    nTrials = 120;
    nTargets = max(1, round(nTrials * 0.2));
    stimulusTime = 0.5;
    responseTime = 2.5;
    trialDuration = 3.0;
    
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
                    end
                elseif keyCode(KbName('RightArrow'))
                    if ~responseMade
                        responseMade = true;
                        responses{trial} = 'RIGHT';
                        responseTimes(trial) = GetSecs - stimOnset;
                        correctResponses(trial) = ~isTarget(trial);
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
