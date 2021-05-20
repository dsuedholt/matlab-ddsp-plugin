classdef MLPLayer < handle
% MLPLAYER A single layer of an inference-only multi-layer perceptron. 
%
%  This layer form the building block of the feed-forward stack used in the 
%  decoder. It consists of a dense layer, followed by layer normalization,
%  followed by leaky ReLU.

    properties (Access = private)
        Kernel, Bias;         % weights of the dense layer
        Beta, Gamma, Epsilon; % weights for the layer normalization
        Alpha;                % factor of the leaky ReLU
    end
    
    methods
        function obj = MLPLayer(kernel, bias, beta, gamma, epsilon, alpha)
            % Initialize given weights
            
            % explicitly require double for code generation
            obj.Kernel = double(kernel);
            obj.Bias = double(bias);
            obj.Beta = double(beta);
            obj.Gamma = double(gamma);
            
            if nargin > 4
                obj.Epsilon = epsilon;
                obj.Alpha = alpha;
            else
                % The default values used in the tensorflow implementation
                obj.Epsilon = 1e-3;
                obj.Alpha = 0.2;
            end
        end
        
        function out = call(obj, in)
            % dense layer
            out = in * obj.Kernel + obj.Bias;
    
            % layer normalization
            
            % first normalize by mean and variance of current input
            out = (out - mean(out)) / sqrt(var(out) + obj.Epsilon);
            
            % then apply learned scaling and offset
            out = obj.Gamma .* out + obj.Beta;

            % Non-Linearity: Leaky ReLU
            out(out < 0) = out(out < 0) * obj.Alpha;
        end 
    end
end

