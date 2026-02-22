classdef Device < handle
    % Basic Device Class (R, C, L, Voltage Source, Current Source, VCCS, CCCS
    properties
        name
        nodes
        value
        params
    end
    methods
        function obj = Device(name, nodes, value)
            obj.name = name;
            obj.nodes = nodes;
            obj.value = value;
            obj.params = struct();
        end
        function n = getNodeCount(obj)
            n = length(obj.nodes);
        end
    end
end