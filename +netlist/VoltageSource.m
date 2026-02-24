classdef VoltageSource < Device
    properties
        DC_value
        AC_mag
        AC_phase
        AC_symexpr = ''
        series_R
    end
    methods
        function obj = VoltageSource(name, nodes, DC_value)
            obj@Device(name, nodes, DC_value);
            obj.DC_value = DC_value;
            obj.AC_mag = 1;
            obj.AC_phase = 0;
            obj.series_R = 0;
            if length(nodes) ~= 2
                error('VS must have 2 nodes.');
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
        function setSeriesR(obj, value)
            obj.series_R = value;
        end
    end
end