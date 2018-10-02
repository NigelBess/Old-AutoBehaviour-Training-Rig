classdef DummyExperiment < Experiment
    %DummyExperiment - Substitue for Experiment.m that allows for testing
    %of stimulus code without an arduino
    methods
        function obj = DummyExperiment(id,num)
            obj = obj@Experiment(id,num);
        end
    end
end



