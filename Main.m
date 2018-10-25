clc
clear all
lastFrameTime = 0;
maxVelocity = 250;
timeout = 20;


mouseID = '000';
sessionNum = 3;
%to do: change session num to look for existing files and increment automatically
numTrials = 100;
port = 'COM3';





    experiment = RealExperiment(port);
    
    
 
renderer = Renderer();
results = Results(mouseID, numTrials ,sessionNum,experiment,renderer,'closedLoopTraining');





experiment.closeServos();
experiment.playReward()
%experiment.waitAndLog(2);
%experiment.logEvent('Starting session');
velocitySensitivity = maxVelocity/experiment.MAX_JOYSTICK_VALUE;

lastFrameTime = GetSecs();
buttonPressed = false;
clc;
for i = 1:numTrials

    while ~experiment.isBeamBroken()
        if (experiment.isButtonPressed)
           buttonPressed = true;
           break;
        end
    end
    if (experiment.isButtonPressed)
           buttonPressed = true;
           break;
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
    results.StartTrial(stimPosition,renderer.currentContrast,experiment.getExpTime());
    
    %initialize values
    finished = 0;%boolean    
    hasHit = 0;%boolean
   % experiment.logEvent(['Starting Trial ' num2str(i)]);
   
    vel = 0;
    time = experiment.getExpTime();
    while ~finished && time - startRespdisplayWindow < timeout
        time = experiment.getExpTime();
        if (experiment.isButtonPressed)
           buttonPressed = true;
           break;
        end
        reading = experiment.readEnc();%input from wheel
        results.LogFrame(reading,-1,time);
        vel = (reading)*velocitySensitivity;
        if abs(vel)>maxVelocity
            vel = maxVelocity*sign(vel);
        end
         
        pos = movePos(pos,vel*(GetSecs()-lastFrameTime));%update position
        if renderer.CheckLeftHit(pos) % x position to the left of the left edge of the screen
            pos = renderer.ToLeft();
            vel = 0;%prevent the circle from moving farther
            results.LogLeft();%log trial as hitting left wall
            if(~hasHit)%has Hit is used to prevent repeated noise when hitting the wall during the same trial
                %also hasHit prevents logging trial as a success if mouse
                %has already failed
               experiment.playNoise();
               % experiment.logEvent('Hit left side');
            end
            hasHit = 1;%true
        elseif renderer.CheckRightHit(pos)% %check right size hit
            pos = renderer.ToRight();
            vel = 0;
            if(~hasHit)
                experiment.playNoise();
                %experiment.logEvent('Hit right side');
            end
            results.LogRight();
            hasHit = 1;
            
        end
        if renderer.CheckSuccess(pos)%success
            experiment.playReward();
            pos = renderer.centerPos;
            vel = 0;
            %experiment.logEvent('Moved grating to center')
            results.LogSuccess(experiment.getExpTime());
            finished = 1;%true
        end
        
        renderer.NewFrame(pos);
        
        
        
       


        
        
        
       % experiment.logData();
        lastFrameTime = GetSecs();
    end %end while
    experiment.closeServos();
    clc;
    
    if (buttonPressed)
        results.cancelTrial();
        results.shortStats();
        break;
    end
    
    %at this point the mouse has completed or timed out the current trial

    experiment.closeServos()

    if finished % the mouse successfully completed the trial (didnt time out)
        
        startLickdisplayWindow = experiment.getExpTime();%log the time that the reward stimulus started
        while experiment.getExpTime() - startLickdisplayWindow < .5% mouse has a 0.5 second window to lick the lickmeter
            %^ to do: remove hardcode
           % experiment.logData();
           results.LogFrame(experiment.readEnc(),experiment.isLicking(),experiment.getExpTime());
            if(experiment.isLicking())
                results.firstLickTimes(results.sessionNum) = experiment.getExpTime();%we want to log the time of lick to see if the mouse was anticipating the water
                %if the mouse doesn't lick within this while loop,
                %fistlicktimes retains its default value of -1 (used as a null)
                break;
            end
           % pause(.005);%to do: remove hardcode
        end
        results.EndTrial(experiment.getExpTime());
        experiment.giveWater(.15);%to do: remove hardcode
    else
        if (experiment.isBeamBroken())
            experiment.playNoise();
            results.EndTrial(experiment.getExpTime());
        else
            results.cancelTrial();
        end
        
    end 
    results.shortStats();
    renderer.EmptyFrame();
    
    %experiment.logEvent(['Ending Trial ' num2str(i)]);
    experiment.refillWater(.03)
    results.save()
end %end for 1:numtrials
sca;
function out = movePos(original, offset)
    out = original;
    out = out + [offset, 0, offset, 0];
end




