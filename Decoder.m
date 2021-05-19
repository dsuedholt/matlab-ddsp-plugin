classdef Decoder < handle
    properties (Access = private)
        LdLayer1, LdLayer2, LdLayer3
        F0Layer1, F0Layer2, F0Layer3
        GRU
        OutLayer1, OutLayer2, OutLayer3
        OutProjKernel, OutProjBias
    end

    methods
        function obj = Decoder(weightfile)
            w = coder.load(weightfile);
            
            obj.LdLayer1 = MLPLayer(w.ld_dense_0_kernel, w.ld_dense_0_bias,...
                w.ld_norm_0_beta, w.ld_norm_0_gamma);
            obj.LdLayer2 = MLPLayer(w.ld_dense_1_kernel, w.ld_dense_1_bias,...
                w.ld_norm_1_beta, w.ld_norm_1_gamma);
            obj.LdLayer3 = MLPLayer(w.ld_dense_2_kernel, w.ld_dense_2_bias,...
                w.ld_norm_2_beta, w.ld_norm_2_gamma);

            obj.F0Layer1 = MLPLayer(w.f0_dense_0_kernel, w.f0_dense_0_bias,...
                w.f0_norm_0_beta, w.f0_norm_0_gamma);
            obj.F0Layer2 = MLPLayer(w.f0_dense_1_kernel, w.f0_dense_1_bias,...
                w.f0_norm_1_beta, w.f0_norm_1_gamma);
            obj.F0Layer3 = MLPLayer(w.f0_dense_2_kernel, w.f0_dense_2_bias,...
                w.f0_norm_2_beta, w.f0_norm_2_gamma); 
            
            obj.OutLayer1 = MLPLayer(w.out_dense_0_kernel, w.out_dense_0_bias,...
                w.out_norm_0_beta, w.out_norm_0_gamma);
            obj.OutLayer2 = MLPLayer(w.out_dense_1_kernel, w.out_dense_1_bias,...
                w.out_norm_1_beta, w.out_norm_1_gamma);
            obj.OutLayer3 = MLPLayer(w.out_dense_2_kernel, w.out_dense_2_bias,...
                w.out_norm_2_beta, w.out_norm_2_gamma);
            
            obj.GRU = GRULayer(w.gru_kernel, w.gru_recurrent, w.gru_bias);
            
            obj.OutProjKernel = double(w.outsplit_kernel);
            obj.OutProjBias   = double(w.outsplit_bias);
        end
        
        function out = call(obj, ld, f0)
            ld = obj.LdLayer1.call(ld);
            ld = obj.LdLayer2.call(ld);
            ld = obj.LdLayer3.call(ld);

            f0 = obj.F0Layer1.call(f0);
            f0 = obj.F0Layer2.call(f0);
            f0 = obj.F0Layer3.call(f0);
            
            out = [ld f0];
            
            out = [out obj.GRU.call(out)];
            
            out = obj.OutLayer1.call(out);
            out = obj.OutLayer2.call(out);
            out = obj.OutLayer3.call(out);
            
            out = out * obj.OutProjKernel + obj.OutProjBias;
        end
        
        function reset(obj)
            obj.GRU.reset;
        end
    end
end