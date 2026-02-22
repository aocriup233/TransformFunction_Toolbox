classdef mosfet_model < handle
    properties
        Name
        ID
        Type = ''
        Nodes = struct()
        Edges = struct()
        DesignVariable = struct()
        ModelSelect = 'Square Law'
        ModelParam = struct()
        IsSmallSignalModel = true
        % using 'Square Law' 'EKV' 'BSIM' to select Model
    end
    methods
        function obj = mosfet_model(Name, ID)
            obj.Name = Name;
            obj.ID = ID;
            % Node voltage is the voltage relative to ground, 
            % and node current is the inflow current and is positive.
            obj.Nodes.B = struct('Voltage', [], 'Current', [], 'Connect', '');
            obj.Nodes.G = struct('Voltage', [], 'Current', [], 'Connect', '');
            obj.Nodes.D = struct('Voltage', [], 'Current', [], 'Connect', '');
            obj.Nodes.S = struct('Voltage', [], 'Current', [], 'Connect', '');
        end
        function initEdges(obj, ModelSelect)
            if nargin > 1
                switch ModelSelect
                    case 'Square Law'
                        obj.initBasicModel();
                    case 'EKV'
                        obj.initBasicModel();
                    case 'BSIM'
                        obj.initBSIMEdge();
                end
            else
                obj.initBasicModel();
            end
        end
        function initBasicModel(obj)
            obj.Edges.GB = struct('Voltage', [], 'Current', [], 'Model', struct());
            obj.Edges.DB = struct('Voltage', [], 'Current', [], 'Model', struct());
            obj.Edges.SB = struct('Voltage', [], 'Current', [], 'Model', struct());
            obj.Edges.GS = struct('Voltage', [], 'Current', [], 'Model', struct());
            obj.Edges.GD = struct('Voltage', [], 'Current', [], 'Model', struct());
            obj.Edges.DS = struct('Voltage', [], 'Current', [], 'Model', struct());
        end
        function initBSIMEdge(obj)
            obj.Edges.BG = struct('Voltage', [], 'Current', [], 'Model', struct());
            obj.Edges.GB = struct('Voltage', [], 'Current', [], 'Model', struct());
            obj.Edges.BD = struct('Voltage', [], 'Current', [], 'Model', struct());
            obj.Edges.DB = struct('Voltage', [], 'Current', [], 'Model', struct());
            obj.Edges.BS = struct('Voltage', [], 'Current', [], 'Model', struct());
            obj.Edges.SB = struct('Voltage', [], 'Current', [], 'Model', struct());
            obj.Edges.GS = struct('Voltage', [], 'Current', [], 'Model', struct());
            obj.Edges.SG = struct('Voltage', [], 'Current', [], 'Model', struct());
            obj.Edges.GD = struct('Voltage', [], 'Current', [], 'Model', struct());
            obj.Edges.DG = struct('Voltage', [], 'Current', [], 'Model', struct());
            obj.Edges.DS = struct('Voltage', [], 'Current', [], 'Model', struct());
            obj.Edges.SD = struct('Voltage', [], 'Current', [], 'Model', struct());
        end
        function [ids, Vt, Region, gm, gds, gmb] = calcBasic(obj)
            % calculate Ids using Square Law
            switch obj.Type
                case 'NMOS'
                    vt0 = obj.ModelParam.vt0(1);
                    gamma = obj.ModelParam.gamma(1);
                    phi = obj.ModelParam.phi(1);
                    lambda = obj.ModelParam.lambda(1);
                    u = obj.ModelParam.miu(1);
                    Cox = obj.ModelParam.Cox(1);
                    Vgs = double(obj.Nodes.G.Voltage - obj.Nodes.S.Voltage);
                    Vds = double(obj.Nodes.D.Voltage - obj.Nodes.S.Voltage);
                    Vsb = double(obj.Nodes.S.Voltage - obj.Nodes.B.Voltage);
                case 'PMOS'
                    vt0 = obj.ModelParam.vt0(2);
                    gamma = obj.ModelParam.gamma(2);
                    phi = obj.ModelParam.phi(2);
                    lambda = obj.ModelParam.lambda(2);
                    u = obj.ModelParam.miu(2);
                    Cox = obj.ModelParam.Cox(2);
                    Vgs = double(obj.Nodes.S.Voltage - obj.Nodes.G.Voltage);
                    Vds = double(obj.Nodes.S.Voltage - obj.Nodes.D.Voltage);
                    Vsb = double(obj.Nodes.B.Voltage - obj.Nodes.S.Voltage);
            end
            Vt = vt0 + gamma*(sqrt(2*phi+Vsb)-sqrt(2*phi));
            W = obj.DesignVariable.W * obj.DesignVariable.M;
            L = obj.DesignVariable.L;
            Vov = Vgs - Vt;
            if Vgs < Vt
                Region = 0;
                ids = 0;
                gm = 0;
                gds = inf;
            elseif Vgs >= Vt
                if Vds < Vov
                    Region = 1;
                    ids = u*Cox*W/L*(Vov*Vds-0.5*Vds^2);
                    gm = u*Cox*W/L*Vds;
                    gds = u*Cox*W/L*(Vov-Vds);
                elseif Vds >= Vov
                    Region = 2;
                    ids = 0.5*u*Cox*W/L*Vov^2*(1+lambda*Vds);
                    gm = u*Cox*W.L*Vov*(1+lambda*Vds);
                    gds = 1/(lambda*ids);
                end
            end
            gmb = gm*gamma/(2*sqrt(2*phi+Vsb));
        end
    end
end