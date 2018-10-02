function [] = JoystickOnlyTraining(mouseID, sessionNum)

    e = Experiment(mouseID, sessionNum);
    r = Results(mouseID, sessionNum);
    r.trialType = 'joyOnly';
    %starting video
    
    %system(['python C:/Users/GoardLab/Documents/AutomatedBehaviorStim/Python/Server.py '...
    %  mouseID ' ' num2str(sessionNum) '&']);

    lastReading = 0;
    currSide = datasample(e.posOptions,1);
    e.closeServos();
    WaitSecs(1);
    e.resetEnc();
    e.openServos(currSide);
    
    while r.numTrials < 50
        currReading = e.readEnc();
        if (currReading < e.leftThresh && strcmp(currSide, 'Right') || currReading > e.rightThresh && strcmp(currSide, 'Left')) && lastReading == 0
                lastReading = 1;
                r.joystickCounts(r.numTrials) = currReading;
                r.joystickResponseTimes(r.numTrials) = GetSecs - e.globalStart;
                e.playReward();
                %e.deactivateServos();
                startLickWindow = GetSecs;    
                %Wait for mouse to lick
                while GetSecs - startLickWindow < .5
                    e.logData();
                    if(e.readLickometer() == 0)
                        r.firstLickTimes(r.numTrials) = GetSecs - e.globalStart;
                        break;
                    end
                end
                e.giveWater(.03);
                currSide = datasample(e.posOptions,1);
                r.save();
                r.nextTrial();
                e.closeServos();
                e.waitAndLog(1);
                e.openServos(currSide);
                e.resetEnc();
        else
            lastReading = 0;
        end
        e.logData();
        e.refillWater(.03)
        pause(.005)
    end
end