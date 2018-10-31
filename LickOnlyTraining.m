clc
clear all

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
r.StartTrial(0,0,GetSecs);
while r.getCurrentTrial()<numTrials
    currReading = e.isLicking();
    clc
    disp(currReading);
    if(currReading == 0 && lastReading == 1)
            e.playReward();
            e.giveWater(0.015);
            r.LogLick(GetSecs);
            r.StartTrial(0,0,GetSecs);
    end
    lastReading = currReading;
    e.refillWater(.015)
    pause(.005);
end