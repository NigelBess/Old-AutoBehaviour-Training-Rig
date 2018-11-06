TestSetup;
    fprintf("arduino has been set up. It is now waiting for the beam to connect...\n\n");
    while true
        clc
        disp(experiment.isBeamBroken())
        pause(0.05);
    end