classdef SpectralModelingSynth < handle
    properties (Access = private)
        PrevPhases = zeros(1, 60)
    end
    
    methods
        
        function out = harmonic(obj, f0, amp, harmDist, sampleRate, nSamples)
            amp = SpectralModelingSynth.scaleFn(amp);
            harmDist = SpectralModelingSynth.scaleFn(harmDist);
            
            nHarm = length(harmDist);
            freqs = f0 .* (1:nHarm);
            harmDist(freqs > sampleRate / 2) = 0;

            harmDist = harmDist / sum(harmDist);

            harmAmps = amp .* harmDist;

        %     freqEnvs = freqs .* ones(nSamples, nHarm);
        %     ampEnvs = harmAmps .* ones(nSamples, nHarm);
            freqEnvs = repmat(freqs, nSamples, 1);
            ampEnvs = repmat(harmAmps, nSamples, 1);

            omegas = freqEnvs * 2 * pi / sampleRate;
            phases = cumsum([obj.PrevPhases; omegas]);
            obj.PrevPhases = mod(phases(nSamples,:), 2*pi);
            
            wavs = sin(phases(2:end,:));
                      
            out = sum(ampEnvs .* wavs, 2);
        end
        
        function out = filteredNoise(obj, noiseMag, nSamples)            
            noiseMag = SpectralModelingSynth.scaleFn(noiseMag - 5);

            noise = rand(1, nSamples) * 2 - 1;

            filterSize = 64;
            win = hann(129)';

            H = [noiseMag noiseMag(65:-1:2)];
            h = ifft(H);

            h = [win(1:64) .* h(66:129) win(65:129) .* h(1:65)];
            %if length(h) < nSamples
                %h = [h zeros(1, nSamples - 129)];
            %end

            h = [h(65:end) h(1:64)];

            if nSamples < 129
                out = zeros(1, nSamples)';
            else
                out = real(ifft(fft([h zeros(1, nSamples - 129)]) .* fft(noise)))';
            end
        end
        
        function out = getAudio(obj,f0,amp,harmDist,noiseMag,sampleRate,nSamples)        
            harm = obj.harmonic(f0, amp, harmDist, sampleRate, nSamples);
            noise = obj.filteredNoise(noiseMag, nSamples);
            
            out = harm + noise;
        end

    end
    
    methods (Static) 
        function out = scaleFn(in)
            out = 2 * (1 + exp(-in)).^(-log(10)) + 1e-7;
        end
    end
end
