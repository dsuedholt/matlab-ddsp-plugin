classdef ddspPlugin < audioPlugin
    
    properties (Access = private, Constant)
        BufSize = 20000;
    end
    
    properties (Access = private)
        Dec;
        Synth;
        InBuf;
        OutBuf;
        currFrameSize;
        currL;
        prevF0 = ddspPlugin.F0MIN;
        nls;
    end
    
    properties
        L = 2;
        Ld = 1;
        F0low = 27;
        F0high = 4800;
        FrameSize = 512;
    end
    
    properties (Constant)
        LDMIN = -120;
        LDMAX = 0;
        % Midi piano keyboard range
        F0MIN = 27;
        F0MAX = 4800;
        
        PluginInterface = audioPluginInterface( ...
            'InputChannels', 1, ...
            'OutputChannels', 1, ...
            audioPluginParameter('F0low', ...
                'DisplayName', 'Lower Freq Bound', ...
                'Mapping', {'log', ddspPlugin.F0MIN, ddspPlugin.F0MAX}), ... 
                audioPluginParameter('F0high', ...
                'DisplayName', 'Upper Freq Bound', ...
                'Mapping', {'log', ddspPlugin.F0MIN, ddspPlugin.F0MAX}), ... 
            audioPluginParameter('L', ...
                'DisplayName', 'Model Order', ...
                'Mapping', {'int', 2, 10}), ...
            audioPluginParameter('Ld', ...
                'DisplayName', 'input gain', ...
                'Mapping', {'log', 0.001, 100}),...
            audioPluginParameter('FrameSize', ...
                'DisplayName', 'Frame Size', ...
                'Mapping', {'int', 64, 2048}));
    end
    
    methods
        function plugin = ddspPlugin
            plugin.Dec = Decoder(plugin.ModelFile);
            plugin.Synth = SpectralModelingSynth;
            plugin.InBuf = CircularBuffer(plugin.BufSize);
            plugin.OutBuf = CircularBuffer(plugin.BufSize, plugin.FrameSize);
            plugin.nls = fastNLS(512, 5, [0.1, 0.2]);
            plugin.currFrameSize = plugin.FrameSize;
            plugin.currL = plugin.L;
        end
      
        function out = process(plugin, in)
            if (plugin.L ~= plugin.currL)...
                || (plugin.FrameSize ~= plugin.currFrameSize)
                plugin.reset;
            end
            plugin.InBuf.write(plugin.Ld * in);
            plugin.generateAudio();
            out = plugin.OutBuf.read(length(in));
        end

        function reset(plugin)
            plugin.currL = plugin.L;
            plugin.currFrameSize = plugin.FrameSize;

            plugin.Dec.reset;
            plugin.InBuf.reset;
            plugin.OutBuf.reset(plugin.FrameSize);
            freqmin = plugin.F0MIN / plugin.getSampleRate;
            freqmax = plugin.F0MAX / plugin.getSampleRate;
            plugin.nls.reset(plugin.FrameSize, plugin.L, [freqmin, freqmax]);
        end
        
        function generateAudio(plugin)
            sampleRate = plugin.getSampleRate;
            
            while plugin.InBuf.nElems >= plugin.FrameSize
                in = plugin.InBuf.read(plugin.FrameSize);
                
                power = sum(in.^2) / plugin.FrameSize;

                ld = -0.691 + 10*log10(power);

                ldScaled = ld / (plugin.LDMAX - plugin.LDMIN) + 1;

                f0 = plugin.nls.estimate(in) * sampleRate;
                f0 = f0(1);
                if isnan(f0)
                    f0 = plugin.prevF0;
                end
                plugin.prevF0 = f0;
                f0Scaled = hzToMidi(f0) / 127;

                decoderOut = plugin.Dec.call(ldScaled, f0Scaled);
                
                amps = decoderOut(1);
                harmDist = decoderOut(2:61);
                noiseMag = decoderOut(62:126);

                frame = plugin.Synth.getAudio(f0, amps, harmDist, noiseMag, sampleRate, plugin.FrameSize); 
                plugin.OutBuf.write(frame);
            end
        end
    end
    
end

function midi = hzToMidi(hz)
    midi = 12 * (log2(hz) - log2(440)) + 69;
    midi(midi < 0) = 0;
end