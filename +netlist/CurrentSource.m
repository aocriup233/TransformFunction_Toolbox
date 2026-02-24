classdef CurrentSource < Device
    properties
        DC_value
        AC_mag
        AC_phase
        AC_symexpr = ''
        parallel_R
    end
    methods
        function obj = CurrentSource(name, nodes, DC_value)
            obj@Device(name, nodes, DC_value);
            obj.DC_value = DC_value;
            obj.AC_mag = 1;
            obj.AC_phase = 0;
            obj.parallel_R = inf;
            if length(nodes) ~= 2
                error('CS must have 2 nodes.');
            end
        end
        function setACvalue(obj, mag, phase)
            obj.AC_mag = mag;
            obj.AC_phase = phase;
        end
        function setACexpr(obj, value)
            if ischar(value)
                obj.AC_symexpr = value;
            else
                return;
            end
        end
        function setparallelR(obj, value)
            obj.parallel_R = value;
        end
    end
end