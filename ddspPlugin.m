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
        PrevFrame;
    end
    
    properties
        L = 2;
        FreqScale = 0;
        InGain = 0;
        OutGain = 0;
        FrameSize = 512;
        fftResol = 5;
    end
    
    properties (Constant)
        LDMIN = -120;
        LDMAX = 0;
        % Midi piano keyboard range
        F0MIN = 60;
        F0MAX = 5000;
        
        PluginInterface = audioPluginInterface( ...
            'InputChannels', 1, ...
            'OutputChannels', 1, ...
            audioPluginParameter('InGain', ...
                'DisplayName', 'Input Gain', ...
                'DisplayNameLocation', 'above',...
                'Label', 'dB', ...
                'Mapping', {'lin', -10, 10},...
                'Style', 'rotaryknob',...
                'Layout', [2 1]),...
            audioPluginParameter('FreqScale', ...
                'DisplayName', 'Octave Shift', ...
                'DisplayNameLocation', 'above',...
                'Mapping', {'int', -2, 2},...
                'Style', 'rotaryknob',...
                'Layout', [2 2]),...
            audioPluginParameter('OutGain', ...
                'DisplayName', 'Output Gain', ...
                'DisplayNameLocation', 'above',...
                'Label', 'dB', ...
                'Mapping', {'lin', -10, 10},...
                'Style', 'rotaryknob',...
                'Layout', [2 3]),...
            audioPluginParameter('L', ...
                'DisplayName', 'Harmonic Order', ...
                'DisplayNameLocation', 'left', ...
                'Mapping', {'int', 1, 10}, ...
                'Layout', [3 2; 3 3]),...
            audioPluginParameter('fftResol',...
                'DisplayName', 'Pitch Resolution', ...
                'DisplayNameLocation', 'left', ...
                'Mapping', {'int', 1, 10},...
                'Layout', [4 2; 4 3]),...
            audioPluginParameter('FrameSize', ...
                'DisplayName', 'Frame Size', ...
                'DisplayNameLocation', 'left', ...
                'Mapping', {'int', 300, 2048},...
                'Layout', [5 2; 5 3]),...
            audioPluginGridLayout( ...
                'RowHeight', [100 100 100 100 100],...
                'ColumnWidth', [150 150 150]));
    end
    
    methods
        function plugin = ddspPlugin
            plugin.Dec = Decoder(plugin.ModelFile);
            plugin.Synth = SpectralModelingSynth;
            plugin.InBuf = CircularBuffer(plugin.BufSize);
            plugin.OutBuf = CircularBuffer(plugin.BufSize, plugin.FrameSize);
            plugin.currFrameSize = plugin.FrameSize;
            plugin.PrevFrame = zeros(ceil(plugin.FrameSize/2), 1);
        end
      
        function out = process(plugin, in)
            if (plugin.FrameSize ~= plugin.currFrameSize)
                plugin.reset;
            end
            plugin.InBuf.write(in);
            plugin.generateAudio();
            out = plugin.OutBuf.read(length(in));
        end

        function reset(plugin)
            plugin.currFrameSize = plugin.FrameSize;
            plugin.setLatencyInSamples(plugin.FrameSize);
            plugin.PrevFrame =  zeros(ceil(plugin.FrameSize/2), 1);
            plugin.Dec.reset;
            plugin.InBuf.reset;
            plugin.OutBuf.reset(plugin.FrameSize);
        end
        
        function generateAudio(plugin)
            sampleRate = plugin.getSampleRate;
            
            while plugin.InBuf.nElems >= plugin.FrameSize
                in = plugin.InBuf.read(plugin.FrameSize);
                
                downsampled = downsample(in, 2);
                pitchFrameSize = length(downsampled);
                pitchFrame = [plugin.PrevFrame; downsampled] .* hann(pitchFrameSize*2, 'periodic');
                plugin.PrevFrame = downsampled(1:pitchFrameSize,1);
                
                power = sum(in.^2) / plugin.FrameSize;

                ld = -0.691 + 10*log10(power) + plugin.InGain;

                ldScaled = ld / (plugin.LDMAX - plugin.LDMIN) + 1;

                ls = 1:plugin.L;
                
                nFft = round(plugin.fftResol*pitchFrameSize*2*plugin.L);
                spec = abs(fft([pitchFrame; zeros(nFft - pitchFrameSize*2, 1)])).^2;

                kstart = ceil(nFft * plugin.F0MIN / (sampleRate * pitchFrameSize / plugin.FrameSize));
                kstop = floor(nFft * plugin.F0MAX / (sampleRate * pitchFrameSize / plugin.FrameSize));

                if (kstart > kstop)
                    kstart=kstop;
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

                f0 = sampleRate * (pitchFrameSize / plugin.FrameSize) * bestk / nFft;
                f0 = f0 * 2^plugin.FreqScale;
                f0Scaled = hzToMidi(f0) / 127;

                [amp, harmDist, noiseMags] = plugin.Dec.call(ldScaled, f0Scaled);

                frame = plugin.Synth.getAudio(f0, amp, harmDist, noiseMags, sampleRate, plugin.FrameSize); 
                plugin.OutBuf.write(frame * 10^(plugin.OutGain/20));
            end
        end
    end
    
end

function midi = hzToMidi(hz)
    midi = 12 * (log2(hz) - log2(440)) + 69;
    midi(midi < 0) = 0;
end