function varargout = PlayrecInit(varargin)

%% Platform independent initialization of Playrec
% PLAYRECINIT(FS,SC,CHS) automatically initialise playrec, if no
% input arguments are given, the default sampling frequency is 48kHz,
% sound card use is given in line 10 and maximum number of channels is 2 
% Valid sound card names can be foudn running 
% >> a = playrec('getDevices')
% the a structure has a "name" field will the names of all the attached
% sound devices like: 
%   SC = 'QUAD-CAPTURE';
%   SC = 'Fireface';
%   SC = 'UA-25';
%   SC = 'Realtek ASIO';
%   SC = 'ASIO MADIface USB';
%   SC = 'ASIO Fireface USB';
if nargin<1 
    fs = 48e3; 
    SC = 'ASIO Fireface USB';
    NumChan = 8;
elseif nargin == 3
    fs = varargin{1};
    SC = varargin{2};
    NumChan = varargin{3};
else
    error('Not enough input arguments: fs, Sound Card, number of channels')
end

H = playrec('getDevices');
if playrec('isInitialised') == 0

    for i = 1:1:size(H,2)
       if  strcmp(H(i).name,SC) 
           OutDevID = i-1;
           InDevID = i-1;
           break;
        end
    end

    if  exist('OutDevID','var')
        playrec('init',fs,OutDevID,-1,NumChan,0,480)
        fprintf('\n Sound Card: %s is initialized\n',SC);
        varargout{2} = SC;
        
    else
        fprintf('\n Sound Card: %s is not connected to the computer',SC);
        varargout{2} = 0;
    end

else
    SC = H(playrec('getPlayDevice')+1).name;
    NumChan = playrec('getPlayMaxChannel');
    varargout{1} = [NumChan-1, NumChan];
    fprintf('\n Sound Card %s is already initialized\n Using channel outputs: %d and %d.',...
        SC,NumChan-1,NumChan)

    varargout{2} = SC;
end

varargout{1} = [NumChan-1, NumChan];
end



