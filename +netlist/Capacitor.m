classdef Capacitor < Device
    methods
        function obj = Capacitor(name, nodes, value)
            obj@Device(name, nodes, value);
            if length(nodes) ~= 2
                error('Capacitor must have 2 nodes');
            end
        end
        function Y = getAdmittance(obj, freq)
            if isnumeric(obj.value)
                Y = 1j*2*pi*freq*obj.value;
                return;
            end
            if ischar(obj.value)
                pattern = '^-?\d+(\.\d+)?([eE][-+]?\d+)?$';
                isPureNumber = ~isempty(regexp(obj.value, pattern, 'once'));
                pattern = '[^eE][\+\-\*\/\^]|[\*\/\^]';
                hasOperator = ~isempty(regexp(obj.value, pattern, 'once'));
                if isPureNumber || ~hasOperator
                    Y = string(['s*' obj.value]);
                else
                    Y = string(['s*(' obj.value ')']);
                end
                return;
            end
        end
        function Z = getImpedance(obj, freq)
            if isnumeric(obj.value)
                if obj.value == 0 || freq == 0
                    Z = inf;
                else
                    Z = 1/(1j*2*pi*freq*obj.value);
                end
                return;
            end
            if ischar(obj.value)
                pattern = '^-?\d+(\.\d+)?([eE][-+]?\d+)?$';
                isPureNumber = ~isempty(regexp(obj.value, pattern, 'once'));
                pattern = '[^eE][\+\-\*\/\^]|[\*\/\^]';
                hasOperator = ~isempty(regexp(obj.value, pattern, 'once'));
                if isPureNumber || ~hasOperator
                    Z = string(['1/(s*' obj.value ')']);
                else
                    Z = string(['1/(s*(' obj.value '))']);
                end
                return;
            end
        end
    end
end