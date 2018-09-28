classdef Game < handle
    
properties (Access = public)
    gameObjects
end
properties (Constant)
    deltaTime = 0.005 %minimum time between each frame
end
methods (Access = private)
   
end
methods (Access = public)
    function [] = StartGame(this)
        
        %find all gameObjects
        allVars = whos();
        for i = 1:numel(allVars)
            if(strcmpi(allVars(i).class,'GameObject'))
                this.gameObjects(end+1) = allVars(i);
            end
        end
        numObjects = numel(this.gameObjects);
        
        %initialize all gameObjects
        for i = 1:numObjects
            this.gameObjects(i).Awake();
        end
        
        %Game Loop
        while true
             for i = 1:numObjects
                 if (this.gameObjects(i).enabled)
                     this.gameObjects(i).Update();
                 end
             end
             pause (this.deltaTime)
        end
    end
end
end