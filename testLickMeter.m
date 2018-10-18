TestSetup;
    fprintf("arduino has been set up. It is now waiting for a lick...\n\n");
    while ~experiment.isLicking()
        pause(0.05);
    end
    fprintf("Lick detected.\n\n");