classdef SignalFlowParser < handle
    properties
        SymManager
        NodesMap
        EdgesList
        Ports
        RawSFFile
        IFremainParallel = false
        %   We need to remain Parallel sym '//' to keep the expr simple.
    end
    methods
        function obj = SignalFlowParser(varargin)
            obj.SymManager = SymbolManager();
            obj.NodesMap = containers.Map('KeyType', 'double', 'ValueType', 'any');
            obj.Ports = {'input', ''; 'output', ''};
            obj.EdgesList = {};
            if nargin == 1
                obj.IFremainParallel = varargin{1};
            end
        end
        function symNames = extractSymbols(obj, filePath)
            %   extract Symbols from .sf / .txt
            obj.readFile(filePath);
            symNames = {};
            for i = 1:length(obj.RawSFFile)
                line = strtrim(obj.RawSFFile{i});
                if isempty(line) || line(1) == '*', continue; end
                %   Parse .SYM
                if startsWith(line, '.SYM')
                    line = strrep(line, '.SYM', '');
                    line = strtrim(line);
                    vars = regexp(line, '(\w+)\s*=', 'tokens');
                    for j = 1:length(vars)
                        symNames{end+1} = vars{j}{1};
                    end
                    remaining = regexprep(line, '\w+\s*=\s*[\w\.]+', '');
                    remaining = strtrim(remaining);
                    if ~isempty(remaining)
                        others = regexp(remaining, '\w+', 'match');
                        for j = 1:length(others)
                            symNames{end+1} = others{j};
                        end
                    end
                end
                %   Parse from .Edges
                tokens = regexp(line, '(\w+)\s*=\s*([-\w]+)', 'tokens');
                for j = 1:(length(tokens))
                    val = tokens{j}{2};
                    if ~isnan(str2double(val(1))), continue; end
                    if startsWith(val, '-')
                        val = val(2:end);
                    end
                    if isnan(str2double(val))
                        symNames{end+1} = val;
                    end  
                end
                if obj.IFremainParallel == true
                    ParallelTokens = regexp(line, '\<[a-zA-Z]\w*//[a-zA-Z]\w*\>', 'match');
                    for j =1:length(ParallelTokens)
                        %   Fuck Matlab r2022a, can't use '//' to create sym!
                        ParallelTokens{j} = replace(ParallelTokens{j}, '//', '_P_');
                        %   WHEN display, transform '_P_' to '//' in Latex
                        symNames{end+1} = ParallelTokens{j};
                    end
                end
                exprTokens = regexp(line, '(\w+)\s*=\s*([^\s]+)', 'tokens');
                for j = 1:length(exprTokens)
                    expr = exprTokens{j}{2};
                    vars = regexp(expr, '[a-zA-Z]+[0-9]*', 'match');
                    for k = 1:length(vars)
                        if ~ismember(vars{k}, {'sin', 'cos', 'exp', 'log'})
                            symNames{end+1} = vars{k};
                        end
                    end
                end
            end
            symNames = setdiff(symNames, {'s', 'w', 'z'});
            symNames = unique(symNames);
        end
        function registerToSM(obj, symNames)
            obj.SymManager.registerFromSF(symNames);
        end
        function registerValue(obj, filePath)
            obj.parseSymValue(filePath);
            obj.SymManager.replaceValuesUnits();
        end
        function parseSymValue(obj, filePath)
            %   Parse Symbol's Value from .SYM ex. gm1 = 300m
            obj.readFile(filePath);
            symValue = {};
            for i = 1:length(obj.RawSFFile)
                line = strtrim(obj.RawSFFile{i});
                if isempty(line) || line(1) == '*', continue; end
                %   Parse .SYM
                if startsWith(line, '.SYM')
                    tokens = regexp(line, '(\w+)\s*=\s*(\S+)', 'tokens');
                    symValue = cell(length(tokens), 2);
                    for j = 1:length(tokens)
                        symValue{j,1} = tokens{j}{1};
                        symValue{j,2} = tokens{j}{2};
                    end
                end
            end
            obj.SymManager.Values = symValue;
        end       
        function initNodesEdges(obj, filePath)
            % initialize Nodes and Edges
            obj.readFile(filePath);
            edgeID = 1;
            for i = 1:length(obj.RawSFFile)
                line = strtrim(obj.RawSFFile{i});
                if isempty(line) || line(1) == '*', continue; end
                %    Parse .NODE
                if startsWith(line, '.NODE')
                    obj.parseNodeLine(line);
                    continue;
                end
                %    Parse .EDGE
                if startsWith(line, '.EDGE')
                    edge = obj.parseEdgeLine(line, edgeID);
                    if ~isempty(edge)
                        obj.EdgesList{end+1} = edge;
                        edgeID = edgeID + 1;
                    end
                end
            end
        end    
        function parseNodeLine(obj, line)
            tokens = regexp(line, '\s+', 'split');
            if length(tokens) >= 3
                nodeID = str2double(tokens{2});
                nodeName = tokens{3};
                node = Nodes(nodeID, nodeName);
                if length(tokens) >= 4 && ~strcmp(tokens{4}, 'Ground')
                    node.NodeType = tokens{4};
                    switch lower(tokens{4})
                        %  initialize Ports (input & output)
                        case {'input'}
                            obj.Ports{1,2} = tokens{2};
                        case {'output'}
                            obj.Ports{2,2} = tokens{2};
                        otherwise
                    end
                    if length(tokens) >= 5
                        node.ElectricalType = tokens{5};
                    end
                else 
                    node.IsAGround = true;
                end
                obj.NodesMap(nodeID) = node;   % ??? Can nodeID == 0?
            end
        end
        function edge = parseEdgeLine(obj, line, edgeID)
            ParallelFlag = obj.IFremainParallel;
            tokens = regexp(line, '\s+', 'split');
            if length(tokens) < 4, edge = []; return; end
            edgeName = tokens{2};
            fromNode = str2double(tokens{3});
            toNode = str2double(tokens{4});
            % ...  ensure fromNode and toNode exist.
            if ~isKey(obj.NodesMap, fromNode)
                edge = []; return; end
            if ~isKey(obj.NodesMap, toNode)
                edge = []; return; end
            edge = Edges(edgeID, edgeName);
            edge.FromNode = fromNode;
            edge.ToNode = toNode;
            parseGainExpr(edge, line, ParallelFlag);
            function parseGainExpr(edge, line, ParallelFlag)
                %   Parse Gain(value & Sym & Expr)
                kv = regexp(line, '(\w+)\s*=\s*(.+)', 'tokens');
                if ~isempty(kv)
                    key = kv{1}{1};
                    valStr = kv{1}{2};
                    switch upper(key)
                        case {'GM'}
                            edge.GainType = 'transconductance';
                        case {'R', 'Z'}
                            edge.GainType = 'transresistance';
                        case {'AV', 'GAIN'}
                            edge.GainType = 'voltage_gain';
                        case {'AI'}
                            edge.GainType = 'current_gain';
                    end
                    edge.setExprGain(valStr, ParallelFlag);
                end
            end
        end
        function readFile(obj, filePath)
            fid = fopen(filePath, "r");
            obj.RawSFFile = {};
            while ~feof(fid)
                obj.RawSFFile{end+1} = fgetl(fid);
            end
            fclose(fid);
        end
    end
end