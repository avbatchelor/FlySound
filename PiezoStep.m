classdef PiezoStep < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'PiezoStep'
    end

    properties (Hidden)
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
    end
    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        
        function obj = PiezoStep(varargin)
            % In case more construction is needed
            obj = obj@FlySoundProtocol(varargin{:});
            obj.createDataStructBoilerPlate();  % protocol specific Params
        end
        
        function run(obj,varargin)
            % Runtime routine for the protocol. obj.run(numRepeats)
            % preassign space in data for all the trialdata structs
            p = inputParser;
            addOptional(p,'famN',1);
            p.addParamValue('displ',10,@(x) isnumeric(x) && x<25);
            p.addParamValue('dur',1,@isnumeric)
            p.addParamValue('pre',0.2,@isnumeric)

            parse(p,varargin{:});
            famN = p.Results.famN;
            
            % stim_mat = generateStimFamily(obj);
            trialdata = obj.dataBoilerPlate;
            trialdata.durSweep = 1;
            obj.aiSession.Rate = trialdata.sampratein;
            obj.aiSession.DurationInSeconds = trialdata.durSweep;
            
            obj.x = ((1:obj.aiSession.Rate*obj.aiSession.DurationInSeconds) - 1)/obj.aiSession.Rate;
            obj.x_units = 's';
            
            for fam = 1:famN

                fprintf('Trial %d\n',obj.n);

                trialdata.trial = obj.n;

                obj.y = obj.aiSession.startForeground; %plot(x); drawnow
                voltage = obj.y;
                current = obj.y;
                
                % apply scaling factors
                current = (current-trialdata.currentoffset)*trialdata.currentscale;
                voltage = voltage*trialdata.voltagescale-trialdata.voltageoffset;
                
                switch obj.rec_mode
                    case 'VClamp'
                        obj.y = current;
                        obj.y_units = 'pA';
                    case 'IClamp'
                        obj.y = voltage;
                        obj.y_units = 'mV';
                end
                                
            end
            [trialdata.Rinput,trialdata.Rseries,trialdata.Cm] = obj.displayRun();
            obj.saveData(trialdata,current,voltage)% save data(n)

        end
                
        function varargout = displayRun(obj)
        end

    end % methods
    
    methods (Access = protected)
                        
        function createDataStructBoilerPlate(obj)
            createDataStructBoilerPlate@FlySoundProtocol(obj);
            dbp = obj.dataBoilerPlate;
            
            % Set Boiler plate params
            % going to need a conversion from V to distance
            dbp.displFactor = 10/30; %um/V
            
            obj.dataBoilerPlate = dbp;
        end
                
        function stim_mat = generateStimFamily(obj)
            for paramsToVary = obj.params
                stim_mat = generateStimulus;
            end
        end
        
    end % protected methods
    
    methods (Static)
    end
end % classdef