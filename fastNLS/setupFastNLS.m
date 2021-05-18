function [ePitch, eOrder] = setupFastNLS(segmentLength, ...
    maxOrder, pitchBounds, sampleRate, input)
%     obj = fastF0Nls(segmentLength, maxOrder, pitchBounds/sampleRate); 
    obj = fastNLS(segmentLength, maxOrder, pitchBounds/sampleRate);   
    obj.reset(segmentLength, maxOrder, pitchBounds/sampleRate);
    [ePitch, eOrder] = obj.estimate(input)
end