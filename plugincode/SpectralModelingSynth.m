classdef SpectralModelingSynth < handle
% SPECTRALMODELINGSYNTH A synthesizer combining additive and subtractive
%  synthesis to generate frames of audio.
%
%  This class implements the audio synthesis part of DDSP. Based on the 
%  synthesizer parameters predicted by the decoder, it generates a desired
%  number of audio samples at a given frame rate.

    properties (Access = private)
        PrevPhases = zeros(1, 60) % save phases for continuity
        noiseBias = -5;           % bias for the magnitudes
    end
    
    methods
        
        function out = harmonic(obj, f0, amp, harmDist, sampleRate, nSamples)
            % Input arguments: see getAudio
            % Outputs audio of the size [nSamples, 1]
            
            % generates nSamples of audio by adding Decoder.nHarmonics
            % sinusoids with integer multiple frequencies of f0. 
            
            % scale parameters
            amp = SpectralModelingSynth.scaleFn(amp);
            harmDist = SpectralModelingSynth.scaleFn(harmDist);
            
            nHarm = length(harmDist);
            
            % frequencies of the harmonics: multiples of f0
            freqs = f0 .* (1:nHarm);
            
            % set the amplitudes of all harmonics with a frequency 
            % above Nyquist to zero to avoid aliasing
            harmDist(freqs > sampleRate / 2) = 0;
            
            % normalize harmonic amplitudes
            harmDist = harmDist / sum(harmDist);

            % scale by overall amplitude
            harmAmps = amp .* harmDist;
            
            % frequency and amplitude envelopes for each sample
            % explicit repmat call required for code generation
            freqEnvs = repmat(freqs, nSamples, 1);
            ampEnvs = repmat(harmAmps, nSamples, 1);

            % frequency in radians
            omegas = freqEnvs * 2 * pi / sampleRate;
            
            % calculate instantaneous phase for each harmonic at each sample
            % by cumulative summation, taking into account the last phase
            % of the previous frame
            phases = cumsum([obj.PrevPhases; omegas]);
            
            % save the phases of the last sample to be continuous with the
            % next frame
            obj.PrevPhases = mod(phases(nSamples,:), 2*pi);
            
            % calculate sinusoids
            wavs = sin(phases(2:end,:));
            
            % scale harmonics by their amplitudes and sum all sinusoids
            out = sum(ampEnvs .* wavs, 2);
        end
        
        function out = filteredNoise(obj, noiseMags, nSamples)   
            % generate nSamples of white noise passed through a filter
            % specified by the magnitude response in noiseMags. 
            
            % scale magnitudes
            noiseMags = SpectralModelingSynth.scaleFn(noiseMags + obj.noiseBias);

            % generate white noise in [-1; 1]
            noise = rand(1, nSamples) * 2 - 1;
            
            nMags = length(noiseMags);
            
            % expand magnitudes to be symmetric, so that the ifft is real
            H = [noiseMags noiseMags(nMags:-1:2)];
            
            % calculate the impulse response corresponding to the filter
            h = ifft(H);
            
            filterSize = length(h);
            win = hann(filterSize, 'periodic')';
            
            % shift the IR to zero-phase / symmetric form and apply hannwindow
            h = win .* [h(floor(filterSize/2)+1:filterSize) h(1:floor(filterSize/2))];
            
            % shift the IR back to causal form and pad to nSamples
            h = [h(floor(filterSize/2)+2:filterSize), ...
                 zeros(1, nSamples - filterSize), ...
                 h(1:floor(filterSize/2)+1)];

            % convolve the noise with the IR by multiplication in the
            % fourier domain
            
            % explicit call to real required for code generation
            out = real(ifft(fft(h) .* fft(noise)))';
        end
        
        function out = getAudio(obj,f0,amp,harmDist,noiseMag,sampleRate,nSamples)        
            % The general entry point to generate a frame of audio.
            % Inputs:
            %     f0         : a pitch in Hz
            %     amp        : an overall amplitude for the additive
            %                  synthesis
            %     harmDist   : the amplitudes of the individual harmonics of
            %                  size [1, Decoder.nHarmonics]
            %     noiseMag   : magnitude response of an FIR filter of size
            %                  [1, Decoder.nMagnitudes]. The first entry
            %                  corresponds to the DC component, the last
            %                  entry to the nyquist frequency, and the
            %                  other entries to linearly spaced frequencies
            %                  between those ends
            %     sampleRate : sampleRate at which to generate audio
            %     nSamples   : number of samples to generate
            
            % additive synthesis
            harm = obj.harmonic(f0, amp, harmDist, sampleRate, nSamples);
            
            % subtractive synthesis
            noise = obj.filteredNoise(noiseMag, nSamples);
            
            out = harm + noise;
        end

    end
    
    methods (Static) 
        function out = scaleFn(in)
            % A scale function for the synthesizer parameters given in the
            % original DDSP paper. A scaled sigmoid with a threshold value
            % and a larger slope
            out = 2 * (1 + exp(-in)).^(-log(10)) + 1e-7;
        end
    end
end
