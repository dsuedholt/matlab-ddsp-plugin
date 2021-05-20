classdef Decoder < handle
% DECODER Construct the decoder part of the DDSP Autoencoder from a file of
% weights
%
%  This class loads its model weights from the supplied .mat file and 
%  constructs the inference-only decoder network of the DDSP Autoencoder.
%  
%  Given normalized values for loudness and pitch, the decoder predicts an 
%  amplitude, a harmonic distribution and a filter magnitude response that 
%  can be used by the SpectralModelingSynth to generate a frame of audio.
%
%  This decoder implements the RnnFcDecoder class from the DDSP python
%  code: Loudness and pitch values are passed through their respective
%  stacks of feed-forward layers (the number of layers is fixed here
%  because of coder restrictions). The output of the two stacks is then
%  concatenated and passed through a recurrent layer, whose output is used
%  to predict the synthesizer parameters.

    properties (Access = private)
        LdLayer1, LdLayer2, LdLayer3;    % Feed-forward stack for loudness
        F0Layer1, F0Layer2, F0Layer3;    % Feed-forward stack for f0
        GRU;                             % Recurrent layer  
        OutLayer1, OutLayer2, OutLayer3; % Feed-forward stack for the GRU output
        OutProjKernel, OutProjBias;      % Final projection layer
    end

    properties (Constant)
        nHarmonics = 60;  % Number of harmonics for the additive synthesis
        nMagnitudes = 65; % Number of magnitudes for the filtered noise
    end
    
    methods
        function obj = Decoder(weightfile)
            % The constructor reads a supplied .mat file and loads all
            % weights into their respective layers.
            
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
        
        function [amp, harmDist, noiseMags] = call(obj, ld, f0)
            % Predict synthesizer parameters for one frame of audio.
            % Inputs:
            %    ld   : normalized loudness in dB
            %    f0   : normalized pitch
            % 
            % Outputs:
            %    amp      : The overall amplitude for the additive synthesis
            %    harmDist : The amplitudes of the individual harmonics
            %    noiseMags: The magnitude response of the filter applied to
            %               white noise
            
          
            % pass inputs through feed-forward stacks
            ld = obj.LdLayer1.call(ld);
            ld = obj.LdLayer2.call(ld);
            ld = obj.LdLayer3.call(ld);

            f0 = obj.F0Layer1.call(f0);
            f0 = obj.F0Layer2.call(f0);
            f0 = obj.F0Layer3.call(f0);
            
            % concatenate and pass through recurrent layer
            out = [ld f0];
            out = [out obj.GRU.call(out)];
            
            % pass through output stack and projection
            out = obj.OutLayer1.call(out);
            out = obj.OutLayer2.call(out);
            out = obj.OutLayer3.call(out);
            out = out * obj.OutProjKernel + obj.OutProjBias;
            
            % extract parameters from projecteed output
            amp = out(1);
            harmDist = out(2:obj.nHarmonics+1);
            noiseMags = out(obj.nHarmonics+2:end);
        end
        
        function reset(obj)
            % Reset the internal state of the recurrent layer
            obj.GRU.reset;
        end
    end
end