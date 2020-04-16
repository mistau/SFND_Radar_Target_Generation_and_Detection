clear all
clc;

%% Radar Specifications 
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Frequency of operation = 77GHz
% Max Range = 200m
% Range Resolution = 1 m
% Max Velocity = 100 m/s
%%%%%%%%%%%%%%%%%%%%%%%%%%%

RangeMax = 200;
RangeResolution = 1;
c = 3e8;

%speed of light = 3e8
%% User Defined Range and Velocity of target

% define the target's initial position and velocity. Note : Velocity
% remains contant

TargetRange = 111;
TargetVelocity = 50;      %% proper German speed on the autobahn
 

%% FMCW Waveform Generation

%Design the FMCW waveform by giving the specs of each of its parameters.
% Calculate the Bandwidth (B), Chirp Time (Tchirp) and Slope (slope) of the FMCW
% chirp using the requirements above.

B = c / (2 * RangeResolution);
Tchirp = 5.5 * 2 * RangeMax / c;
slope  = B / Tchirp;

%Operating carrier frequency of Radar 
fc= 77e9;             %carrier freq
                                                     
%The number of chirps in one sequence. Its ideal to have 2^ value for the ease of running the FFT
%for Doppler Estimation. 
Nd=128;                   % #of doppler cells OR #of sent periods % number of chirps

%The number of samples on each chirp. 
Nr=1024;                  %for length of time OR # of range cells

% Timestamp for running the displacement scenario for every sample on each
% chirp
t=linspace(0,Nd*Tchirp,Nr*Nd); %total time for samples


%Creating the vectors for Tx, Rx and Mix based on the total samples input.
Tx=zeros(1,length(t)); %transmitted signal
Rx=zeros(1,length(t)); %received signal
Mix = zeros(1,length(t)); %beat signal

%Similar vectors for range_covered and time delay.
r_t=zeros(1,length(t));
td=zeros(1,length(t));


%% Signal generation and Moving Target simulation
% Running the radar scenario over the time. 

for i=1:length(t)         
    
    %For each time stamp update the Range of the Target for constant velocity. 
	
    r_t(i) = TargetRange + TargetVelocity * t(i);
    td(i) = r_t(i) * 2/c;  % get delay for target (2*range @ speed of light)
	
    %For each time sample we need update the transmitted and
    %received signal. 
    Tx(i) = cos(2*pi*(fc*t(i) + slope * t(i)^2/2));
    Rx(i) = cos(2*pi*(fc*(t(i) - td(i)) + slope * (t(i) - td(i))^2 /2)); 
    
    %Now by mixing the Transmit and Receive generate the beat signal
    %This is done by element wise matrix multiplication of Transmit and
    %Receiver Signal
    Mix(i) = Tx(i) * Rx(i);

end

%% RANGE MEASUREMENT

%reshape the vector into Nr*Nd array. Nr and Nd here would also define the size of
%Range and Doppler FFT respectively.
trans = reshape(Mix, [Nr, Nd]);

rangeFFT = fft(trans, Nr);  %run the FFT on the beat signal along the range bins dimension (Nr)
rangeFFT = rangeFFT ./ Nr;  %normalize.

rangeFFT = abs(rangeFFT);  % Take the absolute value of FFT output

% Output of FFT is double sided signal, but we are interested in only one side of the spectrum.
% Hence we throw out half of the samples.
rangeFFT = rangeFFT(1:Nr/2);

%plotting the range
figure ('Name','Range from First FFT')
subplot(2,1,1)

 % plot FFT output 
plot(rangeFFT);
 
axis ([0 200 0 1]);



%% RANGE DOPPLER RESPONSE
% The 2D FFT implementation is already provided here. This will run a 2DFFT
% on the mixed signal (beat signal) output and generate a range doppler
% map.You will implement CFAR on the generated RDM


% Range Doppler Map Generation.

% The output of the 2D FFT is an image that has reponse in the range and
% doppler FFT bins. So, it is important to convert the axis from bin sizes
% to range and doppler based on their Max values.

Mix=reshape(Mix,[Nr,Nd]);

% 2D FFT using the FFT size for both dimensions.
sig_fft2 = fft2(Mix,Nr,Nd);

% Taking just one side of signal from Range dimension.
sig_fft2 = sig_fft2(1:Nr/2,1:Nd);
sig_fft2 = fftshift (sig_fft2);
RDM = abs(sig_fft2);
RDM = 10*log10(RDM) ;

%use the surf function to plot the output of 2DFFT and to show axis in both
%dimensions
doppler_axis = linspace(-100,100,Nd);
range_axis = linspace(-200,200,Nr/2)*((Nr/2)/400);
figure,surf(doppler_axis,range_axis,RDM);

%% CFAR implementation

%Slide Window through the complete Range Doppler Map

%Select the number of Training Cells in both the dimensions.
Tr = 10; %training band  row
Tc =  8; %training band colum

%Select the number of Guard Cells in both dimensions around the Cell under 
%test (CUT) for accurate estimation
Gr = 4;  %guard band row
Gc = 4;  %guard band colum

% offset the threshold by SNR value in dB
offset = 3;

%Create a vector to store noise_level for each iteration on training cells
noise_level = zeros(1,1);

%design a loop such that it slides the CUT across range doppler map by
%giving margins at the edges for Training and Guard Cells.
%For every iteration sum the signal level within all the training
%cells. To sum convert the value from logarithmic to linear using db2pow
%function. Average the summed values for all of the training
%cells used. After averaging convert it back to logarithimic using pow2db.
%Further add the offset to it to determine the threshold. Next, compare the
%signal under CUT with this threshold. If the CUT level > threshold assign
%it a value of 1, else equate it to 0.


   % Use RDM[x,y] as the matrix from the output of 2D FFT for implementing
   % CFAR

[width,height] = size(RDM);
RES = zeros( size(RDM) );

for posx = Tr+Gr+1: width-(Tr+Gr)
    for posy = Tc+Gc+1: height-(Tc+Gc)

        %% iterate over surrounding
        for row = posx-(Tr+Gr): posx+Tr+Gr 
            for col = posy-(Tc+Gc): posy+Tc+Gc
                %check if we are outside the guard area
                if(abs(posx-col)>Gr || abs(posy-col)>Gc)
                    noise_level = noise_level + db2pow(RDM(row,col));
                end
            end
        end
        
        threshold = pow2db(noise_level/ (2*(Tc+Gc+1)*2*(Tr+Gr+1)-(Gr*Gc)-1));
        % add SNR offset
        threshold = threshold + offset;
        
        if RDM(posx, posy) < threshold
            RES(posx, posy) = 0;
        else
            RES(posx, posy) = 1.0;
        end
    end
end

% The process above will generate a thresholded block, which is smaller 
%than the Range Doppler Map as the CUT cannot be located at the edges of
%matrix. Hence,few cells will not be thresholded. To keep the map size same
% set those values to 0. 

% deleting the boundaries of the matrix is obsolete 
% as I am using a dedicated result matrix which is initilized to 0

%RDM(1:Tr+Gr, :) = 0;           %left columns
%RDM(width-Tr-Gr:width, :)=0;   %right column
%RDM(:, 1:Tc+Gc) = 0;           %upper rows
%RDM(:, height-Tc-Gc:height)=0; %lower rows

% *%TODO* :
%display the CFAR output using the Surf function like we did for Range
%Doppler Response output.

figure,surf(doppler_axis,range_axis,RES);
colorbar;
