classdef TFAnalyzer < handle
    properties
        TransformFunction
        SymVar = []
        paramRange
        TFsimplifier
    end
    methods
        function obj = TFAnalyzer(TF, unsubVars, TFsimplifier, paramRange)
            %   get unsubVars from TFsimplifier.batchSubs to sweep Vars for
            %   .AC .stb analysis
            obj.TransformFunction = TF;
            if length(unsubVars) == 1
                obj.SymVar = unsubVars;
            end
            obj.TFsimplifier = TFsimplifier;
            if nargin > 3
                obj.paramRange = paramRange;
            end
            %   params must be a vector. (ex. 1:1:100)
        end
        function result = realizeTF(obj, option, Var)
            result = {};
            if isempty(obj.SymVar)
                sys = obj.sym2tf(obj.TransformFunction, Var);
                switch option
                    case 'Bode'
                        result = obj.plotBode(sys);
                    case 'Nyquist'
                        result = obj.plotNyquist(sys);
                    case 'PZ'
                        obj.plotPZmap(sys);
                end
            else
                switch option
                    case 'RLocus'
                        obj.plotRLocus(obj.TransformFunction, Var);
                    case 'PMvsGX'
                        obj.plotPMvsGx(obj.TransformFunction, Var);
                end
            end
        end
        function sys = sym2tf(obj, TF, Var, timeUnits)
            %   expand to Z-transform
            if strcmpi(Var, 's')
                [num, den] = numden(TF);
                numcoeffs = flipud(double(coeffs(num, 'All')));
                dencoeffs = flipud(double(coeffs(den, 'All')));
                sys = tf(numcoeffs, dencoeffs);
            elseif strcmpi(Var,'z') && varargin > 3
                [num, den] = numden(TF);
                numcoeffs = flipud(double(coeffs(num, 'All')));
                dencoeffs = flipud(double(coeffs(den, 'All')));
                sys = tf(numcoeffs, dencoeffs, timeUnits);
            end
        end
        function result = plotBode(obj, sys)
            figure('Name', 'Bode Analysis', 'Position', [100 100 800 600]);
            bode(sys);
            grid on;
            title('Bode Analysis');
            margin(sys);
            [GM, PM, Wcg, Wcp] = margin(sys);
            Px = Wcg /(2*pi);
            Gx = Wcp /(2*pi);
            result = {};
            result.GM = [sprintf('%.4f', GM), 'dB'];
            result.PM = [sprintf('%.4f', PM), 'deg'];
            result.Gx = [sprintf('%1.4e', Gx), 'Hz'];
            result.Px = [sprintf('%1.4e', Px), 'Hz'];
        end
        function result = plotNyquist(obj, sys)
            figure('Name', 'Nyquist Analysis', 'Position', [150 150 700 600]);
            nyquist(sys);
            grid on;
            axis equal;
            title('Nyquist Analysis');
            [GM, PM, Wcg, Wcp] = margin(sys);
            Px = Wcg /(2*pi);
            Gx = Wcp /(2*pi);
            result = {};
            result.GM = [sprintf('%.4f', GM), 'dB'];
            result.PM = [sprintf('%.4f', PM), 'deg'];
            result.Gx = [sprintf('%1.4e', Gx), 'Hz'];
            result.Px = [sprintf('%1.4e', Px), 'Hz'];
        end
        function plotPZmap(obj, sys)
            figure('Name', 'Pole-Zero Map', 'Position', [200 200 600 500]);
            pzmap(sys);
            grid on;
            title('Pole-Zero Map');
        end
        function plotRLocus(obj, sys, Var)
            if strcmpi(obj.SymVar, 'k') || isempty(obj.SymVar)
                figure('Name', 'Root Locus', 'Position', [100 100 800 600]);
                rlocus(sys);
                grid on;
                title('Root Locus');
                return;
            end
            varName = char(obj.SymVar);
            allPoles = [];
            allZeros = [];
            for i = 1:length(obj.paramRange)
                sys_i = simplify(subs(sys, varName, obj.paramRange(i)));
                try
                    [~, p, z, ~] = obj.TFsimplifier.calculateValueTF(sys_i, [], Var);
                    if isempty(allPoles)
                        nPoles = length(p);
                        nZeros = length(z);
                        allPoles = zeros(length(obj.paramRange), nPoles);
                        allZeros = zeros(length(obj.paramRange), nZeros);
                    end
                    allZeros(i, :) = z(:)';
                    allPoles(i, :) = p(:)';
                catch
                    continue;
                end
            end
            figure('Name', sprintf('Root Locus (sweep : %s)', varName), ...
                'Position', [100 100 900 700]);
            hold on;
            allZeros = complex(allZeros);
            allPoles = complex(allPoles);
            for i = 1:size(allPoles, 2)
                valid = ~isnan(allPoles(:,i));
                h = scatter(real(allPoles(valid,i)), imag(allPoles(valid,i)), 10, 'o');
                set(h, 'CData', obj.paramRange(valid));
            end
            for i = 1:size(allZeros, 2)
                valid = ~isnan(allZeros(:,i));
                h = scatter(real(allZeros(valid,i)), imag(allZeros(valid,i)), 10, '+');
                set(h, 'CData', obj.paramRange(valid));
            end
            colormap("turbo");
            c = colorbar;
            c.Label.String = sprintf('Para. %s', varName);
            caxis([min(obj.paramRange) max(obj.paramRange)]);
            xlabel('Real Axis');
            ylabel('Imaginary Axis');
            title(sprintf('Root Locus vs Sweep %s', varName));
            grid on;
            axis equal;
        end
        function plotPMvsGx(obj, sys, Var)
            varName = char(obj.SymVar);
            PM_values = [];
            GX_values = [];
            validParams = [];
            for i = 1:length(obj.paramRange)
                sys_i = simplify(subs(sys, varName, obj.paramRange(i)));
                sys_i = obj.sym2tf(sys_i, Var);
                try
                    [~, PM, ~, Wcp] = margin(sys_i);
                    Gx = Wcp / (2*pi);
                    if ~isinf(PM) && ~isnan(PM) && PM > 0
                        PM_values = [PM_values, PM];
                        GX_values = [GX_values, Gx];
                        validParams = [validParams, obj.paramRange(i)];
                    end
                catch
                    continue;
                end
            end
            if isempty(PM_values)
                return;
            end
            figure('Name', sprintf('PM vs GX (sweep : %s)', varName), ...
                'Position', [150 150 1000 400]);
            subplot(1, 2, 1);
            scatter(validParams, PM_values, [], obj.paramRange, "filled");
            xlabel(sprintf('%s', varName));
            ylabel('Phase Margin (deg)');
            title(sprintf('%s', varName), 'vs PM');
            grid on;
            subplot(1, 2, 2);
            scatter(GX_values, PM_values, [], obj.paramRange, 'filled');
            colormap("winter");
            xlabel('GBW (Hz)');
            ylabel('Phase Margin (deg)');
            title('GBW vs PM');
            grid on;
        end
        function plotSmithChart(obj)
            %   expand for RF IC
        end
    end
end