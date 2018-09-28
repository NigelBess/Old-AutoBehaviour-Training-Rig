clc
clear all

mouseID = '000';
sessionNum = 0;
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
results = Results(mouseID, sessionNum);
results.globalStart = experiment.globalStart;
results.dateTime = experiment.dateTime;
results.numTrials = 0;
results.trialType = 'closedLoopTraining';
results.contrastOptions = experiment.CONTRAST_OPTIONS;

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
    while ~experiment.isBeamBroken()
        pause(.005)
    end

    experiment.openServos('Center');

    gratingNum = randi([1, length(experiment.CONTRAST_OPTIONS)]);
    results.contrastSequence(i) = experiment.CONTRAST_OPTIONS(gratingNum);
    choice = rand();
    rightProb = results.getLeftProportionOnInterval(i-6,i-1);
    if isnan(rightProb)
        rightProb = .5;
    end 
    if choice < rightProb
        results.stimSequence{i} = 'Right';
    else
        results.stimSequence{i} = 'Left';
    end

    if strcmp(results.stimSequence{i},'Right')
        initPos = [.5*experiment.xScreenCenter-stimSize(1)+1 experiment.yScreenCenter-stimSize(1)+1 .5*experiment.xScreenCenter+stimSize(1) experiment.yScreenCenter+stimSize(2)];
    else
        initPos = [1.5*experiment.xScreenCenter-stimSize(1)+1 experiment.yScreenCenter-stimSize(1)+1 1.5*experiment.xScreenCenter+stimSize(1) experiment.yScreenCenter+stimSize(2)];
    end

    pos = initPos;
    gratingSrc = [(gratingNum - 1)*1500+1 1 gratingNum*1500 1500];
    Screen('DrawTexture', experiment.displayWindow, tex, gratingSrc, pos, 0, 0);
    Screen('DrawTexture', experiment.displayWindow, ringTex, [], [experiment.xScreenCenter-ringSize(1) experiment.yScreenCenter-ringSize(1) experiment.xScreenCenter+ringSize(1) experiment.yScreenCenter+ringSize(1)],0,0)
    Screen('Flip',experiment.displayWindow);

    startRespdisplayWindow = experiment.getExpTime();
    results.startTimes(i) = experiment.getExpTime();
    finished = 0;
    results.responded(i) = 0;
    results.responseCorrect(i) = 0;
    results.joystickResponseTimes(i) = -1;
    hasHit = 0;
    results.joystickResponses{i} = 'None';
    experiment.logEvent(['Starting Trial ' num2str(i)]);
    while ~finished && experiment.getExpTime() - startRespdisplayWindow < timeout
        if isTest
            reading = (mod(gratingNum,3)-1)*100;
        else
            reading = experiment.readEnc();
        end
        vel = (reading-25*sign(reading))*(10/105);
        if abs(reading) < 50
            vel = 0;
        end

        if pos(1) < 0
            vel = max(vel,0);
            results.responseCorrect(i) = 0;
            if(~hasHit)
                disp('Hit!')
                experiment.logEvent('Hit left side');
            end
            results.joystickResponses{i} = 'Left';
            results.responded(i) = 1;
            hasHit = 1;
        elseif pos(1) > experiment.xScreenCenter*2 - stimSize(1)*2
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

        pos = pos + [vel 0 vel 0];

        if abs(pos(1) - centerPos(1)) < stimSize*.25
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
            finished = 1;
        end
        Screen('DrawTexture', experiment.displayWindow, tex, gratingSrc, pos, 0, 0);
        Screen('DrawTexture', experiment.displayWindow, ringTex, [], [experiment.xScreenCenter-ringSize(1) experiment.yScreenCenter-ringSize(1) experiment.xScreenCenter+ringSize(1) experiment.yScreenCenter+ringSize(1)],0,0)
        Screen('Flip',experiment.displayWindow);
        experiment.logData();
    end %end while

    experiment.closeServos()
    experiment.waitAndLog(1);

    if finished
        experiment.playReward();
        startLickdisplayWindow = experiment.getExpTime();
        while experiment.getExpTime() - startLickdisplayWindow < .5
            experiment.logData();
            if(experiment.readLickometer() == 0)
                results.firstLickTimes(results.sessionNum) = experiment.getExpTime();
                break;
            end
            pause(.005);
        end
        experiment.giveWater(.15);
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