classdef ddspPlugin < audioPlugin
    
    properties (Access = private)
        Dec;
        Synth;
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
            
            amps = decoderOut(1);
            harmDist = decoderOut(2:61);
            noiseMag = decoderOut(62:126);
            
            audio = plugin.Synth.getAudio(plugin.F0, amps, harmDist, noiseMag, sampleRate, nSamples);
            out(:,1) = audio;
            out(:,2) = audio;
        end
    end
end

function midi = hzToMidi(hz)
    midi = 12 * (log2(hz) - log2(440)) + 69;
    midi(midi < 0) = 0;
end