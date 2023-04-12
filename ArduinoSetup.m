%%

try
    ard = arduino;
catch
    ard = nan;
end

%%
LED = 'D7'; % high led is on
RES = 'D8'; % Reset SWOutPressed when low else is high. 
SWState = 'D5'; % 1 if up 0 if down
SWPressed = 'D6'; % 1 after pressed until RES is low.


ard.BaudRate = 9600;
configurePin(ard,RES,'DigitalOutput')
configurePin(ard,LED,'DigitalOutput')
configurePin(ard,SWState,'pullup')
configurePin(ard,SWPressed,'pullup')

%%
%
writeDigitalPin(ard,RES,0) % SWPressed = 0 ; SWState = 1;
writeDigitalPin(ard,RES,1) 

tic
writeDigitalPin(ard,LED,1);
while toc < 60
    buttonOut = [readDigitalPin(ard,SWState),...
            readDigitalPin(ard,SWPressed)];
     if ~buttonOut(1) 
         if buttonOut(2)
            disp('Correct Response')
            pause(0.2)
            disp(buttonOut)
         end
     else
         if buttonOut(2) 
            writeDigitalPin(ard,RES,0);
            disp('button released')
            pause(0.2)
            writeDigitalPin(ard,RES,1);
         else
            disp('button not pressed')
            pause(0.2)
         end
     end    
     %disp(buttonOut)
    
end
writeDigitalPin(ard,LED,0);