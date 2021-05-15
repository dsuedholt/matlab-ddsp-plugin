classdef ddspPlugin < audioPlugin
    
    properties (Access = private, Constant)
        BufSize = 20000;
    end
    
    properties (Access = private)
        Dec;
        Synth;
        AudioBuf = zeros(ddspPlugin.BufSize, 1);
        BufIdx = 0;
    end
    
    properties
        Ld = -50;
        F0 = 440;
    end
    
    properties (Constant)
        LDMIN = -120;
        LDMAX = 0;
        % Midi piano keyboard range
        F0MIN = 27;
        F0MAX = 4187;
        
        PluginInterface = audioPluginInterface( ...
            audioPluginParameter('F0', ...
                'DisplayName', 'Frequency in Hz', ...
                'Mapping', {'log', ddspPlugin.F0MIN, ddspPlugin.F0MAX}), ... 
            audioPluginParameter('Ld', ...
                'DisplayName', 'Loudness in dB', ...
                'Mapping', {'lin', ddspPlugin.LDMIN, ddspPlugin.LDMAX})) 
    end
    
    methods
        function plugin = ddspPlugin
            plugin.Dec = Decoder('violinWeights.mat');
            plugin.Synth = SpectralModelingSynth;
        end
        
        function out = process(plugin, in)
            ldScaled = plugin.Ld / (plugin.LDMAX - plugin.LDMIN) + 1;
            f0Scaled = hzToMidi(plugin.F0) / 127;
            
            decoderOut = plugin.Dec.call(ldScaled, f0Scaled);
            
            nSamples = length(in);
            out = nan(size(in));
            sampleRate = plugin.getSampleRate();
            
            % 250 is the frame rate of the violin model
            frameSize = floor(sampleRate / 250);
            
            amps = decoderOut(1);
            harmDist = decoderOut(2:61);
            noiseMag = decoderOut(62:126);
            
            while plugin.BufIdx < nSamples
                frame = plugin.Synth.getAudio(plugin.F0, amps, harmDist, noiseMag, sampleRate, frameSize); 
                plugin.AudioBuf(plugin.BufIdx+1:plugin.BufIdx+frameSize) = frame;
                plugin.BufIdx = plugin.BufIdx + frameSize;
            end
            
            out(:,1) = plugin.AudioBuf(1:nSamples,:);
            out(:,2) = plugin.AudioBuf(1:nSamples,:);
            
            overflow = plugin.BufIdx - nSamples;
            plugin.AudioBuf(1:overflow) = plugin.AudioBuf(nSamples+1:plugin.BufIdx);
            plugin.BufIdx = overflow; % never negative because of while loop
        end
    end
end

function midi = hzToMidi(hz)
    midi = 12 * (log2(hz) - log2(440)) + 69;
    midi(midi < 0) = 0;
end