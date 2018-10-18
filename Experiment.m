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
        lastWaterTime
        dateTime
        globalStart
        rewardTone
        noiseTone

    end
    methods
        function obj =  Experiment()
                        %sound
            obj.rewardTone = MakeTone(obj.REWARD_TONE_DURATION, obj.REWARD_TONE_FREQUENCY, obj.TONE_SAMPLE_FREQUENCY);
            obj.noiseTone = rand(1,floor(0.5*obj.TONE_SAMPLE_FREQUENCY)) - 0.5;
            obj.globalStart = GetSecs();
            obj.dateTime = now();
        end
    end
end

