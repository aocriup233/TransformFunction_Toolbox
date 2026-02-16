classdef Nodes < handle
    properties
        %  Basic information
        ID = []
        name = ''
        %  Graph Properties
        GraphType = 'SignalFlowGraph'            %  SmallSignalGraph   SignalFlowGraph(default)
        NodeType = 'Internal'                    %  Input   Output   Internal(default)
        ElectricalType = 'Voltage'               %  Voltage(default)   Current   VoltageCurrent
        %  Value
        Value = 0;                               % voltage/current value
        %  Connection information ...
        %  Other
        IsAGround = false                        %  True  False(default)
    end
    methods
        function  obj = Nodes(varargin)
            % Initialize
            if nargin == 0
                return;
            elseif nargin == 1 && isstruct(varargin{1})
                s = varargin{1};
                obj.ID = s.ID;
                obj.name = s.name;
                if isfield(s, 'GraphType'), obj.GraphType = s.GraphType; end
                if isfield(s, 'NodeType'), obj.NodeType = s.NodeType; end
                if isfield(s, 'ElectricalType'), obj.ElectricalType = s.ElectricalType; end
                if isfield(s, 'IsAGround'), obj.IsAGround = s.IsAGround; end
            elseif nargin >= 2
                obj.ID = varargin{1};
                obj.name = varargin{2};
                if nargin >= 3, obj.GraphType = varargin{3}; end
                if nargin >= 4, obj.NodeType = varargin{4}; end
                if nargin >= 5, obj.ElectricalType = varargin{5}; end
                if nargin >= 6, obj.IsAGround = varargin{6}; end
            end
        end
    end
end
