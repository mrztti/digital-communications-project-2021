% ======================================================================= %
% SSY125 Project
% ======================================================================= %
clc
clear

% ======================================================================= %
% Simulation Options
% ======================================================================= %
N = 1e5;  % 5 simulate N bits each transmission (one block)
maxNumErrs = 200; % get at least 100 bit errors (more is better)
maxNum = 2e6; % 6 OR stop if maxNum bits have been simulated
EbN0 = -1:8; % power efficiency range:

% ======================================================================= %
% Other Options
% ======================================================================= %
constellation = SymbolMapper.QPSK_GRAY; % Choice of constellation
convolutional_encoder = ConvEncoder.E2; % Choice of convolutional code
UPPER_BOUND_DEPTH = 15; % How far we are willing to go in precision for the upper bound


decoder_type = DecoderType.HARD;
decoder2_type = DecoderType.SOFT;
decoder = ViterbiDecoder(convolutional_encoder.trellis, decoder_type, constellation);
decoder2 = ViterbiDecoder(convolutional_encoder.trellis, decoder2_type, constellation);

% ======================================================================= %
% Simulation Chain
% ======================================================================= %
BER_coded = zeros(1, length(EbN0)); % pre-allocate a vector for BER results
BER_coded2 = zeros(1, length(EbN0));
BER_uncoded = zeros(1, length(EbN0));

lb = LoadingBar(length(EbN0)*maxNum);

for i = 1:length(EbN0) % use parfor ('help parfor') to parallelize
  totErr_u = 0;  % Number of uncoded errors observed
  totErr_c = 0;  % Number of coded errors observed
  totErr_c2 = 0;  % Number of coded errors observed
  num = 0; % Number of bits processed
  snr = EbN0(i);
  
  drawFirst = true;
  while((totErr_c2 < maxNumErrs) && (num < maxNum))
  % ===================================================================== %
  % Begin processing one block of information
  % ===================================================================== %
  % [SRC] generate N information bits 
  u = randi([0,1], N, 1);

  % [ENC] convolutional encoder
  c = convolutional_encoder.encode(u);

  % [MOD] symbol mapper  
  x_coded = constellation.map(c);
  x_uncoded = constellation.map(u);

  % [CHA] add Gaussian noise
  y_coded = constellation.AWGN_channel(x_coded, snr, convolutional_encoder);
  y_uncoded = constellation.AWGN_channel(x_uncoded, snr, ConvEncoder.NONE);

  % Only draw on the first iteration
%   if drawFirst
%       figure("Name", "Symbols received for EbN0 = " + string(snr));
%       hold on;
%       grid on;
%       plt = plot_symbols(y, constellation, snr);
%   end

  cf_coded = decoder.decode(y_coded);
  cf_coded2 = decoder2.decode(y_coded);
  cf_uncoded = constellation.unmap(y_uncoded);
  % ===================================================================== %
  % End processing one block of information
  % ===================================================================== %
  BitErrs_coded = sum(u~=cf_coded); % count the bit errors and evaluate the bit error rate
  BitErrs_coded2 = sum(u~=cf_coded2);
  BitErrs_uncoded = sum(u~=cf_uncoded);
  totErr_u = totErr_u + BitErrs_uncoded;
  totErr_c = totErr_c + BitErrs_coded;
  totErr_c2 = totErr_c2 + BitErrs_coded2;
  num = num + N; 

  lb = lb.step(N);
  end 
  BER_coded(i) = totErr_c/num; 
  BER_coded2(i) = totErr_c2/num; 
  BER_uncoded(i) = totErr_u/num;
  lb = lb.set(i*maxNum);
end
% ======================================================================= %
% End
% ======================================================================= %

% ======================================================================= %
% Plot results
% ======================================================================= %

figure()
hold on;

BER_theory = @(EbN0) qfunc(sqrt(2*EbN0));

plot(EbN0,BER_theory(10.^(EbN0 / 10)),'Marker','x')
spect = distspec(decoder.trellis.structify(),UPPER_BOUND_DEPTH);
ub = convolutional_encoder.theoretical_BER_SOFT(UPPER_BOUND_DEPTH, EbN0);
plot(EbN0, ub,'Marker','x')

plot(EbN0, BER_uncoded, 'Color', 'Red')
plot(EbN0, BER_coded, 'Color', 'Blue')
plot(EbN0, BER_coded2, 'Color', 'Green')



title('Plot of coded and uncoded BER compared to the theoretical BER')
xlabel('E_b/N_0 [dB]')
ylabel('BER')
legend('Theoretical uncoded BER', 'Upper bound of BER (soft decoding)', 'Uncoded transmission', 'Coded transmission (HARD)', 'Coded transmission (SOFT)')
axis([EbN0(1) EbN0(end) 1e-4 1])
set(gca, 'YScale', 'log')


% ======================================================================= %
% Custom functions
% ======================================================================= %

function p = plot_symbols(y, constellation, snr)
    col = linspace(1,10,length(y));
    scatter(real(y), imag(y), col);
    cs = constellation.constellation();
    p = scatter(real(cs), imag(cs), 'red', 'filled');
end








