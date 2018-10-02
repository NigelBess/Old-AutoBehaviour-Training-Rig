clc
clear all

mouseID = '000';
sessionNum = 1;
%to do: change session num to look for existing files and increment automatically
numTrials = 2;
isTest = false;
port = 'COM4';



 if isTest
    experiment = DummyExperiment(mouseID, sessionNum,port);
    timeout = 2;
    iti = .5;
else
    experiment = RealExperiment(mouseID, sessionNum,port);
    timeout = 60;
    iti = 3;
end
results = Results(mouseID, numTrials ,sessionNum,experiment,'closedLoopTraining');

tiledGratings = zeros(1500,1500*4);
for i = 1:length(experiment.CONTRAST_OPTIONS)
    tiledGratings(:,(i-1)*1500+1:i*1500) = GenerateCircularGrating(750,experiment.CONTRAST_OPTIONS(i));
end
ring = GenerateTargetRing(1000, 750);
ringSize = [120 120];
stimSize = [90 90];
tex = Screen('MakeTexture', experiment.displayWindow, tiledGratings);
ringTex = Screen('MakeTexture', experiment.displayWindow, ring);
centerPos = [experiment.xScreenCenter-stimSize(1)+1 experiment.yScreenCenter-stimSize(1)+1 experiment.xScreenCenter+stimSize(1) experiment.yScreenCenter+stimSize(2)];
experiment.closeServos();
experiment.giveWater(.3);
experiment.playReward()
experiment.waitAndLog(2);
experiment.logEvent('Starting session');
for i = 1:numTrials
    while ~experiment.isBeamBroken()%wait for beam to be broken
        pause(.005)%to do, remove hardcoded time delay 
    end

    experiment.openServos('Center');

    gratingNum = randi([1, length(experiment.CONTRAST_OPTIONS)]);
    results.contrastSequence(i) = experiment.CONTRAST_OPTIONS(gratingNum);
    choice = rand();%used to decied if grated circle starts on the left or right
    rightProb = results.getLeftProportionOnInterval(i-6,i-1);%returns the proportion of left choices from the mouse, over the last 5 trials
    if isnan(rightProb)
        rightProb = .5;
    end 
    if choice < rightProb
        results.stimSequence{i} = 'Right';
    else
        results.stimSequence{i} = 'Left';
    end

    if strcmp(results.stimSequence{i},'Right')%to do: remove string comparison, turn both assignments into a single variable dependent assignment
        initPos = [.5*experiment.xScreenCenter-stimSize(1)+1 experiment.yScreenCenter-stimSize(1)+1 .5*experiment.xScreenCenter+stimSize(1) experiment.yScreenCenter+stimSize(2)];
    else
        initPos = [1.5*experiment.xScreenCenter-stimSize(1)+1 experiment.yScreenCenter-stimSize(1)+1 1.5*experiment.xScreenCenter+stimSize(1) experiment.yScreenCenter+stimSize(2)];
    end
    %not sure why initPos is a vector 4

    pos = initPos;%starting position of the grated circle as determined by the above choice
    gratingSrc = [(gratingNum - 1)*1500+1, 1, gratingNum*1500, 1500];%4 value vector, not sure what this is
    Screen('DrawTexture', experiment.displayWindow, tex, gratingSrc, pos, 0, 0);%rendering grated circle
    
    %render the ring
    Screen('DrawTexture', experiment.displayWindow, ringTex, [], [experiment.xScreenCenter-ringSize(1) experiment.yScreenCenter-ringSize(1) experiment.xScreenCenter+ringSize(1) experiment.yScreenCenter+ringSize(1)],0,0);
   
    %not sure why we are flipping the screen
    Screen('Flip',experiment.displayWindow);

    startRespdisplayWindow = experiment.getExpTime();
    %^ i assume this is the start time of the response window
    %ie when we started rendering
    
    
    results.startTimes(i) = experiment.getExpTime(); %log the time that this trial started
    
    %initialize values
    finished = 0;%boolean    
    hasHit = 0;%boolean
    experiment.logEvent(['Starting Trial ' num2str(i)]);
    
    
    while ~finished && experiment.getExpTime() - startRespdisplayWindow < timeout
        %float reading = reading of mouse input
        if isTest
            reading = (mod(gratingNum,3)-1)*100;%dummy value
        else
            reading = experiment.readEnc();%input from wheel
        end
        vel = (reading-25*sign(reading))*(10/105);%turn reading from wheel into a screen velocity (in pixels/frame maybe?)
        %to do: get rid of hardcoded values
        %to do: convert velocity to units of pixels/time instead of
        %pixels/frame
        
        if abs(reading) < 50%minimum wheel turn required. to do: remove hardcoded value
            vel = 0;
        end

        if pos(1) < 0 % x position to the left of the left edge of the screen
            %(this means the circle has collided with the left edge of th screen)
            vel = max(vel,0);%prevent the circle from moving farther
            results.responseCorrect(i) = 0;%log trial as fail
            if(~hasHit)
                disp('Hit!')
                experiment.logEvent('Hit left side');
            end
            results.joystickResponses{i} = 'Left';
            results.responded(i) = 1;%true
            hasHit = 1;%true
        elseif pos(1) > experiment.xScreenCenter*2 - stimSize(1)*2%check right size hit
            vel = min(vel,0);
            results.responseCorrect(i) = 0;
            if(~hasHit)
                disp('Hit!')
                experiment.logEvent('Hit right side');
            end
            results.joystickResponses{i} = 'Right';
            results.responded(i) = 1;
            hasHit = 1;
        end

        pos = pos + [vel 0 vel 0];%update velocity
        %to do: (CRITICAL!)
        %this part absolutely needs to include some Delta Time to account
        %for speed differences in different computers

        if abs(pos(1) - centerPos(1)) < stimSize*.25%success
            experiment.logEvent('Moved grating to center')
            results.responded(i) = 1;
            results.joystickResponseTimes(i) = experiment.getExpTime();
            if ~hasHit
                results.responseCorrect(i) = 1;
                if strcmp(results.stimSequence{i},'Right')
                    results.joystickResponses{i} = 'Right';
                else
                    results.joystickResponses{i} = 'Left';
                end
            else
                 results.responseCorrect(i) = 0;
            end
            finished = 1;%true
        end
        Screen('DrawTexture', experiment.displayWindow, tex, gratingSrc, pos, 0, 0);
        Screen('DrawTexture', experiment.displayWindow, ringTex, [], [experiment.xScreenCenter-ringSize(1) experiment.yScreenCenter-ringSize(1) experiment.xScreenCenter+ringSize(1) experiment.yScreenCenter+ringSize(1)],0,0)
        Screen('Flip',experiment.displayWindow);
        experiment.logData();
    end %end while
    
    %at this point the mouse has completed or timed out the current trial

    experiment.closeServos()
    experiment.waitAndLog(1);%see what the wheel is doing while the servos close.
    %^ to do: remove hardcoded value

    if finished % the mouse successfully completed the trial (didnt time out)
        experiment.playReward();
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
        experiment.waitAndLog(1);
    end
    Screen('FillRect',experiment.displayWindow,experiment.GREY_VALUE);
    Screen('Flip',experiment.displayWindow);
    results.endTimes(i) = experiment.getExpTime();
    experiment.logEvent(['Ending Trial ' num2str(i)]);
    experiment.refillWater(.03)
    experiment.waitAndLog(iti/2);
    experiment.resetEnc();
    experiment.waitAndLog(iti/2);
    results.numTrials = i;
    disp(i)
    results.save()
end %end for 1:numtrials