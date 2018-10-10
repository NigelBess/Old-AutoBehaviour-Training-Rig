clc;
clear;
numTrials = 100000;
numStreaks = 0;
lastValue = 0;
currentValue = 0;
for i = 2:numTrials
    currentValue = rand>0.5;
    if currentValue~=lastValue
        numStreaks = numStreaks+1;
    end
end
fprintf("average streak : %.2f", numTrials/numStreaks);