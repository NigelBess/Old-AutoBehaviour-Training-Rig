classdef RealExperiment < Experiment
    %EXPERIMENT - Object for a single experiment run in autobehavior rig
    
    %hardware and display objects/parameters
    properties
        arduinoBoard
        leftServo
        rightServo
        encoder
        outsideOfRange;
    end
    
    %constants
    properties (Constant)
        LEFT_SERVO_PIN = "D9"
        RIGHT_SERVO_PIN = "D6"
        ENCODER_PIN_A = "D2"
        ENCODER_PIN_B = "D3"
        SOLENOID_PIN = "D12"
        LICKMETER_READ_PIN  = "A2"
        LICKMETER_POWER_PIN = "A3"
        BEAM_BREAK_PIN = "D11"
        BUTTON_PIN = "A4";
        BUTTON_POWER_PIN = "A5";
        LEFT_SERVO_OPEN_POS = 0.4
        RIGHT_SERVO_OPEN_POS = 0.6
        LEFT_SERVO_CLOSED_POS = 0
        RIGHT_SERVO_CLOSED_POS = 1
        JOYSTICK_RESPONSE_THRESHOLD = 20
        MAX_JOYSTICK_VALUE = 100
        SERVO_ADJUSTMENT_TIME = 0.5
    end
    
    methods
        function obj = RealExperiment(port)
            %hardware
            
            obj.arduinoBoard = arduino(port,'uno','libraries',{'servo','rotaryEncoder'});
            
            digitalOutputPins = [obj.SOLENOID_PIN, obj.LICKMETER_POWER_PIN, obj.BUTTON_POWER_PIN];
            for pin = digitalOutputPins
                configurePin(obj.arduinoBoard,pin,'DigitalOutput');
            end
            
            digitalInputPins = [obj.BUTTON_PIN,obj.BEAM_BREAK_PIN];
            for pin = digitalInputPins
                configurePin(obj.arduinoBoard,pin,'DigitalInput')
            end
            
            analogInputPins = [obj.LICKMETER_READ_PIN];
            for pin = analogInputPins
                configurePin(obj.arduinoBoard,pin,'AnalogInput')
            end
            
            pullupPins = [];
            for pin = pullupPins
                configurePin(obj.arduinoBoard,pin,'pullup')
            end
            
            
            obj.encoder = rotaryEncoder(obj.arduinoBoard, obj.ENCODER_PIN_A,obj.ENCODER_PIN_B);
            writeDigitalPin(obj.arduinoBoard,obj.LICKMETER_POWER_PIN,1);%for lickometer
            writeDigitalPin(obj.arduinoBoard,obj.BUTTON_POWER_PIN,1);%for button
            
            
            obj.leftServo = servo(obj.arduinoBoard,obj.LEFT_SERVO_PIN);
            obj.rightServo = servo(obj.arduinoBoard,obj.RIGHT_SERVO_PIN);
            obj.closeServos();
            obj.lastWaterTime = -1;
        end
       
        %Open 1 or more servos
        function [] = openServos(obj)
            obj.positionServos(obj.LEFT_SERVO_OPEN_POS,obj.RIGHT_SERVO_OPEN_POS);               
        end
        function [] = openSide(obj,side)
            if side>0
                obj.positionServos(obj.LEFT_SERVO_OPEN_POS,obj.RIGHT_SERVO_CLOSED_POS);
            else
                obj.positionServos(obj.LEFT_SERVO_CLOSED_POS,obj.RIGHT_SERVO_OPEN_POS);
            end
            obj.resetEnc(0);
        end
        function [] = openLeftServo(obj)
            obj.positionServos(obj.LEFT_SERVO_OPEN_POS,obj.RIGHT_SERVO_CLOSED_POS);       
        end
        function [] = openRightServo(obj)
            obj.positionServos(obj.LEFT_SERVO_CLOSED_POS,obj.RIGHT_SERVO_OPEN_POS);       
        end
        function [] = positionServos(obj,left,right)
                obj.leftServo.writePosition(left);
               
                obj.rightServo.writePosition(right);
                 pause(obj.SERVO_ADJUSTMENT_TIME);
        end
        
        %close both servos
        function [] = closeServos(obj)
                obj.positionServos(obj.LEFT_SERVO_CLOSED_POS,obj.RIGHT_SERVO_CLOSED_POS);
                obj.resetEnc(0);
                obj.outsideOfRange = false;
        end
        
        %1 = no lick, 0 = licking
        function out = isLicking(obj)
               out = ~readDigitalPin(obj.arduinoBoard,obj.LICKMETER_READ_PIN);
        end
        
        %set encoder position to 0
        function [] = resetEnc(obj,value)
               resetCount(obj.encoder,value);
        end
        
        %read encoder counts
        function n = readEnc(obj)
            n = readCount(obj.encoder);
            if abs(n)>obj.MAX_JOYSTICK_VALUE
                n = obj.MAX_JOYSTICK_VALUE*sign(n);
                    obj.resetEnc(obj.MAX_JOYSTICK_VALUE*sign(n));
                return;
            end
            if abs(n)<obj.JOYSTICK_RESPONSE_THRESHOLD
                n = 0;
                return;
            end
            
        end
        
        %determine if joystick is farther left than threshold
        function l = isJoyLeft(obj)
            l = obj.readEnc() < -obj.JOYSTICK_RESPONSE_THRESHOLD;
        end
        
        %determine if joystick is farther right than threshold
        function r = isJoyRight(obj)
            r = obj.readEnc() > obj.JOYSTICK_RESPONSE_THRESHOLD;
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
            lick = obj.isLicking();
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
                %obj.logData();
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
        function out = isButtonPressed(obj)
            out = ~readDigitalPin(obj.arduinoBoard,obj.BUTTON_PIN);
        end
    end
    
end

