function P = iso226(F,L,what)
%**************************************************************************
% P = iso226(F,L,what)
% Funtion to calculate loudness level(phon) from a sound presure level (dB)
% or sound pressure level from loudness level, using the calculation method
% given in ISO 226 2004.
% Input valriables:
%       F: Frequency in Hz between 20 and 12500Hz
%       L: Sound pressure level in dB or Loudness level in phon
%       what: String to define convertion:
%               'SPL' => dB into phon
%               'LL'  => phon into dB
%
% Author:   Rodrigo Ordoñez
%           Acoustics, Department of Electronic Systems
%           Aalborg University
% Date:     15-02-2007
% Version:  1.0
%**************************************************************************
if min(F) >= 20 && max(F) <= 12500
    if strcmp(what,'LL') || strcmp(what,'SPL')
        f = [20 25 31.5 40 50 63 80 100 125 160 ...
         200 250 315 400 500 630 800 1000 1250 1600 ... 
         2000 2500 3150 4000 5000 6300 8000 10000 12500];
        f2 = 20:0.1:12500;
        a_f = [532 506 480 455 432 409 387 367 349 330 ...
         315 301 288 276 267 259 253 250 246 244 ...
         243 243 243 242 242 245 254 271 301]./1000;
        L_U = [-316 -272 -230 -191 -159 -130 -103 -81 -62 -45 -31 -20 -11 ...
         -4 0 3 5 0 -27 -41 -10 17 25 12 -21 -71 -112 -107 -31]./10;
        T_f = [785 687 595 511 440 375 315 265 221 179 144 114 86 62 44 30 ...
         22 24 35 17 -13 -42 -60 -54 -15 60 126 139 123]./10;
        TT = spline(f,T_f,f2);
        aa = spline(f,a_f,f2);
        LL = spline(f,L_U,f2);

        A_f = zeros(length(F),length(L));
        B_f = zeros(length(F),length(L));
        P = zeros(length(F),length(L));
        for j = 1:length(L)
            for i = 1:length(F)
                if strcmp(what,'LL')
                    A_f(i,j) = 4.47e-3*(10^(0.025*L(j)) - 1.14) + ...
                        (0.4*10^(0.1*(TT(f2==F(i)) + ...
                        LL(f2==F(i))) - 9))^aa(f2==F(i));
                    P(i,j) = (10/aa(f2==F(i)))*log10(A_f(i,j)) - ...
                        LL(f2==F(i)) + 94;    %%dB SPL
                end
                if strcmp(what,'SPL')
                    B_f(i,j) = (0.4*10^(0.1*(L(j) + ...
                        LL(f2==F(i)))-9))^aa(f2==F(i)) - ...
                        (0.4*10^(0.1*(TT(f2==F(i)) + ...
                        LL(f2==F(i)))-9))^aa(f2==F(i)) + 0.005076;
                    P(i,j) = 40*log10(B_f(i,j)) + 94;  %%phon
                    if P(i,j) < 0
                        P(i,j) = 0;
                    end
                end
            end
        end
        P = round(10*P)./10;
    else
        error('You must choose between sound pressure level (SPL) or loudness level (LL)')
    end
else
    error('Frequency (F) must be between 20 and 12500 Hz')
end