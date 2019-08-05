classdef HardwareIOGen2 < Rig
    properties(Constant)
        leftServoPin = "D9"
        rightServoPin = "D6"
        encoderPinA = "D2"
        encoderPinB = "D3"
        solenoidPin = "D12"
        lickmeterReadPin  = "A2"
        lickmeterPowerPin = "A3"
        breakBeamPin = "D11"
        buttonPin = "A4";
        buttonPowerPin = "A5";
    end
    properties(Access = protected)
        %timer
    end
    methods (Access = public)
        function obj = HardwareIOGen2(port)
            obj.port = port;
            obj.digitalOutputPins = [obj.solenoidPin, obj.lickmeterPowerPin, obj.buttonPowerPin];
            obj.digitalInputPins = [obj.buttonPin];
            obj.analogInputPins = [obj.lickmeterReadPin];
            obj.pullupPins = [];
            obj.lastWaterTime = -1;
            %obj.timer = timer('Name','PinSniffer','BusyMode','Drop','ExecutionMode','fixedSpacing','Period',1,'TimerFcn',{@pollArduinoPins,obj.arduinoBoard}); 
        end
        function obj = Awake(obj)          
            obj.arduinoBoard = arduino(obj.port,'uno','libraries',{'servo','rotaryEncoder'});
            obj.ConfigurePins();            
            
            obj.encoder = rotaryEncoder(obj.arduinoBoard, obj.encoderPinA,obj.encoderPinB);
            writeDigitalPin(obj.arduinoBoard,obj.lickmeterPowerPin,1);%for lickometer
            writeDigitalPin(obj.arduinoBoard,obj.buttonPowerPin,1);%for button
            
            
            obj.leftServo = servo(obj.arduinoBoard,obj.leftServoPin);
            obj.rightServo = servo(obj.arduinoBoard,obj.rightServoPin);
            obj.CloseServos();
        end
         function out = UnsafeReadJoystick(obj)
%              try
                out = readCount(obj.encoder)/obj.maxJoystickValue;
                if abs(out)>1
                    out = sign(out);
                    obj.ResetEnc(out*obj.maxJoystickValue);
                    return;
                end
                if abs(out)<obj.joystickResponseThreshold
                    out = 0;
                    return;
                end 
%              catch e
%                 out = 0;
%                 warning(getReport(e));
%              end
         end
         
         function out = UnsafeReadIR(obj)
             %true -> beam is broken
                configurePin(obj.arduinoBoard,obj.breakBeamPin,'pullup');
               out = ~readDigitalPin(obj.arduinoBoard,obj.breakBeamPin);
               configurePin(obj.arduinoBoard,obj.breakBeamPin,'unset');
         end
        function out = ReadLick(obj)
            out = false;
        end
        function obj = GiveWater(obj,time)
             writeDigitalPin(obj.arduinoBoard,obj.solenoidPin,1);
             if obj.lastWaterTime>0
                 time = time + obj.evaporationConstant*(obj.Game.GetTime() - obj.lastWaterTime);
             end
             obj.lastWaterTime = obj.Game.GetTime();
             obj.DelayedCall('CloseSolenoid',time);
        end
        function obj = CloseSolenoid(obj)
            writeDigitalPin(obj.arduinoBoard,obj.solenoidPin,0);
        end
    end
end