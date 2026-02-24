classdef VCCS < Device
    properties
        control_nodes
    end
    methods
        function obj = VCCS(name, nodes, control_nodes, gm)
            obj@Device(name, nodes, gm);
            obj.control_nodes = control_nodes;
            if length(nodes) ~= 2 || length(control_nodes) ~= 2
                error('VCCS must have 2 output nodes and 2 control nodes.');
            end
        end
        function gm = getTransconductance(obj)
            gm = obj.value;
        end
    end
end
