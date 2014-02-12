% Electrophysiology Protocol Base Class
classdef PiezoProtocol < FlySoundProtocol
    % CurrentSine.m
    % CurrentStep.m
    % FlySoundProtocol.m
    % PiezoBWCourtshipSong.m
    % PiezoCourtshipSong.m
    % PiezoSine.m
    % PiezoSquareWave.m
    % PiezoStep.m
    % SealAndLeak.m
    % SealTest.m
    % Sweep.m

    properties (Constant, Abstract) 
        protocolName;
    end
    
    properties (SetAccess = protected, Abstract)
    end
            
    % The following properties can be set only by class methods
    properties (Hidden, SetAccess = protected)
        calibratedStimulus;
        calibratedStimulusFileName;
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = protected)
    end
    
    events
        Calibrating
    end
    
    methods
        
        function obj = PiezoProtocol(varargin)
            obj = obj@FlySoundProtocol(varargin{:});
        end
        
    end % methods
    
    methods (Abstract, Static, Access = protected)
    end
    
    methods (Abstract,Static)
    end
    
    methods (Abstract)
        getCalibratedStimulus(obj)
        getCalibratedStimulusFileName(obj)
    end

    
    methods (Access = protected)
    end % protected methods
    
    methods (Static)
        function CalibrateStimulus(A)
            if ~strcmp(A.protocol.modusOperandi,'Cal')
                error('A.protocol is not in calibration mode.  Call A.setProtocol(''<protocol>'',''modusOperandi'',''Cal'')');
            end
            
            t = makeInTime(A.protocol);
            N = 3;
            
            trials = zeros(length(t),N);
            paramsToIter = A.protocol.paramsToIter;
            paramIter = A.protocol.paramIter;
            
            for p_ind = 1:size(paramIter,2)
                if ~isempty(paramIter)
                    ps = [paramsToIter',num2cell(paramIter(:,p_ind))]';
                    ps = ps(:)';
                    A.protocol.setParams(ps{:});
                end
                for n = 1:N;
                    A.run;
                    trials(:,n) = A.rig.inputs.data.sgsmonitor;
                    if abs(mean(A.rig.inputs.data.sgsmonitor(t<0))-A.protocol.params.displacementOffset) > .5
                        error('Is the Piezo on?');
                    end
                end
                sgs = mean(trials,2);
                
                f = figure(101);clf
                ax = subplot(1,1,1,'parent',f); hold(ax,'on');
                
                [~,stim,targetstim] = A.protocol.getStimulus;

                plot(ax,A.protocol.x,stim,'color',[.7 .7 .7])
                plot(ax,A.protocol.x,targetstim,...
                    'color',[1 0 0])
                plot(ax,t,trials,'color',[.7 .7 1])
                plot(ax,t,sgs,'color',[0 0 1])
                
                
                sgs = sgs - mean(sgs(10:2000));
                stim = stim - stim(1);
                targetstim = targetstim - targetstim(1);
                
                [C, Lags] = xcorr(sgs,stim,'coeff');
                figure(102);
                plot(Lags,C);
                
                i_del = Lags(C==max(C));  % assume lag is causal.  If not it's an error.
                
                if i_del < 0
                    error('No causal delay between stimulus and response')
                end
                %     t_del = t(end)-t(end+i_del+1);
                % else
                %     t_del = t(i_del+1) - t(1);
                % end
                %
                figure(103); %clf
                plot(t(1:end-i_del),targetstim(1:end-i_del),'color',[.7 .7 .7]), hold on
                plot(t(1:end-i_del),sgs(i_del+1:end)), hold off
                
                diff = targetstim(1:end-i_del)-sgs(i_del+1:end);
                diff = diff/A.protocol.params.displacement;
                diff = diff(t(1:end-i_del)>=0 & t(1:end-i_del)<A.protocol.params.stimDurInSec);
                
                [oldstim,fs] = audioread([A.protocol.getCalibratedStimulusFileName,'.wav']);
                info = audioinfo([A.protocol.getCalibratedStimulusFileName,'.wav']);
                NBITS = info.BitsPerSample;
                
                newstim = oldstim+diff;
                
                figure(104),clf, hold on
                plot(oldstim,'color',[.7 .7 .7])
                plot(newstim,'r')
                plot(diff),
                
                fn = A.protocol.getCalibratedStimulusFileName;
                cur_cs_fn = length(dir([fn,'_*.wav']));
                copyfile([fn,'.wav'],[fn '_' num2str(cur_cs_fn) '.wav'],'f')
                
                audiowrite([fn,'.wav'],newstim,fs,'BitsPerSample',NBITS);
                if mean(sqrt(diff.^2)) > .01 || max(abs(diff)) > 0.05
                    disp(mean(sqrt(diff.^2)))
                    disp(max(abs(diff)))
                    A.protocol.CalibrateStimulus(A);
                end
            end
            
            if ~isempty(paramIter)
                for p_ind = 1:length(paramsToIter);
                    ps{2*p_ind-1} = paramsToIter{p_ind};
                    ps{2*p_ind} = unique(paramIter(p_ind,:));
                end
                A.protocol.setParams(ps{:});
            end
        end
    end
end % classdef