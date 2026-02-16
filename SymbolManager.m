classdef SymbolManager < handle
    properties
        Values
        Symbols
        Expressions
        DefaultVars
        DefaultUnits
    end
    methods
        function obj = SymbolManager()
            obj.Values = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.Symbols = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.Expressions = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.initDefaultVars();
            obj.initDefaultUnits();
        end
        function initDefaultVars(obj)
            % Laplace transform, Fourier transform, Z-transform
            syms s w z;
            obj.DefaultVars.s = s;
            obj.DefaultVars.w = w;
            obj.DefaultVars.z = z;
            obj.Symbols('s') = s;
            obj.Symbols('w') = w;
            obj.Symbols('z') = z;
        end
        function initDefaultUnits(obj)
            obj.DefaultUnits.K =  1e3;
            obj.DefaultUnits.M =  1e6;
            obj.DefaultUnits.G =  1e9;
            obj.DefaultUnits.m =  1e-3;
            obj.DefaultUnits.u =  1e-6;
            obj.DefaultUnits.n =  1e-9;
            obj.DefaultUnits.p =  1e-12;
            obj.DefaultUnits.f =  1e-15;
        end
        %  ...
        function symVar = registerVar(obj, name, assumption)
            %   register from string
            if isKey(obj.Symbols, name)
                %   Fuck Matlab r2022a, can't use isKey()!!!
                symVar = obj.Symbols(name);
                return;
            end
            if nargin < 3 || isempty(assumption)
                symVar = sym(name);
            else
                symVar = sym(name, assumption);
            end
            obj.Symbols(name) = symVar;
        end
        function registerFromSF(obj, symNames)
            %   register from SFP.symNames
            for i = 1:length(symNames)
                obj.registerVar(symNames{i});
            end
        end
        function replaceValuesUnits(obj)
            for i = 1:size(obj.Values, 1)
                values = obj.Values{i, 2};
                value = values(1:end-1);
                value = str2double(value);
                units = values(end);
                switch units
                    case 'k'
                        values = value * obj.DefaultUnits.K;
                    case 'M'
                        values = value * obj.DefaultUnits.M; 
                    case 'G'
                        values = value * obj.DefaultUnits.G;
                    case 'm'
                        values = value * obj.DefaultUnits.m;
                    case 'u'
                        values = value * obj.DefaultUnits.u;
                    case 'n'
                        values = value * obj.DefaultUnits.n;
                    case 'p'
                        values = value * obj.DefaultUnits.p;
                    case 'f'
                        values = value * obj.DefaultUnits.f; 
                end
                obj.Values(i, 2) = {values};
            end
        end








        

    end
end



