prompt = {"Mouse ID", "Session Number", "Number of Trials", "Port"};
title = "Settings";
dims = [1 35];
defInput = {'000','1','1000','COM5'};

val = inputdlg(prompt,title,dims,defInput);
 mouseID = val{1};
 sessionNum = str2num(val{2});
 numTrials = str2num(val{3});
    port = val{4};