clc
clear all

%*IMPORTANT*
%make sure to set these values before running
mouseID = '000';
sessionNum = 1;
numTrials = 1000;
port = 'COM3';

    e = RealExperiment(port);
    r = Results(mouseID, numTrials,sessionNum,e,'joyStickOnly');
    %starting video
    
    %system(['python C:/Users/GoardLab/Documents/AutomatedBehaviorStim/Python/Server.py '...
    %  mouseID ' ' num2str(sessionNum) '&']);

    lastReading = 0;
    currSide = roll();
    e.closeServos();
    e.openSide(currSide);
    r.StartTrial(0,0,GetSecs());
    while r.getCurrentTrial < numTrials 
        currReading = e.readEnc();
        if (sign(currSide)==sign(currReading) && lastReading == 0)
                lastReading = 1;
                r.LogJoy(currReading,currSide,GetSecs());
                e.playReward();
                %e.deactivateServos();
                startLickWindow = GetSecs;    
                %Wait for mouse to lick
                while GetSecs - startLickWindow < .5
                    if(e.isLicking())
                        r.LogLick(GetSecs-startLickWindow);
                        break;
                    end
                end
                e.giveWater(.05);
                currSide = roll();
                e.closeServos();
                e.openSide(currSide);
                r.StartTrial(0,0,GetSecs());
                startTime = GetSecs();
        else
            lastReading = 0;
        end
        e.refillWater(.03h)
        pause(.005)
    end
    
    function out = roll()
        out = -1+2*(rand<0.5);%either -1 or 1
    end