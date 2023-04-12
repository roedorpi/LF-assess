function  varargout = STMThres(varargin)
app = varargin{1};
Modulations = varargin{2};
%Default parameters
MaxReversals = 4; 
MaxNumberOfTrials = 45;
TestFreqs = [63 80 100 125 160 200];
Est = app.ThresDataTab.Data;
%Get start parameters
ModAmp = 0;
SensationLevel = round(app.SensationLeveldBKnob.Value);
frequency = round(str2double(app.CenterFrequencyKnob.Value));
CyclesOctave = round(str2double(app.FreqModKnob.Value));
CyclesSeconds = round(str2double(app.TimeModKnob.Value));
if strcmp(app.EarSwitch.Value,'Left')
    ChosenEar = 1;
    ChannelOut = app.ChanNumbers(1);
else
    ChosenEar = 2; 
    ChannelOut = app.ChanNumbers(2);
end
SPL20dBFS = app.EarphoneSens.LdB(1,TestFreqs == frequency,ChosenEar);

app.STMTrialParam = [frequency, ModAmp, CyclesOctave, CyclesSeconds, SensationLevel];
if ~isempty(Est)
    %sensation level adjustment
    LevelToTry = mean(Est.Threshold_dBSPL(Est.Frequency == frequency),'omitnan') - SPL20dBFS + SensationLevel;
    if sum(Est.Frequency == frequency) && LevelToTry < -10
        StimLevel = LevelToTry;
    else
        StimLevel = -10;
    end
else
    StimLevel = -10;
end
%generateStim(frequency,ModAmp,CyclesOctave,CyclesSeconds);
StartLevel = ModAmp;
%Flash start warning
app.RespApp.AnswerPanel.Enable = 'on';
app.RespApp.Button_1.Enable = 'off';
app.RespApp.Button_2.Enable = 'off';
app.RespApp.Button_3.Enable = 'off';
if Modulations == 2
    app.StartButton.Enable = 'on';
    app.RespApp.AnswerPanel.Title = 'Vi starter snart igen.';
    pause(20)
end
app.RespApp.AnswerPanel.Title = 'Gør dig klar!';
%% Blink Button to signal start
for m = 1:3
    app.RespApp.Button_1.BackgroundColor = [0.39,0.83,0.07];
    app.RespApp.Button_2.BackgroundColor = [0.39,0.83,0.07];
    app.RespApp.Button_3.BackgroundColor = [0.39,0.83,0.07];
    if m>6
        pause(0.5)
    else
        pause(1)
    end
    app.RespApp.Button_1.BackgroundColor = [0.3,0.3,0.3];
    app.RespApp.Button_2.BackgroundColor = [0.3,0.3,0.3];
    app.RespApp.Button_3.BackgroundColor = [0.3,0.3,0.3];
    if m>6
        pause(0.5)
    else
        pause(1)
    end
end
app.RespApp.Button_1.BackgroundColor = [0.96, 0.96, 0.96];
app.RespApp.Button_2.BackgroundColor = [0.96, 0.96, 0.96];
app.RespApp.Button_3.BackgroundColor = [0.96, 0.96, 0.96];
app.RespApp.AnswerPanel.Title = 'Hvilken af de tre lyde er anderledes?';
app.RespApp.ButtonReset;
pause(1)

