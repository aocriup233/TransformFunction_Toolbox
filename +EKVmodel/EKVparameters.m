classdef EKVparameters < handle
    properties
        %  Basic MOSFET instance parameters
        L           %   Gate Length (m)
        W           %   Total Gate Width (m)
        NF = 1      %   Number of Fingers
        M = 1       %   Multiplicity Factor
        %  Junction diodes geometric charactristics
        AS = 0      %   Area of Source Active Area (m^2)
        AD = 0      %   Area of Drain Active Area (m^2)
        PS = 0      %   Perimeter of Sourse Active Area (m)
        PD = 0      %   Perimeter of Drain Active Area (m)
        %  Shallow trench isolation stress effect
        SA = 0      %   Distance of first gate finger from STI (one side) (m)
        SB = 0      %   Distance of last gate finger from STI (one side) (m)
        SD = 0      %   Distance between neighbouring gate fingers
        %  Flags and Setup Parameters
        SIGN = 1    %   1 for NMOS, -1 for PMOS
        TG = -1     %   Doping Type of Gate, -1 for opposite than bulk, 1 for same with bulk 0 for metal gate; no polysilicon depletion effect
        TNOM = 27   %   Nominal Temperature (C)
        %  Process geometrical scaling
        SCALE = 1   %   Scaling Factor for all dimensions
        XL = 0      %   Optical offset for gate Length (m)
        XW = 0      %   Optical offset for Gate Width (m)
        %  Noise flag Parameters
        TH_NOI = 1  %   Thermal noise flag (on/off). Includes short channel effects but no NQS noise
        NQS_NOI = 0 %   NQS noise flag (on/off). Includes thermal noise without short channel effects
        %  Matching Parameters
        AVT0 = 0    %   Matching Parameter for Threshold Voltage
        AGAMMA = 0  %   Matching Parameter for Body Effect Coefficient
        AKP = 0     %   Matching Parameter for Mobility(\miu)        
        %  Oxide, Substrate and Gate Doping related Parameters
        COX         %   Oxide Capacitance per unit Area (F/m^2)
        XJ          %   Depth of Active Areas (m)
        Vt0         %   Threshold Voltage (V)
        PHIF        %   Bulk Fermi Potential (V)
        GAMMA       %   Body Effect Coefficient (V^1/2)
        GAMMAG      %   Body Effect Coefficient for Gate (V^1/2)
        N0          %   Long Channel Slope Factor Fine Tuning
        VBI         %   Built-in Voltage Drop (V)
        %  Quantum Effects
        AQMA = 0.5  %   Quantum Effect Coefficient in Accumulation (V^1/3*F^-2/3)
        AQMI = 0.4  %   Quantum Effect Coefficient in Inversion (V^1/3*F^-2/3)
        ETAQM = 0.75%   Quantum Effect: Weight of inversion charge in effective vertical field calculation
        %  Mobilty and Vertical field Mobility Effect
        KP          %   Mobility multiplied with COX (F/(V*s))
        E0 = 10e9   %   First Order Coefficient for Mobility Reduction due to Vertical Field (V/m)
        E1 = 310e6  %   Second Order Coefficient for Mobility Reduction due to Vertical Field (V^2/m^2)
        ETA = 0.5   %   Weight of inversion charge into calculation of vertical field
        %  Coulomb Scattering
        THC = 0     %   Coulomb Scattering Factor
        ZC = 1e-6   %   Coulomb Scattering coefficient for normolized inversion charge
        %  Drain Induced Threshold Swift (DITS)
        FPROUT = 1e6%   Output resistance factor for DITS effect (m^-1/2)
        PDITS = 0   %   DITS parameter
        PDITSL = 0  %   Length scaling factor for DITS effect (1/m)
        PDITSD = 1  %   DITS dependence on drain bias (1/V)
        DDITS = 0.3 %   Smoothing parameter for DITS effect
        %  Small Dimensions Geometrical Parameters
        DL = -10e-9 %   Difference between effective and drawn gate length (m)
        DLC = 0     %   Fine tuning difference of effective gate length between current and capacitance behaviour (m)
        DW = -10e-9 %   Difference between effective and drawn gate width (m)
        DWC = 0     %   Fine tuning difference of effective gate width between current and capacitance behaviour (m)
        WDL = 0     %   Width scaling for narrow devices of Leff (m^2)
        LDW = 0     %   Length scaling for short devices of Weff (m^2)
        LL = 0      %   Base for Exponential Dependence of Leff (m)
        LLN = 1     %   Exponent for Exponential Dependence of Leff
        %  Reverse Short Channel Effect (RSCE)
        LR = 50e-6  %   Length scaling coefficient for RSCE (m)
        QLR = 0.5e-3%   Threshold Voltage coefficient for RSCE (V*m^2/F)
        NLR = 10e-3 %   Body Effect coefficient for RSCE (m^2/F)
        FLR = 0     %   Fermi Potential coefficient for RSCE
        %  Charge Sharing (CHSH)
        LETA = 0.5  %   CHSH coefficient
        LETA0 = 0   %   Length indepedent CHSH coefficient (1/m)
        LETA2 = 0   %   Second order length scaling CHSH coefficient (m)
        WETA = 0.2  %   Narrow Channel CHSH coefficient
        NCS = 1     %   Slope Factor Dependence on CHSH
        %  Drain Induced Barrier Lowing (DIBL)
        ETAD = 1    %   DIBL coefficient
        SIGMAD = 1  %   Body effect DIBL coefficient
        %  Velocity Saturation (VSAT) and Channel Length Modulation (CLM)
        UCRIT = 5e6 %   Critical longitudinal field of Carriers for VSAT (V/m)
        LAMBDA = 0.5%   Length Modulation coefficient
        DELTA = 2   %   Order of VSAT model (1~2)
        ACLM = 0.83 %   Channel Length Modulation Factor
        %  Inverse Narrow Width Effect (INWE)
        WR = 90e-9  %   Width scaling coefficient for INWE (m)
        QWR = 0.3e-3%   Threshold Voltage coefficient of INWE (V*m^2/F)
        NWR = 5e-3  %   Body Effect coefficient for INWE (m^2/F)
        %  Impact Ionization Current (IDB)
        IBA = 0     %   IDB coefficient (1/m)
        IBB = 300e6 %   IDB exponential factor (V/m)
        IBN = 1     %   IDB factor of VSAT
        %  Gate Current (IG)
        XB = 3.1    %   Si-SiO2 tunning barrier height (V)
        EB = 29e9   %   Characteristic electrical field of gate current (V/m)
        KG = 0      %   Gate Current Parameter (A/V^2)
        LOVIG = 20e-9 % Overlap Length for Gate Current (m)
        %  Gate Induced Drain and Source Leakage (GIDL)
        AGIDL = 0   %   Pre-exponential coefficient for GIDL (A/V)
        BGIDL = 2.3e9 % Exponential coefficient for GIDL (V/m)
        CGIDL = 0.5 %   Body effect parameter for GIDL (V^3)
        EGIDL = 0.8 %   Fitting parameter for band bending for GIDL (V)
        %  Edge Conductance Effect
        WEDGE = 0   %   Width of Edge Conductance area (m)
        DPHIEDGE = 0 %  Difference of Fermi protential of Edge Conductance area with respect to the main part of channel (V)
        DGAMMAEDGE = 0 % Difference of Body Effect coefficient between edge conduction area the main channel (V^1/2)
        %  Inner Fringing Capacitance
        KJF = 0     %   Fringing Capacitance factor (C/m)
        CJF = 0     %   Fringing Capacitance bias factor (1/V)
        VFR = 0     %   Built-in correction for Fringing Capacitance (V)
        DFR = 1e-3  %   Smooth factor of Fringing Capacitance model
        %  STI Stress Effect
        SAREF = 0   %   Reference distance from STI, for SA (m)
        SBREF = 0   %   Reference distance from STI, for SB (m)
        WLOD = 0    %   Distance between the edge device and the STI (m)
        KKP = 0     %   KP dependence on STISE
        KVT0 = 0    %   VT0 dependence on STISE
        KGAMMA = 0  %   GAMMA dependence on STISE
        KETAD = 0   %   ETAD (DIBL effect) dependence on STISE
        LKKP = 0    %   Length scaling of KP dependence on STISE
        WKKP = 0    %   Width scaling of KP dependence on STISE
        PKKP = 0    %   Area scaling of KP dependence on STISE
        TKKP = 0    %   Temperature scaling of KP dependence on STISE
        LLODKKP = 0 %   Length exponent of KP dependence on STISE
        WLODKKP = 0 %   Width exponent of KP dependence on STISE
        LKVT0 = 0   %   Length scaling of VT0 dependence on STISE
        WKVT0 = 0   %   Width scaling of VT0 dependence on STISE
        PKVT0 = 0   %   Area scaling of VT0 dependence on STISE
        LLODKVT0 = 0 %  Length exponent of VT0 dependence on STISE
        WLODKVT0 = 0 %  Width exponent of VT0 dependence on STISE
        LODKGAMMA = 0 % Exponent of GAMMA dependence on STISE
        LODKETAD = 0 %  Exponent of ETAD dependence on STISE
        %  Length, Width and area Scaling Parameters
        LA = 1      %   First critical length for KP length scaling (m)
        LB = 1      %   Second critical length for KP length scaling (m)
        KA = 0      %   Factor for KP length scaling for LA
        KB = 0      %   Factor for KP length scaling for LB
        WKP1 = 1e-6 %   Width parameter for mobility profile vs. width (m)
        WKP2 = 0    %   Amplitude parameter for mobility profile vs. width
        WKP3 = 0    %   Span parameter for mobility profile vs. width


        %  prefixes
        prefixes = struct( ...
            'm' , 1e-3 , ...
            'u' , 1e-6 , ...
            'n' , 1e-9 , ...
            'p' , 1e-12, ...
            'f' , 1e-15, ...
            'k' , 1e3  , ...
            'M' , 1e6  , ...
            'G' , 1e9  , ...
            'T' , 1e12)
    end
end
    

        
        
