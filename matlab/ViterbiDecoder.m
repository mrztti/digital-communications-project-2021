% =========================================================================
% Viterbi Decoder class
% =========================================================================
% Convenience class to contain the decoder with a set of given properties


classdef ViterbiDecoder
    properties
        decoder_type
        trellis
        constellation
    end
    methods
        function vd = ViterbiDecoder(trellis, type, constellation)
            vd.decoder_type = type;
            vd.trellis = trellis;
            vd.constellation = constellation;
        end

        function y = decode(obj, symbols)
            y = obj.decoder_type.decode(symbols, obj.trellis, obj.constellation);
        end
    end

end

