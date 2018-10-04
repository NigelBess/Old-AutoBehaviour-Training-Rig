TestSetup;
    fprintf("arduino has been set up. It is now waiting for the beam to connect...\n\n");
    while experiment.isBeamBroken()
        pause(0.05);
    end
    fprintf("IR beam is now aligned\n\n");