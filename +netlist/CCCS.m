classdef CCCS < Device
    properties
        control_source
    end
    methods
        function obj = CCCS(name, nodes, control_source, gm)
            obj@Device(name, nodes, gm);
            obj.control_source = control_source;
            if length(nodes) ~= 2 || length(control_source) ~= 1
                error('VCCS must have 2 output nodes and control source.');
            end
        end
        function beta = getCurrentgain(obj)
            beta = obj.value;
        end
    end
end