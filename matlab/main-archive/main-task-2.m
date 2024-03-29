% ======================================================================= %
% SSY125 Project
% ======================================================================= %
clc
clear

% ======================================================================= %
% Simulation Options
% ======================================================================= %
N = 1e5;  % 5 simulate N bits each transmission (one block)
maxNumErrs = 100; % get at least 100 bit errors (more is better)
maxNum = 1e6; % 6 OR stop if maxNum bits have been simulated
EbN0 = -1:8; % power efficiency range:

% ======================================================================= %
% Other Options
% ======================================================================= %
constellation = SymbolMapper.QPSK_GRAY; % Choice of constellation
e1 = ConvEncoder.E1;
e2 = ConvEncoder.E2;
e3 = ConvEncoder.E3;
UPPER_BOUND_DEPTH = 10; % How far we are willing to go in precision for the upper bound
decoder_type = DecoderType.SOFT;
decoder1 = ViterbiDecoder(e1.trellis, decoder_type, constellation);
decoder2 = ViterbiDecoder(e2.trellis, decoder_type, constellation);
decoder3 = ViterbiDecoder(e3.trellis, decoder_type, constellation);

% ======================================================================= %
% Simulation Chain
% ======================================================================= %
BER_coded1 = zeros(1, length(EbN0)); % pre-allocate a vector for BER results
BER_coded2 = zeros(1, length(EbN0));
BER_coded3 = zeros(1, length(EbN0));
lb = LoadingBar(length(EbN0)*maxNum);

for i = 1:length(EbN0) % use parfor ('help parfor') to parallelize
  totErr1 = 0;  % Number of coded errors observed
  totErr2 = 0;  % Number of coded errors observed
  totErr3 = 0;  % Number of coded errors observed
  num = 0; % Number of bits processed
  snr = EbN0(i);
  
  
  drawFirst = true;
  while((totErr1 + totErr2 + totErr3 < 3*maxNumErrs) && (num < maxNum))
  % ===================================================================== %
  % Begin processing one block of information
  % ===================================================================== %
  % [SRC] generate N information bits 
  u = randi([0,1], N, 1);

  % [ENC] convolutional encoder
  c1 = e1.encode(u);
  c2 = e2.encode(u);
  c3 = e3.encode(u);

  % [MOD] symbol mapper  
  x1 = constellation.map(c1);
  x2 = constellation.map(c2);
  x3 = constellation.map(c3);

  % [CHA] add Gaussian noise
  y1 = constellation.AWGN_channel(x1, snr, e1);
  y2 = constellation.AWGN_channel(x2, snr, e2);
  y3 = constellation.AWGN_channel(x3, snr, e3);

  % Only draw on the first iteration
%   if drawFirst
%       figure("Name", "Symbols received for EbN0 = " + string(snr));
%       hold on;
%       grid on;
%       plt = plot_symbols(y, constellation, snr);
%   end

  cf1 = decoder1.decode(y1);
  cf2 = decoder2.decode(y2);
  cf3 = decoder3.decode(y3);
  % ===================================================================== %
  % End processing one block of information
  % ===================================================================== %
  BitErrs1= sum(u~=cf1); % count the bit errors and evaluate the bit error rate
  BitErrs2 = sum(u~=cf2);
  BitErrs3 = sum(u~=cf3);
  totErr1 = totErr1 + BitErrs1;
  totErr2 = totErr2 + BitErrs2;
  totErr3 = totErr3 + BitErrs3;
  num = num + N; 

  lb = lb.step(N);
  end 
  BER_coded1(i) = totErr1/num;
  BER_coded2(i) = totErr2/num; 
  BER_coded3(i) = totErr3/num;
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
plot(EbN0,e1.theoretical_BER_SOFT(UPPER_BOUND_DEPTH, EbN0),'Marker','x', 'Color',	'#9F0000')
plot(EbN0,e2.theoretical_BER_SOFT(UPPER_BOUND_DEPTH, EbN0),'Marker','x', 'Color',	'#00741F')
plot(EbN0,e3.theoretical_BER_SOFT(UPPER_BOUND_DEPTH, EbN0),'Marker','x', 'Color',	'#00420F')
plot(EbN0, BER_coded1, 'Color', 'Red')
plot(EbN0, BER_coded2, 'Color', 'Green')
plot(EbN0, BER_coded3, 'Color', 'Blue')


title('Plot of coded BER for E1, E2, E3 compared to their BER upper bound')
xlabel('E_b/N_0 [dB]')
ylabel('BER')
legend('E1 - Upper bound', 'E2 - Upper bound','E3 - Upper bound', 'E1 - SOFT', 'E2 - SOFT', 'E3 - SOFT')
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








