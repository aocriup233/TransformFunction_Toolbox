classdef SignalFlowChart < handle
    properties
        SFParser
        NodesMap = []
        EdgesList = []
        AdjMatrix = []
        TransformFunction = []
    end
    methods
        function obj = SignalFlowChart(varargin)
            if nargin >= 1
                obj.SFParser = SignalFlowParser(varargin{1});
            else 
                obj.SFParser = SignalFlowParser();
            end
        end
        function createSFC(obj, filePath)
            %   Get NodesCell and EdgesMatrix
            symNames = obj.SFParser.extractSymbols(filePath);
            obj.SFParser.registerToSM(symNames);
            obj.SFParser.initNodesEdges(filePath);
            obj.NodesMap = keys(obj.SFParser.NodesMap);
            obj.EdgesList = cell(length(obj.SFParser.EdgesList), 3);
            for i = 1:length(obj.SFParser.EdgesList)
                edge = obj.SFParser.EdgesList{i};
                obj.EdgesList{i,1} = edge.FromNode;
                obj.EdgesList{i,2} = edge.ToNode;
                obj.EdgesList{i,3} = edge.GainExpr;
            end
        end
        function [Nodes, Edges] = prepareMason(obj)
            Nodes = cellfun(@num2str, obj.NodesMap, 'UniformOutput', false);
            idToIdx = containers.Map('KeyType', 'double', 'ValueType', 'double');
            for i = 1:length(obj.NodesMap)
                idToIdx(obj.NodesMap{i}) = i;
            end
            n = length(obj.EdgesList);
            Edges = cell(n, 3);
            for i = 1:n
                edge = obj.EdgesList(i, :);
                Edges{i, 1} = idToIdx(edge{1});
                Edges{i, 2} = idToIdx(edge{2});
                Edges{i, 3} = edge(3);
            end
        end
        function buildAdjMatrix(obj, Nodes, Edges)
            AdjMat = sym(zeros(length(Nodes)));
            for i = 1:size(Edges, 1)
                from = Edges{i, 1};
                to = Edges{i, 2};
                gain = Edges{i, 3};
                AdjMat(from, to) = AdjMat(from, to) + gain;
            end
            obj.AdjMatrix = AdjMat;
        end
        function [paths, gains] = findAllForwardPaths(obj, startNode, endNode, Nodes)
            startIdx = find(strcmp(Nodes, startNode), 1);
            endIdx = find(strcmp(Nodes, endNode), 1);
            paths = {};
            gains = sym([]);
            currentPath = startIdx;
            currentGain = sym(1);
            N = length(Nodes);
            visited = false(1, N);
            visited(startIdx) = true;
            [paths, gains] = obj.dfsForward(startIdx, endIdx, currentPath, currentGain, visited, paths, gains, N);
        end
        function [paths, gains] = dfsForward(obj, current, target, path, gain, visited, paths, gains, N)
            %  using DFS to find Forward Paths
            if current == target
                paths{end+1} = path;
                gains(end+1) = gain;
                return;
            end
            for next = 1:N
                if obj.AdjMatrix(current, next) ~= 0 && ~visited(next)
                    newGain = gain * obj.AdjMatrix(current, next);
                    newPath = [path, next];
                    newVisited = visited;
                    newVisited(next) = true;
                    [paths, gains] = obj.dfsForward(next, target, newPath, newGain, newVisited, paths, gains, N);
                end
            end 
        end
        function loops = findAllLoops(obj)
            N = length(obj.NodesMap);
            loops = struct('path', {}, 'gain', {}, 'nodes', {});
            for start = 1:N
                visited = false(1,N);
                path = start;
                gain = sym(1);
                loops = obj.dfsLoop(start, start, path, gain, visited, loops, N);
            end
            loops = obj.removeDuplicateLoops(loops);
        end
        function loops = dfsLoop(obj, current, start, path, gain, visited, loops, N)
            %  using DFS to find Loops
            visited(current) = true;
            for next = 1:N
                if obj.AdjMatrix(current, next) ~= 0
                    if next == start && length(path) > 1
                        loopGain = gain * obj.AdjMatrix(current, next);
                        newLoop.path = [path, start];
                        newLoop.gain = loopGain;
                        newLoop.nodes = sort(path);
                        loops{end+1} = newLoop;
                    elseif ~visited(next)
                        newPath = [path, next];
                        newGain = gain * obj.AdjMatrix(current, next);
                        loops = obj.dfsLoop(next, start, newPath, newGain, visited, loops, N);
                    end
                end
            end
            visited(current) = false;
        end
        function uniqueLoops = removeDuplicateLoops(obj, loops)
            if isempty(loops)
                uniqueLoops = [];
                return;
            end
            n = length(loops);
            keep = true(1, n);
            for i = 1:n
                for j = i+1:n
                    if isequal(loops{i}.nodes, loops{j}.nodes)
                        keep(j) = false;
                    end
                end
            end
            uniqueLoops = loops(keep);
        end
        function result = checkTouching(obj, path1, path2)
            nodes1 = unique(path1);
            nodes2 = unique(path2);
            result = ~isempty(intersect(nodes1, nodes2));
        end
        function delta = calculateDelta(obj, loops)
            m = length(loops);
            if m == 0
                delta = sym(1);
                return;
            end
            L = sym(zeros(1, m));
            for i = 1:m
                L(i) = loops{i}.gain;
            end
            delta = sym(1);
            for k = 1:m
                kthSum = sym(0);
                combinations = nchoosek(1:m, k);
                for c = 1:size(combinations, 1)
                    indices = combinations(c, :);
                    if obj.areNonTouching(loops, indices)
                        product = sym(1);
                        for idx = indices
                            product = product * L(idx);
                        end
                        kthSum = kthSum + product;
                    end
                end
                delta = delta + ((-1)^k) * kthSum;
            end
        end
        function result = areNonTouching(obj, loops, indices)
            n = length(indices);
            for i = 1:n
                for j = i+1:n
                    if obj.checkTouching(loops{indices(i)}.path, loops{indices(j)}.path)
                        result = false;
                        return;
                    end
                end
            end
            result = true;
        end
        function [deltaK, results] = calculateDeltaK(obj, forwardPath, loops)
            pathNodes = unique(forwardPath);
            nonTouchingLoops = {};
            for i = 1:length(loops)
                if ~obj.checkTouching(forwardPath, loops{i}.path)
                    nonTouchingLoops{end+1} = loops{i};
                end
            end
            if isempty(nonTouchingLoops)
                deltaK = sym(1);
            else
                deltaK = obj.calculateDelta(nonTouchingLoops);
            end
            results.nonTouchingLoops = nonTouchingLoops;
        end
        function [details, TF, dcGain, poles, zeros] = solveTF(obj)
            s = obj.SFParser.SymManager.Symbols('s');
            inputNode = obj.SFParser.Ports{1, 2};
            endNode = obj.SFParser.Ports{2, 2};
            [nodes, edges] = obj.prepareMason;
            obj.buildAdjMatrix(nodes, edges);
            [paths, gains] = obj.findAllForwardPaths(inputNode, endNode, nodes);
            details.forwardPaths = paths;
            details.forwardGains = gains;
            loops = obj.findAllLoops();
            details.loops = loops;
            delta = obj.calculateDelta(loops);
            details.delta = delta;
            numerator = sym(0);
            details.deltaK = {};
            for k = 1:length(paths)
                [deltaK, kDetails] = obj.calculateDeltaK(paths{k}, loops);
                Pk = gains(k);
                term = Pk * deltaK;
                numerator = numerator + term;
                details.deltaK{k} = struct('Pk', Pk, 'deltaK', deltaK, ...
                    'term', term, 'nonTouching', kDetails.nonTouchingLoops);
            end
            obj.TransformFunction = simplify(numerator / delta);
            TF = obj.TransformFunction;
            details.numerator = numerator;
            try
                [dcGain, poles, zeros] = obj.calculatePZK(s, TF);
            catch
                TFS = TFsimplifier(obj.SFParser.SymManager);
                [TF, poles, zeros, dcGain] = TFS.reconstructSymTF(TF, 's');
            end
        end
        function [TF, poles, zeros, dcGain] = simplifyTF(obj, TF, level)
            if nargin < 3, level = 'gmro'; end
            TFS = TFsimplifier(obj.SFParser.SymManager);
            try
                [TF, poles, zeros, dcGain] = TFS.simplifySymTF(TF, 's', level);
            catch
                [TF, poles, zeros, dcGain] = TFS.reconstructSymTF(TF, 's');
            end
        end
        function [dcGain, poles, zeros] = calculatePZK(obj, s, TF)
            [num, den] = numden(TF);
            dcGain = subs(TF, s, 0);
            zeros = solve(num == 0, s, 'MaxDegree', 4);
            poles = solve(den == 0, s, 'MaxDegree', 4);
        end
        function result = analysisTF(obj, TF, option, paramRange, Var)
            TFS = TFsimplifier(obj.SFParser.SymManager);
            varCell = TFS.SymManager.Values;
            [TF, unsubVars] = TFS.batchSubs(TF, varCell);
            TFA = TFAnalyzer(TF, unsubVars, TFS);
            if nargin > 3
                TFA.paramRange = paramRange;
            end
            if nargin < 5
                    Var = 's';
            end
            result = TFA.realizeTF(option, Var);
            [~, p, z, DCgain] = TFS.calculateValueTF(TF, unsubVars, Var);
            result.poles = p;
            result.zeros = z;
            result.DCgain = DCgain;
        end
    end
end

            




