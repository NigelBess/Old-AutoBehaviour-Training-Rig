classdef Renderer < handle
properties (Constant)
     DISPLAY_SCREEN_NUMBER = 2
     GREY_VALUE = .5
     RING_OUTER = 1000;
     RING_INNER = 750;
     CONTRAST_OPTIONS = [1]
     %CONTRAST_OPTIONS = [.125 .25 .5 1]
     %CONTACT_THRESHOLD = 10;
end
properties
    ring
    tiledGratings
    ringSize
    stimSize
    tex
    ringTex
    centerPos
        xScreenCenter
        yScreenCenter
        displayWindow
        screenHeight
        screenWidth
        gratingSrc
        currentContrast
end
methods
    function obj = Renderer()
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
            
            
            
            
        obj.ring  = GenerateTargetRing(obj.RING_OUTER,obj.RING_INNER);
        obj.tiledGratings = zeros(1500,1500*4);
        for i = 1:length(obj.CONTRAST_OPTIONS)
            obj.tiledGratings(:,(i-1)*1500+1:i*1500) = GenerateCircularGrating(750,obj.CONTRAST_OPTIONS(i));
        end
        obj.ringSize = [120 120];
        obj.stimSize = [90 90];
        obj.tex = Screen('MakeTexture', obj.displayWindow, obj.tiledGratings);
        obj.ringTex = Screen('MakeTexture', obj.displayWindow, obj.ring);
        obj.centerPos = obj.Center();
    end
    function gratingNum = GenerateGrating(obj)
        gratingNum = randi([1, length(obj.CONTRAST_OPTIONS)]);
        obj.currentContrast = obj.CONTRAST_OPTIONS(gratingNum);
        obj.gratingSrc = [(gratingNum - 1)*1500+1, 1, gratingNum*1500, 1500];%4 value vector, not sure what this is
    end
    function [] = NewFrame(obj,positions)
    %render grated circle
    Screen('DrawTexture', obj.displayWindow, obj.tex, obj.gratingSrc, positions, 0, 0);
    
     %render the ring
    Screen('DrawTexture', obj.displayWindow, obj.ringTex, [], [obj.xScreenCenter-obj.ringSize(1) obj.yScreenCenter-obj.ringSize(1) obj.xScreenCenter+obj.ringSize(1) obj.yScreenCenter+obj.ringSize(1)],0,0);
   
    %not sure why we are flipping the screen
    Screen('Flip',obj.displayWindow);
    end
    function [] = EmptyFrame(obj)
    Screen('FillRect',obj.displayWindow,obj.GREY_VALUE);
    Screen('Flip',obj.displayWindow);
    end
    function initPos = InitialFrame(obj, startOnLeft)
         initPos = obj.InitPos(startOnLeft);
        obj.NewFrame(initPos);
    end
    function out = InitPos(obj,startOnLeft)
        out = [(startOnLeft + 0.5)*obj.xScreenCenter-obj.stimSize(1)+1, obj.yScreenCenter-obj.stimSize(1)+1, (startOnLeft + 0.5)*obj.xScreenCenter+obj.stimSize(1), obj.yScreenCenter+obj.stimSize(2)];
    end
    function bool = CheckLeftHit(obj, pos)
        bool = pos(1)<=(obj.LeftSide());
    end
    function bool = CheckRightHit(obj, pos)
        bool = pos(1) >= (obj.RightSide()-2*obj.stimSize);
    end
    function bool = CheckSuccess(obj,pos)
       bool = abs(pos(1) - obj.centerPos(1)) < obj.stimSize*.25;
    end
    function rightSide = RightSide(obj)
        rightSide = obj.xScreenCenter*2;
    end
    function out = Center(obj)
        out = [obj.xScreenCenter-obj.stimSize(1)+1, obj.yScreenCenter-obj.stimSize(1)+1, obj.xScreenCenter+obj.stimSize(1), obj.yScreenCenter+obj.stimSize(2)];
    end
    function leftSide = LeftSide(obj)
        leftSide = 0;
    end
    function out = ToRight(obj)
        out = obj.InitPos(0);
        out(1) = obj.RightSide()-2*obj.stimSize(1);
        out(3) = obj.RightSide();
    end
    function out = ToLeft(obj)
        out = obj.InitPos(0);
        out(1) = obj.LeftSide();
        out(3) = 2*obj.stimSize(1);
    end
end
end