%% Initialize the parameters
FamRun = true; % are we at familiarization?
NextLevel = StartLevel; % dB
PrevLevel = StartLevel; 
delete(app.UIAxes.Children)
app.Reversals = 0;
app.TrialNr = 1;
app.Response = [];
generateStim(frequency,StartLevel,CyclesOctave,CyclesSeconds);
while app.Reversals < MaxReversals && app.TrialNr < MaxNumberOfTrials 
    Answered = 0;
    % Get the last signal generated
    sig(:,1) = app.CurrentSignal.p(:);
    sig(:,2) = app.CurrentSignal.n1(:);
    sig(:,3) = app.CurrentSignal.n2(:);
    SigPresLev = 20*log10(rms(sig));
    % make a randomic order of the three stimuli 
    Order = randperm(3);
    % save presentation order
    app.CurrentSignal.PresentationOrder = Order;
    pause(0.5)
    % play stim A    
    app.RespApp.Button_1.BackgroundColor = [0.2, 0.8, 0.2];
    drawnow
    Out1 = playrec('play',sig(:,Order(1)),ChannelOut);
    playrec('block',Out1);
    app.RespApp.Button_1.BackgroundColor = [0.96, 0.96, 0.96];
    drawnow

    % play stim B
    app.RespApp.Button_2.BackgroundColor = [0.2, 0.8, 0.2];
    drawnow
    Out2 = playrec('play',sig(:,Order(2)),ChannelOut);
    playrec('block',Out2);
    app.RespApp.Button_2.BackgroundColor = [0.96, 0.96, 0.96];
    drawnow

    % play stim C
    app.RespApp.Button_3.BackgroundColor = [0.2, 0.8, 0.2];
    drawnow
    Out3 = playrec('play',sig(:,Order(3)),ChannelOut);
    playrec('block',Out3);
    app.RespApp.Button_3.BackgroundColor = [0.96, 0.96, 0.96];
    drawnow

    % Enable Response Buttons
    
    app.RespApp.Button_1.Enable = 'on';
    app.RespApp.Button_2.Enable = 'on';
    app.RespApp.Button_3.Enable = 'on';
    % Start timer to calculate response time
    app.CurrentSignal.TStart = tic;
    drawnow
    while ~Answered && strcmp(app.StartButton.Text,'Stop') 
        pause(0.1) 
        Answered = app.RespApp.Pushed;
        if Answered
            ProcessAnswer
            break
        end 
    end
    % If the stop button is pushed
     if  strcmp(app.StartButton.Text,'Start') 
         app.Reversals = MaxReversals;
     end
end
%%
% stop condition was reached, reset the app to start with a 
% new stimuli
app.RespApp.Button_1.Enable = 'off';
app.RespApp.Button_2.Enable = 'off';
app.RespApp.Button_3.Enable = 'off';
app.RespApp.AnswerPanel.Title = 'Tid til en pause.';
app.StartButton.Enable = 'off';
app.STMparametersPanel.Enable = 'off';

