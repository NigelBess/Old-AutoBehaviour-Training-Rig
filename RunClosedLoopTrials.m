function [] = RunClosedLoopTrials(mouseID, sessionNum, numTrials, isTest,port)
  %  try 
        if isTest
            e = DummyExperiment(mouseID, sessionNum);
            timeout = 2;
            iti = .5;
        else
            e = Experiment(mouseID, sessionNum,port);
            timeout = 60;
            iti = 3;
        end
        r = Results(mouseID, sessionNum);
        r.globalStart = e.globalStart;
        r.dateTime = e.dateTime;
        r.numTrials = 0;
        r.trialType = 'closedLoopTraining';
        r.contrastOptions = e.CONTRAST_OPTIONS;

        tiledGratings = zeros(1500,1500*4);
        for i = 1:length(e.CONTRAST_OPTIONS)
            tiledGratings(:,(i-1)*1500+1:i*1500) = GenerateCircularGrating(750,e.CONTRAST_OPTIONS(i));
        end
        ring = GenerateTargetRing(1000, 750);
        ringSize = [120 120];
        stimSize = [90 90];
        tex = Screen('MakeTexture', e.displayWindow, tiledGratings);
        ringTex = Screen('MakeTexture', e.displayWindow, ring);
        centerPos = [e.xScreenCenter-stimSize(1)+1 e.yScreenCenter-stimSize(1)+1 e.xScreenCenter+stimSize(1) e.yScreenCenter+stimSize(2)];
        e.closeServos();
        e.giveWater(.3);
        e.playReward()
        e.waitAndLog(2);
        e.logEvent('Starting session');
        for i = 1:numTrials
            while ~e.isBeamBroken()
                pause(.005)
            end

            e.openServos('Center');

            gratingNum = randi([1, length(e.CONTRAST_OPTIONS)]);
            r.contrastSequence(i) = e.CONTRAST_OPTIONS(gratingNum);
            choice = rand();
            rightProb = r.getLeftProportionOnInterval(i-6,i-1);
            if isnan(rightProb)
                rightProb = .5;
            end 
            if choice < rightProb
                r.stimSequence{i} = 'Right';
            else
                r.stimSequence{i} = 'Left';
            end

            if strcmp(r.stimSequence{i},'Right')
                initPos = [.5*e.xScreenCenter-stimSize(1)+1 e.yScreenCenter-stimSize(1)+1 .5*e.xScreenCenter+stimSize(1) e.yScreenCenter+stimSize(2)];
            else
                initPos = [1.5*e.xScreenCenter-stimSize(1)+1 e.yScreenCenter-stimSize(1)+1 1.5*e.xScreenCenter+stimSize(1) e.yScreenCenter+stimSize(2)];
            end

            pos = initPos;
            gratingSrc = [(gratingNum - 1)*1500+1 1 gratingNum*1500 1500];
            Screen('DrawTexture', e.displayWindow, tex, gratingSrc, pos, 0, 0);
            Screen('DrawTexture', e.displayWindow, ringTex, [], [e.xScreenCenter-ringSize(1) e.yScreenCenter-ringSize(1) e.xScreenCenter+ringSize(1) e.yScreenCenter+ringSize(1)],0,0)
            Screen('Flip',e.displayWindow);

            startRespdisplayWindow = e.getExpTime();
            r.startTimes(i) = e.getExpTime();
            finished = 0;
            r.responded(i) = 0;
            r.responseCorrect(i) = 0;
            r.joystickResponseTimes(i) = -1;
            hasHit = 0;
            r.joystickResponses{i} = 'None';
            e.logEvent(['Starting Trial ' num2str(i)]);
            while ~finished && e.getExpTime() - startRespdisplayWindow < timeout
                if isTest
                    reading = (mod(gratingNum,3)-1)*100;
                else
                    reading = e.readEnc();
                end
                vel = (reading-25*sign(reading))*(10/105);
                if abs(reading) < 50
                    vel = 0;
                end

                if pos(1) < 0
                    vel = max(vel,0);
                    r.responseCorrect(i) = 0;
                    if(~hasHit)
                        disp('Hit!')
                        e.logEvent('Hit left side');
                    end
                    r.joystickResponses{i} = 'Left';
                    r.responded(i) = 1;
                    hasHit = 1;
                elseif pos(1) > e.xScreenCenter*2 - stimSize(1)*2
                    vel = min(vel,0);
                    r.responseCorrect(i) = 0;
                    if(~hasHit)
                        disp('Hit!')
                        e.logEvent('Hit right side');
                    end
                    r.joystickResponses{i} = 'Right';
                    r.responded(i) = 1;
                    hasHit = 1;
                end

                pos = pos + [vel 0 vel 0];

                if abs(pos(1) - centerPos(1)) < stimSize*.25
                    e.logEvent('Moved grating to center')
                    r.responded(i) = 1;
                    r.joystickResponseTimes(i) = e.getExpTime();
                    if ~hasHit
                        r.responseCorrect(i) = 1;
                        if strcmp(r.stimSequence{i},'Right')
                            r.joystickResponses{i} = 'Right';
                        else
                            r.joystickResponses{i} = 'Left';
                        end
                    else
                         r.responseCorrect(i) = 0;
                    end
                    finished = 1;
                end
                Screen('DrawTexture', e.displayWindow, tex, gratingSrc, pos, 0, 0);
                Screen('DrawTexture', e.displayWindow, ringTex, [], [e.xScreenCenter-ringSize(1) e.yScreenCenter-ringSize(1) e.xScreenCenter+ringSize(1) e.yScreenCenter+ringSize(1)],0,0)
                Screen('Flip',e.displayWindow);
                e.logData();
            end

            e.closeServos()
            e.waitAndLog(1);

            if finished
                e.playReward();
                startLickdisplayWindow = e.getExpTime();
                while e.getExpTime() - startLickdisplayWindow < .5
                    e.logData();
                    if(e.readLickometer() == 0)
                        r.firstLickTimes(r.numTrials) = e.getExpTime();
                        break;
                    end
                    pause(.005);
                end
                e.giveWater(.15);
            else
                e.playNoise();
                e.waitAndLog(1);
            end
            Screen('FillRect',e.displayWindow,e.GREY_VALUE);
            Screen('Flip',e.displayWindow);
            r.endTimes(i) = e.getExpTime();
            e.logEvent(['Ending Trial ' num2str(i)]);
            e.refillWater(.03)
            e.waitAndLog(iti/2);
            e.resetEnc();
            e.waitAndLog(iti/2);
            r.numTrials = i;
            disp(i)
            r.save()
        end
   % catch ME
      %  matlabmail('jamesproney@gmail.com',ME.identifier,'Behavior Rig Crash','pdotjpr@gmail.com','NotMyPassword');
   % end
end