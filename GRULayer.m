classdef GRULayer < handle
    %GRULAYER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        Wr, Wz, Wh
        Rr, Rz, Rh
        Bwr, Bwz, Bwh
        Brr, Brz, Brh
        State
        NumHiddenUnits
    end
    
    methods
        function obj = GRULayer(inputKernel, recurrentKernel, bias)
            %GRULAYER Construct an instance of this class
            %   Detailed explanation goes here
            obj.NumHiddenUnits = length(bias)/3;
            obj.State = zeros(1, obj.NumHiddenUnits);
            
            %MATLAB ORDER: r, z, h
            %KERAS ORDER: z, r, h
            
            zidx = 1:obj.NumHiddenUnits;
            ridx = obj.NumHiddenUnits+1:obj.NumHiddenUnits*2;
            hidx = obj.NumHiddenUnits*2+1:obj.NumHiddenUnits*3;
            
            inputKernel = double(inputKernel);
            recurrentKernel = double(recurrentKernel);
            bias = double(bias);
            
            obj.Wz = inputKernel(:,zidx);
            obj.Wr = inputKernel(:,ridx);
            obj.Wh = inputKernel(:,hidx);
            
            obj.Rz = recurrentKernel(:,zidx);
            obj.Rr = recurrentKernel(:,ridx);
            obj.Rh = recurrentKernel(:,hidx);
            
            obj.Bwz = bias(1,zidx);
            obj.Bwr = bias(1,ridx);
            obj.Bwh = bias(1,hidx);
            
            obj.Brz = bias(2,zidx);
            obj.Brr = bias(2,ridx);
            obj.Brh = bias(2,hidx);
        end
        
        function out = call(obj,in)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
            r = in * obj.Wr + obj.Bwr + obj.State * obj.Rr + obj.Brr;
            r = GRULayer.GateAct(r);
            
            z = in * obj.Wz + obj.Bwz + obj.State * obj.Rz + obj.Brz;
            z = GRULayer.GateAct(z);
            
            h = in * obj.Wh + obj.Bwh + r .* (obj.State * obj.Rh + obj.Brh);
            h = GRULayer.StateAct(h);
            h = (1 - z) .* h + z .* obj.State;
            
            obj.State = h;
            out = h;
        end
        
        function reset(obj)
            obj.State = zeros(1, obj.NumHiddenUnits);
        end
    end
    
    methods (Static)
        function out = GateAct(in)
            out = (1 + exp(-in)).^(-1);
        end
        
        function out = StateAct(in)
            out = tanh(in);
        end
    end
end

