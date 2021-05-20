classdef GRULayer < handle
%GRULAYER A layer implementing a gated recurrent unit
%
%  This class implements an inference-only GRU Layer. The calculations
%  follow the 'recurrent-bias-after-multiplication' mode, described at 
%  https://mathworks.com/help/deeplearning/ref/nnet.cnn.layer.grulayer.html

    properties (Access = private)
        Wr, Wz, Wh;     % input weights
        Rr, Rz, Rh;     % recurrent weights
        Bwr, Bwz, Bwh;  % input biases
        Brr, Brz, Brh;  % recurrent biases
        State;          % hidden state
        NumHiddenUnits; 
    end
    
    methods
        function obj = GRULayer(inputKernel, recurrentKernel, bias)
            % The constructor loads the passed weight matrices
            % a tensorflow keras model, into the appropriate variables
            
            % Inputs:
            %   inputKernel  : The input weights of the GRU, of the shape
            %                  [inputSize, NumHiddenUnits*3]. Since the
            %                  weights come from keras, they are stacked in
            %                  the order [update; reset; candidate]
            %
            %   recurrentKernel : recurrent weights in the same shape as
            %                     inputKernel
            %
            %   bias        : The 6 different bias vectors, in the shape
            %                 [2, NumHiddenUnits*3]. First row for the
            %                 update biases, second row for the recurrent
            %                 biases
            
            obj.NumHiddenUnits = length(bias)/3;
            obj.State = zeros(1, obj.NumHiddenUnits);
            
            % indexing for the weights for the update gate
            zidx = 1:obj.NumHiddenUnits;
            
            % indexing for the weights for the reset gate
            ridx = obj.NumHiddenUnits+1:obj.NumHiddenUnits*2;
            
            % indexing for the weights for the candidate state
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
            % in: a row vector matching the input size determined by the 
            % weights of the layer
            
            % reset gate calculation
            r = in * obj.Wr + obj.Bwr + obj.State * obj.Rr + obj.Brr;
            r = GRULayer.gateAct(r);
            
            % update gate calculation
            z = in * obj.Wz + obj.Bwz + obj.State * obj.Rz + obj.Brz;
            z = GRULayer.gateAct(z);
            
            % candidate state calculation
            h = in * obj.Wh + obj.Bwh + r .* (obj.State * obj.Rh + obj.Brh);
            h = GRULayer.stateAct(h);
            
            % calculate hidden state at current time step
            h = (1 - z) .* h + z .* obj.State;
            
            % save and return hidden state
            obj.State = h;
            out = h;
        end
        
        function reset(obj)
            % reset the hidden state
            obj.State = zeros(1, obj.NumHiddenUnits);
        end
    end
    
    methods (Static)
        function out = gateAct(in)
            % Gate Activation function: sigmoid
            out = (1 + exp(-in)).^(-1);
        end
        
        function out = stateAct(in)
            % State Activation function: tanh
            out = tanh(in);
        end
    end
end

