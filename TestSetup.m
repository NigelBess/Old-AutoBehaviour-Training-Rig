clc
clear all

mouseID = '000';
sessionNum = 1;
port = 'COM4';
  experiment = RealExperiment(mouseID, sessionNum,port);