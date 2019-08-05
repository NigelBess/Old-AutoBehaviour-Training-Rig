classdef HardwareIOGen2_1 < HardwareIOGen2
methods(Access = public)
    function obj = HardwareIOGen2_1(port)
        obj = obj@HardwareIOGen2(port);
    end
    function out = ReadJoystick(obj)
        out = -ReadJoystick@HardwareIOGen2(obj);
    end
end
end