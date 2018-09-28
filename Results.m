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
    end
    
    methods
        function obj = Results(id, num)
            %empty buffers for data logging
            obj.dateTime = -1;
            obj.globalStart = -1;
            obj.startTimes = [];
            obj.stimSequence = {};
            obj.contrastOptions = [];
            obj.contrastSequence = [];
            obj.joystickResponses = {};
            obj.joystickResponseTimes = [];
            obj.joystickCounts = [];
            obj.responseCorrect = [];
            obj.responded = [];
            obj.firstLickTimes = [];
            obj.numTrials = 1;
            obj.trialType ="";
            obj.mouseID = id;
            obj.sessionNum = num;
            
            %save directory
            obj.sessionID = [datestr(date, 'mmddyy') '_' num2str(obj.sessionNum)];
            obj.saveDir = strcat('./', obj.mouseID, '_', obj.sessionID);
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
            ocr = mean(obj.responseCorrect);
        end
        
        %overall response rate
        function orr = getOverallResponseRate(obj)
            orr = mean(obj.responded);
        end
        
        %correct rate for trials with 'Left' stimulus
        function lcr = getLeftCorrectRate(obj)
            lcr = mean(obj.responseCorrect(cellfun(@(x)strcmp(x,'Left'),obj.stimSequence(1:obj.numTrials))));
        end
        
        %correct rate for trials with 'Right' stimulus
        function rcr = getRightCorrectRate(obj)
            rcr = mean(obj.responseCorrect(cellfun(@(x)strcmp(x,'Right'),obj.stimSequence(1:obj.numTrials))));
        end
        
        %response rate for trials with 'Left' stimulus
        function lrr = getLeftResponseRate(obj)
            lrr = mean(obj.responded(cellfun(@(x)strcmp(x,'Left'),obj.stimSequence(1:obj.numTrials))));
        end
        
        %response rate for trials with 'Right' stimulus
        function rrr = getRightResponseRate(obj)
            rrr = mean(obj.responded(cellfun(@(x)strcmp(x,'Right'),obj.stimSequence(1:obj.numTrials))));
        end
        
        %fraction of time mouse response to the left (doesn't include no-response trials)
        function lrp = getLeftResponseProportion(obj)
            lrp = mean(cellfun(@(x)strcmp(x,'Left'),obj.joystickResponses(logical(obj.responded))));
        end
        
        %fraction of time mouse response to the right (doesn't include no-response trails)
        function rrp = getRightResponseProportion(obj)
            rrp = mean(cellfun(@(x)strcmp(x,'Right'),obj.joystickResponses(logical(obj.responded))));
        end
        
        %correct rate for a specific contrast level
        function contcr = getCorrectRateForContrast(obj, cont)
            contcr = mean(obj.responseCorrect(obj.contrastSequence == cont));
        end
        
        %response rate for a specific contrast level
        function contrr = getResponseRateForContrast(obj, cont)
            contrr = mean(obj.responded(obj.contrastSequence == cont));
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

