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
            
            nMags = length(noiseMag);
            

            H = [noiseMag zeros(1, 2*(nMags-1)) noiseMag(nMags:-1:2)];
            h = ifft(H);
            
            filterSize = length(h);
            win = hann(filterSize, 'periodic')';
            h = win .* [h(floor(filterSize/2)+1:filterSize)  h(1:floor(filterSize/2))];

            h = [h(floor(filterSize/2)+2:filterSize) zeros(1, nSamples - filterSize) h(1:floor(filterSize/2)+1)];

            % call to real only needed for coder
            out = real(ifft(fft([zeros(1, nSamples) h]) .* fft([noise zeros(1, nSamples)])))';
            out = out(nSamples+1:end, 1);
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
