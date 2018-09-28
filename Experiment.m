classdef Experiment < handle
    %EXPERIMENT - Object for a single experiment run in autobehavior rig
    
    %hardware and display objects/parameters
    properties
        arduinoBoard
        leftServo
        rightServo
        encoder
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
        xScreenCenter
        yScreenCenter
        displayWindow
        screenHeight
        screenWidth
    end
    
    %constants
    properties (Constant)
        POSITION_OPTIONS = {'Left', 'Right'}
        CONTRAST_OPTIONS = [.125 .25 .5 1]
        LEFT_SERVO_PIN = 'D5'
        RIGHT_SERVO_PIN = 'D6'
        ENCODER_PIN_A = 'D2'
        ENCODER_PIN_B = 'D3'
        SOLENOID_PIN = 'A0'
        LICKOMETER_READ_PIN  = 'A4'
        LICKOMETER_POWER_PIN = 'A3'
        BEAM_BREAK_PIN = 'A1'
        LEFT_SERVO_OPEN_POS = .5
        RIGHT_SERVO_OPEN_POS = .5
        LEFT_SERVO_CLOSED_POS = 0.0
        RIGHT_SERVO_CLOSED_POS = 1.0
        LEFT_JOYSTICK_RESPONSE_THRESHOLD = -45
        RIGHT_JOYSTICK_RESPONSE_THRESHOLD = 45
        DISPLAY_SCREEN_NUMBER = 2
        GREY_VALUE = .5
        TONE_SAMPLE_FREQUENCY = 12000
        REWARD_TONE_DURATION = .25
        REWARD_TONE_FREQUENCY = 10000
        NOISE_TONE_DURATION = .5
        EVAPORATION_CONSTANT = .15/3600
        WATER_REFILL_INTERVAL = 3600*2
    end
    
    methods
        function obj = Experiment(id, num, port)
            %hardware
            obj.arduinoBoard = arduino(port,'uno','libraries',{'servo','rotaryEncoder'});
            obj.leftServo = servo(obj.arduinoBoard,obj.LEFT_SERVO_PIN);
            obj.rightServo = servo(obj.arduinoBoard,obj.RIGHT_SERVO_PIN);
            obj.encoder = rotaryEncoder(obj.arduinoBoard, obj.ENCODER_PIN_A,obj.ENCODER_PIN_B);
            
            %sound
            obj.rewardTone = MakeTone(obj.REWARD_TONE_DURATION, obj.REWARD_TONE_FREQUENCY, obj.TONE_SAMPLE_FREQUENCY);
            obj.noiseTone = rand(1,floor(0.5*obj.TONE_SAMPLE_FREQUENCY)) - 0.5;

            %Initialize PsychToolbox
            PsychDefaultSetup(2);
            Screen('Preference','SkipSyncTests',1);
            Screen('Preference','VisualDebugLevel',0);
            Screen('Preference','SuppressAllWarnings',1);

            %Color Screen Grey
            [window, windowRect] = PsychImaging('OpenWindow', obj.DISPLAY_SCREEN_NUMBER, obj.GREY_VALUE);

            % Enable alpha blending with proper blend-function. We need it for drawing of our alpha-mask (gaussian aperture):
            Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

            %Get info on window
            [obj.screenWidth, obj.screenHeight] = Screen('WindowSize', window);
            [obj.xScreenCenter, obj.yScreenCenter] = RectCenter(windowRect);
            obj.displayWindow = window;

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
            
            obj.resetEnc();
            writeDigitalPin(obj.arduinoBoard,obj.LICKOMETER_POWER_PIN,1);%for lickometer
            obj.openServos('Center');
            obj.lastWaterTime = -1;
        end
       
        %Open 1 or more servos
        function [] = openServos(obj, dir)
            if strcmp(dir, 'Right')
                obj.leftServo.writePosition(obj.LEFT_SERVO_CLOSED_POS);
                obj.rightServo.writePosition(obj.RIGHT_SERVO_OPEN_POS);
            elseif strcmp(dir, 'Left')
                obj.leftServo.writePosition(obj.LEFT_SERVO_OPEN_POS);
                obj.rightServo.writePosition(obj.RIGHT_SERVO_CLOSED_POS);
            else
                obj.leftServo.writePosition(obj.LEFT_SERVO_OPEN_POS);
                obj.rightServo.writePosition(obj.RIGHT_SERVO_OPEN_POS);
            end
        end
        
        %close both servos
        function [] = closeServos(obj)
                obj.leftServo.writePosition(obj.LEFT_SERVO_CLOSED_POS);
                obj.rightServo.writePosition(obj.RIGHT_SERVO_CLOSED_POS);
        end
        
        %1 = no lick, 0 = licking
        function reading = readLickometer(obj)
               reading = readDigitalPin(obj.arduinoBoard,obj.LICKOMETER_READ_PIN);
        end
        
        %set encoder position to 0
        function [] = resetEnc(obj)
               readCount(obj.encoder,'reset',true);
        end
        
        %read encoder counts
        function n = readEnc(obj)
            n = readCount(obj.encoder);
        end
        
        %determine if joystick is farther left than threshold
        function l = isJoyLeft(obj)
            l = obj.readEnc() < obj.LEFT_JOYSTICK_RESPONSE_THRESHOLD;
        end
        
        %determine if joystick is farther right than threshold
        function r = isJoyRight(obj)
            r = obj.readEnc() > obj.RIGHT_JOYSTICK_RESPONSE_THRESHOLD;
        end
        
        function [] = giveWater(obj, time)
             writeDigitalPin(obj.arduinoBoard,obj.SOLENOID_PIN,1);% solenoid valve opens
             if(obj.lastWaterTime == -1)
                obj.waitAndLog(time);
             else
                 %linearly increasing supplement to combat evaporation in spout
                 time = time + obj.EVAPORATION_CONSTANT*(GetSecs - obj.lastWaterTime);
                 obj.waitAndLog(time);
             end
             writeDigitalPin(obj.arduinoBoard,obj.SOLENOID_PIN,0);% solenoid valve closes
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
            broken = ~readDigitalPin(obj.arduinoBoard,obj.BEAM_BREAK_PIN);
        end
    end
    
end

