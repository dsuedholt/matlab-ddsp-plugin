classdef CircularBuffer < handle
    properties (Access = private)
        Buffer
        ReadIdx
        WriteIdx
        BufSize
    end
    
    methods
        function obj = CircularBuffer(bufSize, initialWriteIdx)
            obj.BufSize = bufSize;
            obj.Buffer = zeros(bufSize, 1);
            obj.ReadIdx = 1;
            if (nargin > 1)
                obj.WriteIdx = initialWriteIdx;
            else
                obj.WriteIdx = 1;
            end
        end
        
        function out = read(obj, nElems)
            stopIdx = obj.ReadIdx + nElems - 1;
            if stopIdx <= obj.BufSize
                out = obj.Buffer(obj.ReadIdx:stopIdx);
            else
                stopIdx = stopIdx - obj.BufSize;
                out = [obj.Buffer(obj.ReadIdx:end); obj.Buffer(1:stopIdx)];
            end
            
            obj.ReadIdx = mod(stopIdx, obj.BufSize) + 1;
        end
        
        function write(obj, vals)
            nElems = length(vals);
            stopIdx = obj.WriteIdx + nElems - 1;
            if stopIdx <= obj.BufSize
                obj.Buffer(obj.WriteIdx:stopIdx) = vals;
            else
                stopIdx = stopIdx - obj.BufSize;
                obj.Buffer(obj.WriteIdx:end) = vals(1:nElems-stopIdx);
                obj.Buffer(1:stopIdx) = vals(nElems-stopIdx+1:end);
            end
            
            obj.WriteIdx = mod(stopIdx, obj.BufSize) + 1;
        end
        
        function out = nElems(obj)
            out = obj.WriteIdx - obj.ReadIdx;
            if out < 0
                out = out + obj.BufSize;
            end
        end
    end
end