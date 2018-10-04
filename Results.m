classdef Results < handle
    %RESULTS results from a series of trials
    
    properties% (Access = private)
        filename
        mouseID
        sessionNum
        dateTime
        globalStart
        sessionID
        saveDir
        startTimes
        endTimes
        contrastSequence
        contrastOptions
        stimSequence
        joystickResponses
        joystickResponseTimes
        joystickCounts
        responseCorrect
        responded
        firstLickTimes
        numTrials
        trialType
        currentTrial
    end
    
    methods
        function obj = Results(id, trials, sessionNum,experiment,renderer,type)
            %empty buffers for data logging
            obj.dateTime = experiment.dateTime;
            obj.globalStart = experiment.globalStart;
            obj.startTimes = zeros(1,trials);
            obj.stimSequence = cell(1,trials);
            obj.contrastOptions = renderer.CONTRAST_OPTIONS;
            obj.contrastSequence = zeros(1,trials);
            obj.joystickResponses = cell(1,trials);
            for i = 1:trials
                obj.joystickResponses{i} = 'None';
            end
            obj.joystickResponseTimes = -1*ones(1,trials);%-1 is used as a null value
            obj.joystickCounts = [];
            obj.responseCorrect = zeros(1,trials);
            obj.responded = zeros(1,trials);
            obj.firstLickTimes = [];
            obj.numTrials = trials;
            obj.trialType = type;
            obj.mouseID = id;
            obj.sessionNum = sessionNum;
            
            %save directory
            obj.sessionID = [datestr(date, 'mmddyy') '_' num2str(obj.sessionNum)];
            obj.saveDir = experiment.saveDir;
        end
        function [] = StartTrial(obj, trialNum, stimulusPosition, contrastSeq, startTime)
            obj.currentTrial = trialNum;
            obj.stimSequence{trialNum} = stimulusPosition;
            obj.contrastSequence(trialNum) = contrastSeq;
            obj.startTimes(trialNum) = startTime;
        end
        function [] = LogLeft(obj)
            obj.responseCorrect(obj.currentTrial) = 0;
            obj.joystickResponses{obj.currentTrial} = 'Left';
            obj.responded(obj.currentTrial) = 1;%true
        end
        
        function [] = LogRight(obj)
           obj.responseCorrect(obj.currentTrial) = 0;
            obj.joystickResponses{obj.currentTrial} = 'Right';
            obj.responded(obj.currentTrial) = 1;%true
        end
        
        function [] = LogSuccess(obj, time)
            if ~obj.responded(obj.currentTrial)
                obj.responseCorrect(obj.currentTrial) = 1;
                obj.joystickResponses{obj.currentTrial} = obj.stimSequence{obj.currentTrial};
                obj.responded(obj.currentTrial) = 1;%true
            end
            obj.joystickResponseTimes(obj.currentTrial) = time;
        end
        function [] = LogLick(obj, time)
            obj.firstLickTimes(obj.currentTrial) = time;
        end

        %save results in '.mat' file
        function [] = save(obj)
            if ~exist(obj.saveDir)
                mkdir(obj.saveDir);
            end
            save([obj.saveDir '/' obj.mouseID '_' obj.sessionID '_results.mat'],'obj');
        end
        
        %overall correct rate (including no-response trials)
        function ocr = getOverallCorrectRate(obj)
            ocr = mean(obj.responseCorrect(1:obj.currentTrial-1));
        end
        
        %overall response rate
        function orr = getOverallResponseRate(obj)
            orr = mean(obj.responded(1:obj.currentTrial-1));
        end
        
        %correct rate for trials with 'Left' stimulus
        function lcr = getLeftCorrectRate(obj)
            lcr = mean(obj.responseCorrect(cellfun(@(x)strcmp(x,'Left'),obj.stimSequence(1:obj.currentTrial-1))));
        end
        
        %correct rate for trials with 'Right' stimulus
        function rcr = getRightCorrectRate(obj)
            rcr = mean(obj.responseCorrect(cellfun(@(x)strcmp(x,'Right'),obj.stimSequence(1:obj.currentTrial-1))));
        end
        
        %response rate for trials with 'Left' stimulus
        function lrr = getLeftResponseRate(obj)
            lrr = mean(obj.responded(cellfun(@(x)strcmp(x,'Left'),obj.stimSequence(1:obj.currentTrial-1))));
        end
        
        %response rate for trials with 'Right' stimulus
        function rrr = getRightResponseRate(obj)
            rrr = mean(obj.responded(cellfun(@(x)strcmp(x,'Right'),obj.stimSequence(1:obj.currentTrial-1))));
        end
        
        %fraction of time mouse response to the left (doesn't include no-response trials)
        function lrp = getLeftResponseProportion(obj)
            lrp = mean(cellfun(@(x)strcmp(x,'Left'),obj.joystickResponses(logical(obj.responded(1:obj.currentTrial-1)))));
        end
        
        %fraction of time mouse response to the right (doesn't include no-response trails)
        function rrp = getRightResponseProportion(obj)
            rrp = mean(cellfun(@(x)strcmp(x,'Right'),obj.joystickResponses(logical(obj.responded(1:obj.currentTrial-1)))));
        end
        
        %correct rate for a specific contrast level
        function contcr = getCorrectRateForContrast(obj, cont)
            contcr = mean(obj.responseCorrect(obj.contrastSequence(1:obj.currentTrial-1) == cont));
        end
        
        %response rate for a specific contrast level
        function contrr = getResponseRateForContrast(obj, cont)
            contrr = mean(obj.responded(obj.contrastSequence(1:obj.currentTrial-1) == cont));
        end
        
        %print out all of the information
        function [] = printStats(obj)
            disp(strcat('Overall correct rate = ', num2str(obj.getOverallCorrectRate())));
            disp(strcat('Overall response rate = ', num2str(obj.getOverallResponseRate())));
            disp(strcat('Left corect rate = ', num2str(obj.getLeftCorrectRate())));
            disp(strcat('Right correct rate = ', num2str(obj.getRightCorrectRate())));
            disp(strcat('Left response rate = ',  num2str(obj.getLeftResponseRate())));
            disp(strcat('Right response rate = ', num2str(obj.getRightResponseRate())));
            disp(strcat('Left response proportion = ', num2str(obj.getLeftResponseProportion())));
            disp(strcat('Right response proportion = ', num2str(obj.getRightResponseProportion())));
            for c = obj.contrastOptions
                disp(['Correct rate for contrast=' num2str(c) ': ' num2str(obj.getCorrectRateForContrast(c))]);
                disp(['Response rate for contrast=' num2str(c) ': ' num2str(obj.getResponseRateForContrast(c))]);
            end
        end
        
        %get fraction of left responses of a specific interval of trials. Used for bias correction
        function leftProp = getLeftProportionOnInterval(obj,start,last)
            if start < 1 || last > length(obj.joystickResponses)
                leftProp = NaN;
                return;
            end
            lefts = sum(cellfun(@(x)strcmp(x,'Left'),obj.joystickResponses(start:last)));
            rights = sum(cellfun(@(x)strcmp(x,'Right'),obj.joystickResponses(start:last)));
            leftProp = lefts/(lefts + rights);
        end
    end
    
end

