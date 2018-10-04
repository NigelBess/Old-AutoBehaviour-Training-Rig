classdef RealExperiment < Experiment
    %EXPERIMENT - Object for a single experiment run in autobehavior rig
    
    %hardware and display objects/parameters
    properties
        arduinoBoard
        leftServo
        rightServo
        encoder
    end
    
    %constants
    properties (Constant)
        LEFT_SERVO_PIN = 'D9'
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
    end
    
    methods
        function obj = RealExperiment(id, num, port)
            obj = obj@Experiment(id,num,port);
            %hardware
            obj.arduinoBoard = arduino(port,'uno','libraries',{'servo','rotaryEncoder'});
            obj.leftServo = servo(obj.arduinoBoard,obj.LEFT_SERVO_PIN);
            obj.rightServo = servo(obj.arduinoBoard,obj.RIGHT_SERVO_PIN);
            obj.encoder = rotaryEncoder(obj.arduinoBoard, obj.ENCODER_PIN_A,obj.ENCODER_PIN_B);
            

            
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

