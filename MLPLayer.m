classdef MLPLayer < handle
    properties (Access = private)
        Kernel, Bias, Beta, Gamma, Epsilon, Alpha
    end
    
    methods
        function obj = MLPLayer(kernel, bias, beta, gamma, epsilon, alpha)
            obj.Kernel = double(kernel);
            obj.Bias = double(bias);
            obj.Beta = double(beta);
            obj.Gamma = double(gamma);
            
            if nargin > 4
                obj.Epsilon = epsilon;
                obj.Alpha = alpha;
            else
                obj.Epsilon = 1e-3;
                obj.Alpha = 0.2;
            end
        end
        
        function out = call(obj, in)
            out = in * obj.Kernel + obj.Bias;
    
            out = (out - mean(out)) / sqrt(var(out) + obj.Epsilon);
            out = obj.Gamma .* out + obj.Beta;

            out(out < 0) = out(out < 0) * obj.Alpha;
        end 
    end
end

