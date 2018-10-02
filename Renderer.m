classdef Renderer < handle
properties (Constant)
     DISPLAY_SCREEN_NUMBER = 2
     GREY_VALUE = .5
     RING_OUTER = 1000;
     RING_INNER = 750;
     CONTRAST_OPTIONS = [.125 .25 .5 1]
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
        obj.centerPos = [obj.xScreenCenter-obj.stimSize(1)+1, obj.yScreenCenter-obj.stimSize(1)+1, obj.xScreenCenter+obj.stimSize(1), obj.yScreenCenter+obj.stimSize(2)];
    end
    function [] = NewFrame(obj,positions, grating)
    %render grated circle
    Screen('DrawTexture', obj.displayWindow, obj.tex, grating, positions, 0, 0);
    
     %render the ring
    Screen('DrawTexture', obj.displayWindow, obj.ringTex, [], [obj.xScreenCenter-obj.ringSize(1) obj.yScreenCenter-obj.ringSize(1) obj.xScreenCenter+obj.ringSize(1) obj.yScreenCenter+obj.ringSize(1)],0,0);
   
    %not sure why we are flipping the screen
    Screen('Flip',obj.displayWindow);
    end
    function [] = EmptyFrame(obj)
    Screen('FillRect',obj.displayWindow,obj.GREY_VALUE);
    Screen('Flip',obj.displayWindow);
    end
    function initPos = InitialFrame(obj, startOnLeft,grating)
         initPos = [(startOnLeft + 0.5)*obj.xScreenCenter-obj.stimSize(1)+1, obj.yScreenCenter-obj.stimSize(1)+1, (startOnLeft + 0.5)*obj.xScreenCenter+obj.stimSize(1), obj.yScreenCenter+obj.stimSize(2)];
        obj.NewFrame(initPos,grating);
    end
    function bool = CheckLeftHit(obj, pos)
        bool = pos<0;
    end
    function bool = CheckRightHit(obj, pos)
        bool = pos > obj.xScreenCenter*2 - obj.stimSize(1)*2;
    end
    function bool = CheckSuccess(obj,pos)
       bool = abs(pos - obj.centerPos(1)) < obj.stimSize*.25;
    end
end
end