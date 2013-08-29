% Create protocol to deliver a sine pulse to an antenna
%   p = PiezoSine(<paramname>,paramname,'modusOperandi',<'Run','Stim','Cal'>)

classdef PiezoSine < FlySoundProtocol
    properties (Constant)
        protocolName = 'PiezoSine';
        rigRequired = 'PiezoRig';
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
        gaincorrection
    end
    
    events
        StimulusProblem
    end
    
    methods
        
        function obj = PiezoSine(varargin)
            obj = obj@FlySoundProtocol(varargin{:});
            p = inputParser;
            p.addParamValue('modusOperandi','Run',...
                @(x) any(validatestring(x,{'Run','Stim','Cal'})));
            parse(p,varargin{:});
            
            if strcmp(p.Results.modusOperandi,'Cal')
                notify(obj,'StimulusProblem',StimulusProblemData('CalibratingStimulus'))
                obj.gaincorrection = [];
            else
                correctionfiles = dir('C:\Users\Anthony Azevedo\Code\FlySound\Rig Calibration\PiezoSineCorrection*.mat');
                if ~isempty(correctionfiles)
                    cfdate = correctionfiles(1).date;
                    cf = 1;
                    cfdate = datenum(cfdate);
                    for d = 2:length(correctionfiles)
                        if cfdate < datenum(correctionfiles(d).date)
                            cfdate = datenum(correctionfiles(d).date);
                            cf = d;
                        end
                    end
                    temp = load(correctionfiles(cf).name);
                    obj.gaincorrection = temp.d;
                else
                    notify(obj,'StimulusProblem',StimulusProblemData('UncorrectedStimulus'))
                    obj.gaincorrection = [];
                end
            end
        end
        
        function varargout = getStimulus(obj,varargin)
            if ~isempty(obj.gaincorrection)
                gain = obj.gaincorrection.gain(...
                    round(obj.gaincorrection.displacement*10)/10 == round(obj.params.displacement*10)/10,...
                    round(obj.gaincorrection.freqs*10)/10 == round(obj.params.freq*10)/10);
                offset = obj.gaincorrection.offset(...
                    round(obj.gaincorrection.displacement*10)/10 == round(obj.params.displacement*10)/10,...
                    round(obj.gaincorrection.freqs*10)/10 == round(obj.params.freq*10)/10);
                if isempty(gain) || isempty(offset)
                    gain = 1;
                    offset = 0;
                    notify(obj,'StimulusProblem',StimulusProblemData('UncalibratedStimulus'))
                end
            else gain = 1; offset = 0;
            end
            if obj.params.displacement*gain + obj.params.displacementOffset + offset >= 10 || ...
                    obj.params.displacementOffset+offset-obj.params.displacement*gain >= 10
                gain = 1;
                offset = 0;
                notify(obj,'StimulusProblem',StimulusProblemData('StimulusOutsideBounds'))
            end
            commandstim = obj.y .*sin(2*pi*obj.params.freq*obj.x);
            commandstim = commandstim * obj.params.displacement;
            calstim = commandstim *gain;
            commandstim = commandstim+obj.params.displacementOffset;
            calstim = calstim+obj.params.displacementOffset+offset;
            obj.out.piezocommand = calstim;
            varargout = {obj.out,calstim,commandstim};
        end
        
    end % methods
    
    methods (Access = protected)
        
        function defineParameters(obj)
            obj.params.displacementOffset = 5;
            obj.params.sampratein = 50000;
            obj.params.samprateout = 50000;
            obj.params.displacements = 0.05*sqrt(2).^(0:6);
            obj.params.displacement = obj.params.displacements(1);
            
            obj.params.ramptime = 0.04; %sec;
            
            % obj.params.cycles = 10;
            obj.params.freq = 25; % Hz
            obj.params.freqs = 25 * sqrt(2) .^ (0:10);
            obj.params.stimDurInSec = .3; % obj.params.cycles/obj.params.freq;
            obj.params.preDurInSec = .4;
            obj.params.postDurInSec = .3;
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            
            obj.params.Vm_id = 0;
            
            obj.params = obj.getDefaults;
        end
        
        function setupStimulus(obj,varargin)
            setupStimulus@FlySoundProtocol(obj);
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            obj.x = ((1:obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec+obj.params.postDurInSec))-obj.params.preDurInSec*obj.params.samprateout)/obj.params.samprateout;
            obj.x = obj.x(:);
            obj.params.freq = obj.params.freqs(1);
            y = (1:obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec+obj.params.postDurInSec));
            y = y(:);
            y(:) = 0;
            
            stimpnts = obj.params.samprateout*obj.params.preDurInSec+1:...
                obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec);
            
            w = window(@triang,2*obj.params.ramptime*obj.params.samprateout);
            w = [w(1:obj.params.ramptime*obj.params.samprateout);...
                ones(length(stimpnts)-length(w),1);...
                w(obj.params.ramptime*obj.params.samprateout+1:end)];
            
            y(stimpnts) = w;
            obj.y = y;
            obj.out.piezocommand = y;
        end
        
    end % protected methods
    
    methods (Static)
    end
end % classdef

% function displayTrial(obj)
%     figure(1);
%     ax1 = subplot(4,1,[1 2 3]);
%
%     redlines = findobj(1,'Color',[1, 0, 0]);
%     set(redlines,'color',[1 .8 .8]);
%     bluelines = findobj(1,'Color',[0, 0, 1]);
%     set(bluelines,'color',[.8 .8 1]);
%     line(obj.x,obj.y(:,1),'parent',ax1,'color',[1 0 0],'linewidth',1);
%     box off; set(gca,'TickDir','out');
%     switch obj.recmode
%         case 'VClamp'
%             ylabel('I (pA)'); %xlim([0 max(t)]);
%         case 'IClamp'
%             ylabel('V_m (mV)'); %xlim([0 max(t)]);
%     end
%     xlabel('Time (s)'); %xlim([0 max(t)]);
%
%     ax2 = subplot(4,1,4);
%     [~,commandstim] = obj.generateStimulus;
%     line(obj.x,commandstim,'parent',ax2,'color',[.7 .7 .7],'linewidth',1);
%     line(obj.x,obj.sensorMonitor,'parent',ax2,'color',[0 0 1],'linewidth',1);
%     box off; set(gca,'TickDir','out');
%
% end