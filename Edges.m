classdef Edges < handle
    properties
        %  Basic information
        ID = []
        name = ''
        %  Graph Properties
        GraphType = 'SignalFlowGraph'            %  SmallSignalGraph   SignalFlowGraph(default)
        EdgeType = 'Unidirectional'              %  Unidirectional(default)     Bidirectional
        GainType = 'transresistance'             %  transconductance   transresistance(default)    voltage_gain    current_gain
        %  Value
        Value = 1                                %  use it WHEN IsGainSym IS FALSE!
        SymValue = []                            %  use it WHEN IsGainSym IS TRUE!
        GainExpr = []                            %  use it WHEN IsGainSym IS TRUE and GET GainExpr from the SymManager!
        %  Connection Information
        FromNode = []
        ToNode = []
        %  others
        IsGainSym = true                         %  True(default)      False
        %  SymManagerRef = SymManager
    end
    methods
        function  obj = Edges(varargin)
            % Initialize
            if nargin == 0
                return;
            end
            if nargin == 1 && isstruct(varargin{1})
                s = varargin{1};
                obj.initFromStruct(s);
                return;
            end
            if nargin >= 2
                obj.ID = varargin{1};
                obj.name = varargin{2};
            end
            if nargin >= 3, obj.GraphType = varargin{3}; end
            if nargin >= 4, obj.EdgeType = varargin{4}; end
            if nargin >= 5, obj.GainType = varargin{5}; end
            if nargin >= 6, obj.FromNode = varargin{6}; end
            if nargin >= 7, obj.ToNode = varargin{7}; end
            if nargin >= 8, obj.IsGainSym = varargin{8}; end
            if nargin >= 9, obj.setExprGain(varargin{9}, true); end
        end
        function initFromStruct(obj, s)
            if isfield(s, 'ID'), obj.ID = s.ID; end
            if isfield(s, 'name'), obj.name = s.name; end
            if isfield(s, 'GraphType'), obj.GraphType = s.GraphType; end
            if isfield(s, 'GainType'), obj.GainType = s.GainType; end
            if isfield(s, 'FromNode'), obj.FromNode = s.FromNode; end
            if isfield(s, 'ToNode'), obj.ToNode = s.ToNode; end
            if isfield(s, 'IsGainSym'), obj.IsGainSym = s.IsGainSym; end
            if isfield(s, 'GainExpr'), obj.setExprGain(s.GainExpr, true); end
            if isfield(s, 'SymValue'), obj.SymValue = s.SymValue; end
            if isfield(s, 'Value'), obj.Value = s.Value; end
        end
        function exprStr = setExprGain(obj, valStr, ParallelFlag)
            %   CORE CODE!
            %   if we remain Parallel symbol
            if ParallelFlag
                exprStr = replace(valStr, '//', '_P_');
                %    Fuck Matlab r2022a, can't use '//' to create sym!
                %    WHEN display, transform '_P_' to '//' in Latex
                exprStr = replaceUnits(exprStr);
                obj.GainExpr = str2sym(exprStr);
            else 
                
                %    try to Parse Parallel Ex: 'ro1//ro2' =>
                %    '((ro1*ro2)/(ro1+ro2))'
                exprStr = simplify_parallel(valStr);
                obj.GainExpr = simplify(str2sym(exprStr));
            end
            function results = replaceUnits(exprStr)
                %   find numbers + units => values
                unitMap = containers.Map({'a', 'f', 'p', 'n', 'u', 'm', ...
                               'k', 'M', 'G', 'T'}, ...
                             {1e-18, 1e-15, 1e-12, 1e-9, ...
                              1e-6, 1e-3, 1e3, 1e6, 1e9, 1e12});
                pattern = '(\d+\.?\d*(?:[eE][+-]?\d+)?)([afpnumkMGT])';
                [tokens, ~] = regexp(exprStr, pattern, 'tokens', 'match');
                if isempty(tokens)
                    results = exprStr;
                else 
                    results = regexprep(exprStr, pattern, '${convertToSci($1,$2,unitMap)}');
                end
            end
        end
    end
end

