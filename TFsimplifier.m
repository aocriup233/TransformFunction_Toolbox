classdef TFsimplifier < handle
    properties
        SymManager
        Impedance_levels = {'highGain', 'gmro++', 'gmro', 'ro', 'R', 'unity'}
        NumericValues = struct()
        usingAutoOrder = true
    end
    methods
        function obj = TFsimplifier(SymbolManager, varargin)
            % initialize TFsimplifier, SM must be obj from SFP
            obj.SymManager = SymbolManager;
            if nargin >= 2
                obj.NumericValues = varargin{2};
            end
        end
        function [poles, dominantPole] = extractSymPoles(obj, tf_sym, var)
            % extract and simplify poles from TF
            % ex. den(s) = (1-s/p1)*(1-x/p2) = 1 - s*(1/p1+1/p2) + s^2/(p1*p2)
            % => den(s) = 1 - s/p1 + s^2/(p1*p2)
            var = obj.SymManager.Symbols(var);
            [~, den] = numden(tf_sym);
            den_coeffs = coeffs(den, var , "All");
            den_coeffs = den_coeffs / den_coeffs(1);
            order = length(den_coeffs) - 1;
            poles = sym(zeros(1, order));
            for i = 1:order
                if i == 1
                    poles(i) = -den_coeffs(2);
                else
                    poles(i) = -den_coeffs(i+1)/den_coeffs(i);
                end
            end
            if order > 0
                dominantPole = poles(1);
            else
                dominantPole = [];
            end
        end
        function z = extractSymZeros(obj, tf_sym, var)
            var = obj.SymManager.Symbols(var);
            [num, ~] = numden(tf_sym);
            num_coeffs = coeffs(num, var , "All");
            num_coeffs = num_coeffs / num_coeffs(1);
            order = length(num_coeffs) - 1;
            z = sym(zeros(1, order));
            for i = 1:order
                if i == 1
                    z(i) = -num_coeffs(2);
                else
                    z(i) = -num_coeffs(i+1)/num_coeffs(i);
                end
            end
        end
        function [newTF, p, z, DCgain] = reconstructSymTF(obj, TF_sym, var)
            % H(s) = DCgain * \Pi(1-s/z) / \Pi(1-s/p)
            [p, ~] = obj.extractSymPoles(TF_sym, var);
            z = obj.extractSymZeros(TF_sym, var);
            DCgain = subs(TF_sym, var, 0);
            Zproduct = sym(1);
            for i = 1:length(z)
                Zproduct = Zproduct * (1 - var/z(i));
            end
            Pproduct = sym(1);
            for i = 1:length(p)
                Pproduct = Pproduct * (1 - var/p(i));
            end
            newTF = DCgain * Zproduct / Pproduct;
        end
        % method functions for numeric TF
        % method for simplify expr
        function [newTF, p, z, DCgain] = simplifySymTF(obj, TF_sym, var, level)
            if nargin < 4, level = 'gmro'; end
            [p, ~] = obj.extractSymPoles(TF_sym, var);
            z = obj.extractSymZeros(TF_sym, var);
            for i = 1:length(p)
                [pnum, pden] = numden(p(i));
                if obj.usingAutoOrder
                    [~, level] = obj.getMaxOrder(pnum);
                end
                pnum = obj.simplifyExpr(pnum, level);
                if obj.usingAutoOrder
                    [~, level] = obj.getMaxOrder(pden);
                end
                pden = obj.simplifyExpr(pden, level);
                p(i) = simplify(pnum / pden);
            end
            for i = 1:length(z)
                [znum, zden] = numden(z(i));
                if obj.usingAutoOrder
                    [~, level] = obj.getMaxOrder(znum);
                end
                znum = obj.simplifyExpr(znum, level);
                if obj.usingAutoOrder
                    [~, level] = obj.getMaxOrder(zden);
                end
                zden = obj.simplifyExpr(zden, level);
                z(i) = znum / zden;
            end
            DCgain = subs(TF_sym, var, 0);
            Zproduct = sym(1);
            for i = 1:length(z)
                Zproduct = Zproduct * (1 - var/z(i));
            end
            Pproduct = sym(1);
            for i = 1:length(p)
                Pproduct = Pproduct * (1 - var/p(i));
            end
            newTF = DCgain * Zproduct / Pproduct;
        end
        function expr = simplifyExpr(obj, tfexpr, level)
            % level == 'gmro++' , keep 'gm*ro*...'
            % level == 'gmro', keep 'gm*ro'
            % level == 'ro', keep 'ro'
            % level == 'R' , keep 'R'
            if nargin < 3, level = 'gmro'; end
            exprStr = char(tfexpr);
            % for getMaxOrder
            if ~ischar(level)
                expr = simplifyToOrder(obj, exprStr, level);
                return;
            end
            switch level
                case 'gmro++'
                    expr = simplifyToOrder(obj, exprStr, 7);
                case 'gmro'
                    expr = simplifyToOrder(obj, exprStr, 2);
                case 'ro'
                    expr = simplifyToOrder(obj, exprStr, 5);
                case 'R'
                    expr = simplifyToOrder(obj, exprStr, 3);
                otherwise
                    expr = tfexpr;
            end
        end
        function expr = simplifyToOrder(obj, exprStr, MinOrder)
            terms = obj.splitTerms(exprStr);
            keptTerms = {};
            for i = 1:length(terms)
                order = obj.calculateTermOrder(terms{i});
                if order >= MinOrder
                    keptTerms{end+1} = terms{i};
                end
            end
            if isempty(keptTerms)
                if startsWith(exprStr, '-')
                    expr = sym(-1);
                else 
                    expr = sym(1);
                end
            else
                expr = obj.combineTerms(keptTerms);
            end
        end
        function order = calculateTermOrder(obj, term)
            order = 0;
            %  gm ~ mS (1e-3)
            gm_matches = regexp(term, 'gm\w*', 'match');
            order = order + -3*length(gm_matches);
            %  ro ~ 10KOhm (1e5)
            ro_matches = regexp(term, 'ro\w*', 'match');
            order = order + 5*length(ro_matches);
            %  R ~ KOhm (1e3)
            R_matches = regexp(term, 'R(?!o)\w*', 'match');
            order = order + 3*length(R_matches);
        end
        function terms = splitTerms(obj, exprStr)
            terms = {};
            exprStr = strrep(exprStr, ' ', '');
            exprStr = strrep(exprStr, '*', '~');
            exprStr = strrep(exprStr, '-', '+-');
            parts = strsplit(exprStr, '+');
            for i = 1:length(parts)
                part = strtrim(parts{i});
                if isempty(part), continue; end
                part = strrep(part , '~', '*');
                if ~isempty(part) && ~strcmp(part, '0')
                    terms{end+1} = part;
                end
            end
            if isempty(terms)
                terms = exprStr;
            end
        end
        function expr = combineTerms(obj, keptTerms)
            expr = str2sym(keptTerms{1});
            for i = 2:length(keptTerms)
                expr = expr + str2sym(keptTerms{i});
            end
        end
        function [maxOrder, orderLevel] = getMaxOrder(obj, expr)
            expr = char(expr);
            terms = splitTerms(obj, expr);
            maxOrder = -3;
            for i = 1:length(terms)
                order = obj.calculateTermOrder(terms{i});
                if  order > maxOrder
                    maxOrder = order;
                end
            end
            if maxOrder == floor(maxOrder)
                orderLevel = maxOrder - 1;
            else
                orderLevel = floor(maxOrder);
            end
        end
        function [subTF, unsubVars] = batchSubs(obj, expr, varCell)
            if nargin < 3
                varCell = obj.SymManager.Values;
            end
            allVars = symvar(expr);
            allVarNames = arrayfun(@char, allVars, 'UniformOutput',false);
            varsToSub = {};
            valsToSub = [];
            subedNames = {};
            for i = 1:size(varCell, 1)
                varName = varCell{i, 1};
                varValue = varCell{i, 2};
                if ismember(varName, allVarNames)
                    idx = strcmp(allVarNames, varName);
                    varsToSub{end+1} = allVars(idx);
                    valsToSub(end+1) = varValue;
                    subedNames{end+1} = varName;
                end
            end
            if ~isempty(varsToSub)
                subTF = subs(expr, varsToSub, valsToSub);
            else
                subTF = expr;
            end
            unsubVars = setdiff(allVarNames, subedNames);
            unsubVars = setdiff(unsubVars, {'s','z','w'});
        end
        function [newTF, p, z, DCgain] = calculateValueTF(obj, TF, unsubVars, Var)
            %  use this function to calculateValueTF or sweep Vars
            newTF = simplify(TF);
            [num, den] = numden(TF);
            DCgain = double(20*log10(subs(TF, Var, 0)));
            if isempty(unsubVars)
                try
                    p = double(solve(den == 0, Var, 'MaxDegree', 4));
                    z = double(solve(num == 0, Var, 'MaxDegree', 4));
                catch
                    p = double(obj.calculateValueRoots(den, Var));
                    z = double(obj.calculateValueRoots(num, Var));
                end
                p = p /(2*pi);
                z = z /(2*pi);
            else
                try
                    p = solve(den == 0, Var, 'MaxDegree', 4);
                    z = solve(num == 0, Var, 'MaxDegree', 4);
                catch 
                    [newTF, p, z, DCgain] = obj.simplifySymTF(TF, Var);
                end
            end
        end
        function result = calculateValueRoots(obj, expr, Var)
            Coeffs_vec = coeffs(expr, Var, 'All');
            Coeffs = flipud(Coeffs_vec);
            order = length(Coeffs) - 1;
            result = roots(Coeffs);
            if order >= 2
                result = refineRoots(Coeffs_vec, result);
            end
            result = sortRoots(result);
            function refined = refineRoots(Coeffs_vec, result)
                refined = zeros(size(result));
                options = optimoptions('fsolve', 'Display', 'off', 'Algorithm', 'levenberg-marquardt', ...
                    'FunctionTolerance', 1e-14, 'StepTolerance', 1e-14, 'MaxIterations', 100);
                for i = 1:length(result)
                    x0 = result(i);
                    try
                        if abs(imag(x0)) > 1e-10
                            fun = @(x) evaluatePoly(Coeffs_vec, x(1) + 1i*x(2));
                            x_sol = fsolve(@(x) [real(fun(x)); imag(fun(x))], ...
                                [real(x0); imag(x0)], options);
                            refined(i) = x_sol(1) + 1i*x_sol(2);
                        else
                            fun = @(x) evaluatePoly(Coeffs_vec, x);
                            refined(i) = fsolve(fun, real(x0), options);
                        end
                    catch
                        refined(i) = x0;
                    end
                end
                function val = evaluatePoly(Coeffs_vec, x)
                    val = polyval(flipud(double(Coeffs_vec(:))), x);
                end
            end
            function sorted = sortRoots(result)
                if isempty(result)
                    sorted = result;
                    return;
                end
                [~, idx] = sortrows([real(result), imag(result)], [1,2]);
                sorted = result(idx);
            end
        end
    end
end