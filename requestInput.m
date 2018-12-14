prompt = {"Mouse ID", "Session Number", "Number of Trials", "Port","Number of Monitors"};
title = "Settings";
dims = [1 35];
defaultValues;
defInput = {mouseID,sessionNum,numTrials,port,screenNum};

val = inputdlg(prompt,title,dims,defInput);
 mouseID = val{1};
 sessionNum = str2num(val{2});
 numTrials = str2num(val{3});
    port = val{4};
    screenNum = str2num(val{5});
    
    defaults = fopen('defaultValues.m','w');
    lineEnd = "';\n";
    str = "mouseID = '" + string(mouseID)+lineEnd;
    str = str + "sessionNum = '" + string(num2str(sessionNum))+lineEnd;
    str = str + "numTrials = '" + string(num2str(numTrials))+lineEnd;
    str = str + "port = '" + string(port)+lineEnd;
     str = str + "screenNum = '" + string(screenNum)+lineEnd;
    fprintf(defaults,str);
    fclose(defaults);
    
    if screenNum == 1
        screenNum = 0;
    end
    