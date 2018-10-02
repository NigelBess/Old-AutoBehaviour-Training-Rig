classdef Experiment < GameObject
    %hardware and display objects/parameters
        %constants
    properties (Constant)
        POSITION_OPTIONS = {'Left', 'Right'}
        
       
        TONE_SAMPLE_FREQUENCY = 12000
        REWARD_TONE_DURATION = .25
        REWARD_TONE_FREQUENCY = 10000
        NOISE_TONE_DURATION = .5
        EVAPORATION_CONSTANT = .15/3600
        WATER_REFILL_INTERVAL = 3600*2
    end
    
    properties
        mouseID
        sessionNum
        sessionID
        saveDir
        csvFilename
        eventFilename
        lastWaterTime
        dateTime
        globalStart
        rewardTone
        noiseTone

    end
    methods
        function obj =  Experiment(id,num,port)
                        %sound
            obj.rewardTone = MakeTone(obj.REWARD_TONE_DURATION, obj.REWARD_TONE_FREQUENCY, obj.TONE_SAMPLE_FREQUENCY);
            obj.noiseTone = rand(1,floor(0.5*obj.TONE_SAMPLE_FREQUENCY)) - 0.5;

           

            %Mouse and Session Info
            obj.mouseID = id;
            obj.sessionNum = num;
            obj.sessionID = [datestr(date, 'mmddyy') '_' num2str(obj.sessionNum)];
            
            %create save directory
            obj.saveDir = strcat('./', obj.mouseID, '_', obj.sessionID);
            mkdir(obj.saveDir);
            
            %csv log file
            obj.csvFilename = strcat(obj.saveDir, '/', obj.mouseID, '_', obj.sessionID, '.csv');
            csvHeaders = {'Encoder Reading', 'Lickometer', 'Timestamp'};
            csvfid = fopen(obj.csvFilename, 'w') ;
            fprintf(csvfid, '%s,', csvHeaders{1,1:end-1}) ;
            fprintf(csvfid, '%s\n', csvHeaders{1,end}) ;
            fclose(csvfid);
            
            %text-based event file (for redundant logging)
            obj.eventFilename = strcat(obj.saveDir, '/', obj.mouseID, '_', obj.sessionID, '_events', '.txt');

            obj.globalStart = GetSecs();
            obj.dateTime = now();
        end
    end
end

