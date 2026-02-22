classdef Resistor < Device
    methods
        function obj = Resistor(name, nodes, value)
            obj@Device(name, nodes, value);
            if length(nodes) ~= 2
                error('Resistor must have 2 nodes');
            end
        end
        function G = getConductance(obj)
            if isnumeric(obj.value)
                if obj.value == 0 
                    G = inf;
                else
                    G = 1/obj.value;
                end
                return;
            end
            if ischar(obj.value)
                pattern = '^-?\d+(\.\d+)?([eE][-+]?\d+)?$';
                isPureNumber = ~isempty(regexp(obj.value, pattern, 'once'));
                pattern = '[^eE][\+\-\*\/\^]|[\*\/\^]';
                hasOperator = ~isempty(regexp(obj.value, pattern, 'once'));
                if isPureNumber || ~hasOperator
                    G = string(['1/' obj.value]);
                else
                    G = string(['1/(' obj.value ')']);
                end
                return;
            end
        end
        function R = getResistance(obj)
            if isnumeric(obj.value)
                R = obj.value;
                return;
            end
            if ischar(obj.value)
                pattern = '^-?\d+(\.\d+)?([eE][-+]?\d+)?$';
                isPureNumber = ~isempty(regexp(obj.value, pattern, 'once'));
                pattern = '[^eE][\+\-\*\/\^]|[\*\/\^]';
                hasOperator = ~isempty(regexp(obj.value, pattern, 'once'));
                if isPureNumber || ~hasOperator
                    R = string([obj.value]);
                else
                    R = string(['(' obj.value ')']);
                end
                return;
            end
        end
    end
end