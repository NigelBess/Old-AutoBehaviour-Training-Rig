clc
clear all
maxVelocity = 250;
timeout = 20;


requestInput;
mailRecipient = "kevin.sit@lifesci.ucsb.edu";

waterGiveTime = 0.01;%s
        

experiment = RealExperiment(port);
    
    
 
renderer = Renderer(screenNum);
results = Results(mouseID, numTrials ,sessionNum,experiment,'closedLoopTraining');
results.setContrastOptions(renderer);





experiment.closeServos();
experiment.playReward()
%experiment.waitAndLog(2);
%experiment.logEvent('Starting session');
velocitySensitivity = maxVelocity/experiment.MAX_JOYSTICK_VALUE;


buttonPressed = false;
clc;
try
for i = 1:numTrials
    
     if (experiment.isButtonPressed)
           buttonPressed = true;
           break;
    end
    while ~experiment.isBeamBroken() && ~buttonPressed
        buttonPressed = experiment.isButtonPressed;
    end
    if(buttonPressed)
        break;
    end
    

    choice = rand();%used to decied if grated circle starts on the left or right
    bias = results.getLeftProportionOnInterval(5);
    rightProb = bias;%returns the proportion of left choices, over the last 5 trials
   fprintf("%d\n",bias);
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
    
    pos = renderer.InitialFrame(startingOnLeft);
    time = experiment.getExpTime();
    lastFrameTime = GetSecs();
    experiment.openServos();
    while ~finished && (time - startRespdisplayWindow < timeout) && ~(hasHit && ~reward)
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
            experiment.giveWater(waterGiveTime);
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
                results.LogLick(GetSecs()-startLickdisplayWindow);%we want to log the time of lick to see if the mouse was anticipating the water
                %if the mouse doesn't lick within this while loop,
                %fistlicktimes retains its default value of -1 (used as a null)
                %
                break;
            end
           % pause(.005);%to do: remove hardcode
        end
        results.EndTrial(experiment.getExpTime());
        experiment.giveWater(waterGiveTime/5);%to do: remove hardcode
    else
        if (experiment.isBeamBroken())
            experiment.playNoise();
            results.EndTrial(experiment.getExpTime());
            renderer.EmptyFrame();
            pause(2);
        else
            results.cancelTrial();
        end
        
    end 
    results.shortStats();
    renderer.EmptyFrame();
    
    %experiment.logEvent(['Ending Trial ' num2str(i)]);
    experiment.refillWater(.001)
    results.save()
end %end for 1:numtrials
catch
    msg = "Something went wrong with rig "+string(rig)+". Mouse "+string(mouseID) + " is no longer training.";
    subject = "Autobehaviour ERROR: rig "+string(rig)+" mouse "+string(mouseID);
    matlabmail(mailRecipient,msg,subject);
end
if i ==numTrials
    msg = "Mouse "+string(mouseID) +" on rig " + string(rig) + " has completed all " + string(numTrials) + " trials.";
    subject = "Autobehaviour Success: rig "+string(rig)+" mouse "+string(mouseID);
    matlabmail(mailRecipient,msg,subject);
end
sca;
function out = movePos(original, offset)
    out = original;
    out = out + [offset, 0, offset, 0];
end




