classdef DummyExperiment < Experiment
    %DummyExperiment - Substitue for Experiment.m that allows for testing
    %of stimulus code without an arduino
    

    

    
    methods
        function obj = DummyExperiment(id, num, port)
            obj = obj@Experiment(id,num,port);
            
            obj.resetEnc();
            obj.openServos('Center');
            obj.lastWaterTime = -1;
        end
       
        %Open 1 or more servos
        function [] = openServos(obj, dir)
            disp('openning servos')
        end
        
        %close both servos
        function [] = closeServos(obj)
                disp('closing servos');
        end
        
        %1 = no lick, 0 = licking
        function reading = readLickometer(obj)
               reading = 0;
        end
        
        %set encoder position to 0
        function [] = resetEnc(obj)
               disp('encoder reset');
        end
        
        %read encoder counts (changes periodically to allow exploration of different responses)
        function n = readEnc(obj)
            x = mod(floor(GetSecs()/10),3);
            if x == 0
                n = 100;
            elseif x == 1
                n = -100;
            else
                n = 0;
            end
        end
        
        %determine if joystick is farther left than threshold
        function l = isJoyLeft(obj)
            l = 1;
        end
        
        %determine if joystick is farther right than threshold
        function r = isJoyRight(obj)
            r = 1;
        end
        
        function [] = giveWater(obj, time)
             disp('Drink Up');
             obj.lastWaterTime = GetSecs();
        end
      
        %Dispense water automatically after a certain about of time to prevent evap
        function [] = refillWater(obj, time)
            if GetSecs - obj.lastWaterTime > obj.WATER_REFILL_INTERVAL
                obj.giveWater(time)
            end
        end
        
        %time since experiment initalization
        function t = getExpTime(obj)
            t = GetSecs - obj.globalStart;
        end
        
        %write measured values to csv
        function [] = logData(obj)
            count = obj.readEnc();
            lick = obj.readLickometer();
            timestamp = obj.getExpTime();
            data = [count lick timestamp];
            dlmwrite(obj.csvFilename,data,'delimiter',',','precision',9,'-append');
        end
        
        %log an arbitrary event string
        function [] = logEvent(obj,eventstr)
            eventfid = fopen(obj.eventFilename,'a');
            fprintf(eventfid,[num2str(obj.getExpTime) ': ' eventstr '\n']);
            fclose(eventfid);
        end
        
        %pause the experiment while continuing to log data
        function [] = waitAndLog(obj, time)
            startWait = GetSecs;
            while GetSecs - startWait < time
                WaitSecs(.05);
                obj.logData();
            end
        end
        
        %play reward tone
        function [] = playReward(obj)
            sound(obj.rewardTone,obj.TONE_SAMPLE_FREQUENCY);
        end
        
        %play white noise tone
        function [] = playNoise(obj)
            sound(obj.noiseTone, obj.TONE_SAMPLE_FREQUENCY);
        end
        
        %determine wheather IR beam is broken by mouse
        function broken = isBeamBroken(obj)
            broken = 1;
        end
    end
    
end



