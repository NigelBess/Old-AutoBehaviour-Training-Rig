clc
clear all
lastFrameTime = 0;
maxVelocity = 500;
timeout = 20;


mouseID = '000';
sessionNum = 1;
%to do: change session num to look for existing files and increment automatically
numTrials = 100;
isTest = false;
port = 'COM4';





    experiment = RealExperiment(mouseID, sessionNum,port);
    
 
renderer = Renderer();
results = Results(mouseID, numTrials ,sessionNum,experiment,renderer,'closedLoopTraining');





experiment.closeServos();
experiment.playReward()
%experiment.waitAndLog(2);
experiment.logEvent('Starting session');
velocitySensitivity = maxVelocity/experiment.MAX_JOYSTICK_VALUE;

lastFrameTime = GetSecs();
buttonPressed = false;
clc;
for i = 1:numTrials

    while ~experiment.isBeamBroken()%wait for beam to be broken
        pause(.005)%to do, remove hardcoded time delay 
    end

    experiment.openServos();

    
    choice = rand();%used to decied if grated circle starts on the left or right
    rightProb = results.getLeftProportionOnInterval(i-6,i-1);%returns the proportion of left choices, over the last 5 trials
   %^ to do: remove hardcode
   if isnan(rightProb)
        rightProb = .5;
    end 
    startingOnLeft = choice > rightProb;
    if startingOnLeft
        stimPosition = -1;
    else
        stimPosition = 1;
    end
    
   gratingNum = renderer.GenerateGrating();
   pos = renderer.InitialFrame(startingOnLeft);



    startRespdisplayWindow = experiment.getExpTime();
    %^ i assume this means the start time of the response window
    %ie when we started rendering
    
    %log information about the start of the trial
    results.StartTrial(i,stimPosition,renderer.currentContrast,experiment.getExpTime());
    
    %initialize values
    finished = 0;%boolean    
    hasHit = 0;%boolean
    experiment.logEvent(['Starting Trial ' num2str(i)]);
   
    
   % buttonHandle = uicontrol
    
    while ~finished && experiment.getExpTime() - startRespdisplayWindow < timeout
        if (experiment.isButtonPressed)
          %  buttonPressed = true;
           % break;
        end
        %float reading = reading of mouse input
        if isTest
            reading = (mod(gratingNum,3)-1)*100;%dummy value
        else
            reading = experiment.readEnc();%input from wheel
        end
        vel = (reading)*velocitySensitivity;
        if abs(vel)>maxVelocity
            vel = maxVelocity*sign(vel);
        end
        %vel = (reading-25*sign(reading))*(10/105);%turn reading from wheel into a screen velocity (in pixels/frame maybe?)
        %to do: get rid of hardcoded values
        %to do: convert velocity to units of pixels/time instead of
        %pixels/frame
        
%         if abs(reading) < 50%minimum wheel turn required. to do: remove hardcoded value
%             vel = 0;
%         end

        if renderer.CheckLeftHit(pos) % x position to the left of the left edge of the screen
            
            pos = renderer.ToLeft();
            %(this means the circle has collided with the left edge of th screen)
            vel = max(vel,0);%prevent the circle from moving farther
            results.LogLeft();%log trial as hitting left wall
            if(~hasHit)%has Hit is used to prevent repeated noise when hitting the wall during the same trial
                %also hasHit prevents logging trial as a success if mouse
                %has already failed
                experiment.playNoise();
                experiment.logEvent('Hit left side');
            end
            hasHit = 1;%true
        elseif renderer.CheckRightHit(pos)% %check right size hit
            pos = renderer.ToRight();
            vel = min(vel,0);
            if(~hasHit)
                experiment.playNoise();
                experiment.logEvent('Hit right side');
            end
            results.LogRight();
            hasHit = 1;
            
        end
        if renderer.CheckSuccess(pos)%success
            experiment.playReward();
            pos = renderer.centerPos;
            experiment.logEvent('Moved grating to center')
            results.LogSuccess(experiment.getExpTime());
            finished = 1;%true
        end
        
        renderer.NewFrame(pos);
        
         pos = movePos(pos,vel*(GetSecs()-lastFrameTime));%update position
       


        
        
        
        experiment.logData();
        lastFrameTime = GetSecs();
    end %end while
    experiment.closeServos();
    clc;
    results.shortStats();
    if (buttonPressed)
        break;
    end
    
    %at this point the mouse has completed or timed out the current trial

    experiment.closeServos()

    if finished % the mouse successfully completed the trial (didnt time out)
        
        startLickdisplayWindow = experiment.getExpTime();%log the time that the reward stimulus started
        while experiment.getExpTime() - startLickdisplayWindow < .5% mouse has a 0.5 second window to lick the lickmeter
            %^ to do: remove hardcode
            experiment.logData();
            if(experiment.readLickometer() == 0)%returns zero while mouse is licking
                results.firstLickTimes(results.sessionNum) = experiment.getExpTime();%we want to log the time of lick to see if the mouse was anticipating the water
                %if the mouse doesn't lick within this while loop,
                %fistlicktimes retains its default value of -1 (used as a null)
                break;
            end
            pause(.005);%to do: remove hardcode
        end
        experiment.giveWater(.15);%to do: remove hardcode
    else
        experiment.playNoise();
    end
    renderer.EmptyFrame();
    results.EndTrial(experiment.getExpTime());
    experiment.logEvent(['Ending Trial ' num2str(i)]);
    experiment.refillWater(.03)
    results.save()
end %end for 1:numtrials
sca;
function out = movePos(original, offset)
    out = original;
    out = out + [offset, 0, offset, 0];
end




