clc
clear all

%*IMPORTANT*
%make sure to set these values before running
mouseID = '000';
sessionNum = 1;
numTrials = 1000;
port = 'COM3';

e = RealExperiment(port);
r = Results(mouseID, numTrials,sessionNum,e,'lickOnly');
%starting video
%system(['python C:/Users/GoardclearLab/Documents/AutomatedBehaviorStim/Python/Server.py '...
%    mouseID ' ' num2str(sessionNum) '&']);
e.openServos();
lastReading = 1;
startTime = GetSecs;
r.StartTrial(0,0,startTime);
while r.getCurrentTrial()<numTrials
    currReading = e.isLicking();
    clc
    disp(currReading);
    if(currReading == 0 && lastReading == 1)
            e.playReward();
            e.giveWater(0.015);
            r.LogLick(GetSecs-startTime);
            startTime = GetSecs();
            r.StartTrial(0,0,startTime);
    end
    lastReading = currReading;
    e.refillWater(.015)
    pause(.005);
end