app.CurrentStimuliLabel.Text = '...';
drawnow
pause(0.1)
     
        
        
        
        function generateStim(frequency, Level, CO, TM)
            % fixed signal parameters
            signalLength = 1;
            

            %CO = 1; % frequency modulation cycles/octave 
            %TM = 3; % temporal modulating Hz
            fs = 48e3; % sample rate of the audio device
            % Generate stimuli
            [result,noise1, noise2,t] = generate_STM_3(...
                frequency,CO,TM,Level,signalLength,fs,StimLevel,...
                app.SigFilts,app.EarphoneSens,'On','RMS');
          
            % save stimuli and noise distractor as the current stimuli
            app.CurrentSignal.p = result;
            app.CurrentSignal.n1 = noise1;
            app.CurrentSignal.n2 = noise2;
            app.CurrentSignal.fs = fs;
            app.CurrentSignal.t = t;
            app.CurrentSignal.Level = Level;
            app.CurrentSignal.CO = CO;
            app.CurrentSignal.TM = TM;
            app.CurrentSignal.Freq = frequency;
            %app.CurrentSignal;
        end
        
        
       
        function ProcessAnswer
            % This function runs when one of the response buttons is
            % pressed. It evaluates the response and make a new stimuli.
            % Calculate response time:
            app.Response(app.TrialNr).RespTime = toc(app.CurrentSignal.TStart);
            app.Response(app.TrialNr).Level = PrevLevel;
            %% Find out if the level needs to be increased or decreased 
            % If the answer is correct:
            if app.RespApp.Answer == find(app.CurrentSignal.PresentationOrder == 1)
                app.Response(app.TrialNr).Correct = 1;
                % plot the answer in the app
                line(app.UIAxes,app.TrialNr,PrevLevel,'MarkerSize',10,...
                        'Marker','+','Linewidth',4,'color',[0,0.45,0.74]);
                % Check if we are in the familiarization descent
                if app.TrialNr > 1 && FamRun && ~app.Response(app.TrialNr -1).Correct
                    FamRun = false;
                end
                if FamRun
                    if PrevLevel - app.StepSize.Dn < app.StepSize.Min
                        NextLevel = app.StepSize.Min; 
                    else
                        NextLevel = PrevLevel - app.StepSize.Dn - 7; % decrease with 10 dB in Fam
                    end
                else % not in familiarization now we use 2dn/1up
                    if app.Response(app.TrialNr - 1).Correct && ... % the previous is correct
                       app.Response(app.TrialNr - 1).Level == PrevLevel % the level is the same
                       % decrease level                  
                       if PrevLevel - app.StepSize.Dn < app.StepSize.Min
                         NextLevel = app.StepSize.Min; 
                       else
                         NextLevel = PrevLevel - app.StepSize.Dn;
                       end
                    else
                         NextLevel = PrevLevel;
                    end
                end
                %
                if ~FamRun && ~app.Response(app.TrialNr - 2).Correct ...
                        && app.Response(app.TrialNr -1).Correct ...
                        && NextLevel < StartLevel
                    app.Reversals = app.Reversals + 1;
                          line(app.UIAxes,app.TrialNr,PrevLevel,'MarkerSize',10,...
                        'Marker','+','Linewidth',2,'color',[0,1,0]);
                end
            % Incorrect answer: increase level    
            else
                % mark answer as wrong and increse level 
                app.Response(app.TrialNr).Correct = 0;
                % limit the increase to the a maximun of 0 dB 
                if PrevLevel + app.StepSize.Up > app.StepSize.Max
                    NextLevel = app.StepSize.Max;
                else
                    NextLevel = PrevLevel + app.StepSize.Up;
                end
                % check if there are 3 wrong answers in a row to return to
                % an audible level quickly.
%                 if app.TrialNr >= 3 && ...% four or more answers
%                         ~app.Response(app.TrialNr-1).Correct && ...% 2nd incorrect in a row
%                         ~app.Response(app.TrialNr-2).Correct ...% 3rd incorrect in a row 
%                        % ~app.Response(app.TrialNr-3).Correct % 4th incorrect in a row
%                     % reset reversals counts to one, still need two more. 
%                     if app.Reversals > 1
%                         app.Reversals = app.Reversals - 1;
%                     else
%                         app.Reversals = app.Reversals;
%                     end
%                     %FamRun = true;
%                     if NextLevel + app.StepSize.Dn > app.StepSize.Max
%                         NextLevel = app.StepSize.Max;
%                     else
%                         NextLevel = NextLevel + app.StepSize.Dn;
%                     end
%                 end
                line(app.UIAxes,app.TrialNr,PrevLevel,...
                    'Marker','o','Linewidth',2,'color',[0.85,0.33,0.01]);
            end
            app.CurrentStimuliLabel.Text = sprintf(...
            'Now Presenting: Freq: %i Hz; Level: %3.1f dBSPL; Mod. Amp: %3.1f dB; Trial Nr: %i; Correct %i',...
             frequency,roundn(mean(SigPresLev+SPL20dBFS),-1),NextLevel,app.TrialNr,app.Response(app.TrialNr).Correct);
        
            
            
            generateStim(frequency,NextLevel,CyclesOctave,CyclesSeconds);
                 
            
            % Disable response Response Buttons
                app.RespApp.Button_1.Enable = 'off';
                app.RespApp.Button_2.Enable = 'off';
                app.RespApp.Button_3.Enable = 'off';
            % increment presentation counter
                app.TrialNr = app.TrialNr + 1;
            % Trigger the next presentation    
          %      PresentStimuli(app);
                app.RespApp.ButtonReset;
                PrevLevel = NextLevel;
                
        end
    
 varargout{1} = 1;   
 end 