classdef ddspPlugin < audioPlugin
    
    properties (Access = private, Constant)
        BufSize = 20000;
    end
    
    properties (Access = private)
        Dec;
        Synth;
        InBuf;
        OutBuf;
        nls;
    end
    
    properties
        L = 1;
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
                'Mapping', {'int', 1, 10}), ...
            audioPluginParameter('Ld', ...
                'DisplayName', 'input gain', ...
                'Mapping', {'log', 0.001, 100}),...
            audioPluginParameter('FrameSize', ...
                'DisplayName', 'Frame Size', ...
                'Mapping', {'int', 64, 2048}));
    end
    
    methods
        function plugin = ddspPlugin
            plugin.Dec = Decoder('violinWeights.mat');
            plugin.Synth = SpectralModelingSynth;
            plugin.InBuf = CircularBuffer(plugin.BufSize);
            plugin.OutBuf = CircularBuffer(plugin.BufSize, plugin.FrameSize);
        end
      
        function out = process(plugin, in)
            plugin.InBuf.write(plugin.Ld * in);
            plugin.generateAudio();
            out = plugin.OutBuf.read(length(in));
        end

        function generateAudio(plugin)
            sampleRate = plugin.getSampleRate;
            
            while plugin.InBuf.nElems >= plugin.FrameSize
                in = plugin.InBuf.read(plugin.FrameSize);
                
                power = sum(in.^2) / plugin.FrameSize;

                ld = -0.691 + 10*log10(power);

                ldScaled = ld / (plugin.LDMAX - plugin.LDMIN) + 1;

                ls = 1:plugin.L;
                
                nFft = 5*plugin.FrameSize*plugin.L;
                spec = abs(fft([in; zeros(nFft - plugin.FrameSize, 1)])).^2;

                kstart = floor(nFft * plugin.F0low / sampleRate);
                kstop = ceil(nFft * plugin.F0high / sampleRate);

                if (kstart > kstop)
                    kstart=kstop-1;
                end

                bestk = 0;
                bestval = 0;
                for i=kstart:kstop
                    if (i+1) * ls(end) > nFft
                        ls = ls(1:end-1);
                    end
                    val = sum(spec((i+1)*ls));
                    if val > bestval
                        bestk = i;
                        bestval = val;
                    end
                end

                f0 = sampleRate * bestk / nFft;
                f0Scaled = hzToMidi(f0(1)) / 127;

                decoderOut = plugin.Dec.call(ldScaled, f0Scaled);
                
                amps = decoderOut(1);
                harmDist = decoderOut(2:61);
                noiseMag = decoderOut(62:126);

                frame = plugin.Synth.getAudio(f0(1), amps, harmDist, noiseMag, sampleRate, plugin.FrameSize); 
                plugin.OutBuf.write(frame);
            end
        end
    end
    
end

function midi = hzToMidi(hz)
    midi = 12 * (log2(hz) - log2(440)) + 69;
    midi(midi < 0) = 0;
end