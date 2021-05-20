classdef CircularBuffer < handle
% CIRCULARBUFFER A class for buffering streams of one-dimensional data
    
    properties (Access = private)
        Buffer;
        ReadIdx;
        WriteIdx;
        BufSize;
    end
    
    methods
        function obj = CircularBuffer(bufSize, initialWriteIdx)
            % Initialize the buffer with a fixed buffer size and an
            % optional initial number of zeros written into the buffer
            
            obj.BufSize = bufSize;
            
            if (nargin > 1)
                obj.reset(initialWriteIdx);
            else
                obj.reset;
            end
        end
        
        function out = read(obj, nElems)
            % read and return the next nElems from the buffer 
            
            % no checks are performed to see if the read pointer will pass
            % the write pointer! Handle responsibly :)
            
            stopIdx = obj.ReadIdx + nElems - 1;
            if stopIdx <= obj.BufSize
                % no wraparound, simply return the next nElems
                out = obj.Buffer(obj.ReadIdx:stopIdx);
            else
                % wrap around the end of the buffer
                stopIdx = stopIdx - obj.BufSize;
                out = [obj.Buffer(obj.ReadIdx:end); obj.Buffer(1:stopIdx)];
            end
            
            % advance read pointer
            obj.ReadIdx = mod(stopIdx, obj.BufSize) + 1;
        end
        
        function write(obj, vals)
            % write values into the buffer
            
            % does not check to see if the write pointer passes the read
            % pointer!
            
            nElems = length(vals);
            stopIdx = obj.WriteIdx + nElems - 1;
            
            if stopIdx <= obj.BufSize
                % no wraparound, write directly to the buffer
                obj.Buffer(obj.WriteIdx:stopIdx) = vals;
            else
                % wrap around the end of the buffer
                stopIdx = stopIdx - obj.BufSize;
                obj.Buffer(obj.WriteIdx:end) = vals(1:nElems-stopIdx);
                obj.Buffer(1:stopIdx) = vals(nElems-stopIdx+1:end);
            end
            
            % advance the write pointer
            obj.WriteIdx = mod(stopIdx, obj.BufSize) + 1;
        end
        
        function reset(obj, initialWriteIdx)
            % reset the interal buffer to zeros, set the read pointer to the
            % beginning and optionally set the write pointer to fill the 
            % buffer with an initial amount of zeros
            
            obj.Buffer = zeros(obj.BufSize, 1);
            obj.ReadIdx = 1;
            if (nargin > 1)
                obj.WriteIdx = initialWriteIdx;
            else
                obj.WriteIdx = 1;
            end
        end
        
        function out = nElems(obj)
            % return the number of unread elements in the buffer
            % i.e. the distance between the read and the write pointer
            
            out = obj.WriteIdx - obj.ReadIdx;
            if out < 0
                out = out + obj.BufSize;
            end
        end
    end
end