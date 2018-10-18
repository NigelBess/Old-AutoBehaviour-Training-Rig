classdef Results < handle
    %RESULTS results from a series of trials
    %for stimulusposition and joystickresponses:
    %    -1 : left
    %     0 : no choice
    %     1 : right
    
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
            obj.stimSequence = zeros(1,trials);
            obj.contrastOptions = renderer.CONTRAST_OPTIONS;
            obj.contrastSequence = zeros(1,trials);
            obj.joystickResponses = zeros(1,trials);
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
            obj.stimSequence(trialNum) = stimulusPosition;
            obj.contrastSequence(trialNum) = contrastSeq;
            obj.startTimes(trialNum) = startTime;
        end
        function [] = cancelTrial(obj)
            obj.currentTrial = obj.currentTrial-1;
        end
        function [] = LogLeft(obj)
            obj.responseCorrect(obj.currentTrial) = 0;
            obj.joystickResponses(obj.currentTrial) = -1;
            obj.responded(obj.currentTrial) = 1;%true
        end
        
        function [] = LogRight(obj)
           obj.responseCorrect(obj.currentTrial) = 0;
            obj.joystickResponses(obj.currentTrial) = 1;
            obj.responded(obj.currentTrial) = 1;%true
        end
        
        function [] = LogSuccess(obj, time)
            if ~obj.responded(obj.currentTrial)
                obj.responseCorrect(obj.currentTrial) = 1;
                obj.joystickResponses(obj.currentTrial) = obj.stimSequence(obj.currentTrial);
                obj.responded(obj.currentTrial) = 1;%true
            end
            obj.joystickResponseTimes(obj.currentTrial) = time;
        end
        function [] = LogLick(obj, time)
            obj.firstLickTimes(obj.currentTrial) = time;
        end
        function [] = EndTrial(obj,time)
            obj.endTimes(obj.currentTrial) = time;
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
            ocr = mean(obj.responseCorrect(1:obj.currentTrial));
        end
        
        %overall response rate
        function orr = getOverallResponseRate(obj)
            orr = mean(obj.responded(1:obj.currentTrial));
        end
        
        %correct rate for trials with 'Left' stimulus
        function out = getCorrectRate(obj,direction)
            out = obj.meanOfMatching(obj.stimSequence,direction,obj.responseCorrect);
        end
        function out = meanOfMatching(obj,arrayToMatch,direction,arrayOfValues)
             responses = zeros(1,obj.currentTrial);
            n = 0;
            for i = 1:obj.currentTrial
                if arrayToMatch(i) == direction     
                    n = n+1;
                    responses(n) = arrayOfValues(i);
                end
            end
            if n==0
                out = 0;
                return;
            end
            out = sum(responses(1:n))/n;
        end
        
   
        
        %response rate for trials with 'Left' stimulus
        function out = getResponseRate(obj,direction)
            out = obj.meanOfMatching(obj.stimSequence,direction,obj.responded);
        end
        
        
        %fraction of time mouse response to the left (doesn't include no-response trials)
        function out = getResponseProportion(obj,direction)
            responses = obj.joystickResponses(obj.responded==1);
            out = sum(responses==direction)/numel(responses);
        end
        
        %correct rate for a specific contrast level
        function out = getCorrectRateForContrast(obj, cont)
            out = meanOfMatching(obj.contrastSequence,cont,obj.responseCorrect);
        end
        
        %response rate for a specific contrast level
        function out = getResponseRateForContrast(obj, cont)
            out = obj.meanOfMatching(obj.contrastSequence,cont,obj.responded);
        end
        
        %print out all of the information
        function [] = printStats(obj)
            fprintf('Overall correct rate = %f\n', obj.getOverallCorrectRate());
            fprintf('Overall response rate = %f\n', obj.getOverallResponseRate());
            fprintf('Left corect rate = %f\n', obj.getCorrectRate(-1));
            fprintf('Right correct rate = %f\n', obj.getCorrectRate(1));
            fprintf('Left response rate = %f\n',  obj.getResponseRate(-1));
            fprintf('Right response rate = %f\n', obj.getResponseRate(1));
            fprintf('Left response proportion = %f\n', obj.getResponseProportion(-1));
            fprintf('Right response proportion = %f\n', obj.getResponseProportion(1));
            for c = obj.contrastOptions
                disp(['Correct rate for contrast=' num2str(c) ': ' num2str(obj.getCorrectRateForContrast(c))]);
                disp(['Response rate for contrast=' num2str(c) ': ' num2str(obj.getResponseRateForContrast(c))]);
            end
        end
        function [] = shortStats(obj)
            fprintf(int2str(obj.currentTrial) + " games played\n");
            fprintf("Success Rate : %d %%\n",floor(obj.getOverallCorrectRate()*100));
            obj.horizontalLine();
            fprintf("Mouse makes a choice %d %% of the time. \n",floor(obj.getOverallResponseRate()*100));
            fprintf("Mouse chooses left %d %% of the time. \n",floor(obj.getResponseProportion(-1)*100));
            obj.horizontalLine();
            fprintf("On average, the mouse chooses the same direction %.2f times in a row\n",obj.avgStreak());
            fprintf("Chance value for average streak : 2.00\n\n\n");
        end
        function [] = horizontalLine(obj)
            fprintf("---------------------------------\n\n");
        end
        
        %get fraction of left responses of a specific interval of trials. Used for bias correction
        function out = getLeftProportionOnInterval(obj,start,last)
            if start<1
                start = 1;
            end
            if last<=start
                out = obj.joystickResponses(start)==-1;
                return;
            end
            interval = obj.joystickResponses(start:last);
            out = sum(interval==-1)/numel(interval);
        end
        
        function out = avgStreak(obj)
            responses = obj.joystickResponses(1:obj.currentTrial);
            actualResponses = responses(responses~=0);
            directionChanges = zeros(1,numel(actualResponses));
            directionChanges(1) = 1;
            for i = 2:numel(actualResponses)
                if actualResponses(i)~=actualResponses(i-1)
                    directionChanges(i) = 1;
                end
            end
            out = numel(actualResponses)/sum(directionChanges);
%             lastDir = obj.joystickResponses(1);
%             currentStreak = 1;
%             numStreaksComplete = 0;
%             out = 1;
%             for i = 2:obj.currentTrial
%                 if obj.responded(i)
%                     if obj.joystickResponses(i) == lastDir
%                         currentStreak = currentStreak+1;
%                     else
%                         out = (out*numStreaksComplete + currentStreak)/(numStreaksComplete+1);
%                         numStreaksComplete = numStreaksComplete + 1;
%                         currentStreak = 1;
%                         lastDir = obj.joystickResponses(i);
%                     end
%                 end
%             end
        end
    end
    
end

