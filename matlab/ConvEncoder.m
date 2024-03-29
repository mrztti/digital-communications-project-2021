% =========================================================================
% Convolutional encoder class
% =========================================================================
% Defines all the different encoders (E1,...)
% 

classdef ConvEncoder
    properties
        encoder
        trellis
        rate
    end
    methods
        function ce = ConvEncoder(e, t, r)
            ce.encoder = e;
            ce.trellis = t;
            ce.rate = r;
        end
        function x = encode(obj, bitstream)
            x = obj.encoder(bitstream);
        end
        function ps = theoretical_BER_SOFT(obj, depth, EbN0)
            ps = min(arrayfun(@(e) theoretical_BER_SOFT_nonvec(obj, depth, e), 10.^(EbN0 / 10)), 0.5);
        end
        function ps = theoretical_BER_SOFT_nonvec(obj, depth, EbN0)
            spect = distspec(obj.trellis.structify(),depth);
            dmin = spect.dfree;
            ds = dmin:(dmin+depth-1);
            qs = arrayfun(@(d) qfunc(sqrt(2*d*obj.rate*EbN0)), ds);
            A = qs.*spect.weight;
            ps = sum(A);
        end
    end
    enumeration
        E1(@encode_E1, Trellis.E1, 1/2)
        E2(@encode_E2, Trellis.E2, 1/2)
        E3(@encode_E3, Trellis.E3, 1/2)
        E4(@encode_E4, Trellis.E4, 2/3)
        NONE(@(x) x, [], 1)
    end
end

function m = multiplex(rate, streams)
    N = size(streams, 1) * rate;
    m = zeros(N, 1);
    for i = 1:rate
        m(i:rate:end) = streams(:, i);
    end    
end

function x = one_input(G, order, bitstream)
    
    state = zeros(order, 1); % init state to 0
    N = length(bitstream); % length of stream
    r = size(G, 1); % amount of output streams
    output_streams = zeros(N, r);

    for i = 1:N
        input = [bitstream(i); state]; % concatenate input + state
        output_streams(i, :) = (G * input)'; % calculate output
        state = [bitstream(i); state(1:end-1)]; % update state
    end
    output_streams = mod(output_streams,2); % ensure binary
    x = multiplex(2, output_streams);

end

function x = encode_E1(bitstream)
    x = one_input([1,0,1;1,1,1], 2, bitstream);
end
function x = encode_E2(bitstream)
    x = one_input([1,0,1,1,1;1,0,1,1,0], 4, bitstream);
end
function x = encode_E3(bitstream)
    x = one_input([1,0,0,1,1;1,1,0,1,1], 4, bitstream);
end

function x = encode_E4(bitstream)
    % Ensure that we have an even number of bits
    if mod(length(bitstream),2) == 1
        bitstream = [bitstream; 0];
    end
    bs1 = bitstream(1:2:end); % split inputs
    bs2 = bitstream(2:2:end);
    N = length(bs1);
    output_streams = zeros(N, 3);
    state = zeros(3, 1); % defined from left to right according to fig.2a
    
    for i = 1:N
        output_streams(i, :) = [state(3),bs1(i),bs2(i)];
        state = mod(circshift(state, 1) + [0; bs1(i);bs2(i)],2);
    end

    x = multiplex(3, output_streams);

end


