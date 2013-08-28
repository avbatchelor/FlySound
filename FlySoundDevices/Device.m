classdef Device < handle
    
    properties (Constant, Abstract)
        deviceName;
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
        params
        inputLabels % consider from point of view of cell, input to amp are lines out
        inputUnits %
        inputPorts % consider from point of view of cell, input to amp are lines out
        outputLabels % consider from point of view of cell, input to amp are lines out
        outputUnits %
        outputPorts % consider from point of view of cell, input to amp are lines out
    end
    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        function obj = Device(varargin)
            % This and the transformInputs function are hard coded
            obj.inputLabels = {};
            obj.inputUnits = {};
            obj.inputPorts = [];
            obj.outputLabels = {};
            obj.outputUnits = {};
            obj.outputPorts = 0;
        end
                        
        function p = getParams(obj)
            p = obj.params;
        end
        
        function setParams(obj,varargin)
            p = inputParser;
            names = fieldnames(obj.params);
            for i = 1:length(names)
                p.addParamValue(names{i},obj.params.(names{i}),@(x) strcmp(class(x),class(obj.params.(names{i}))));
            end
            parse(p,varargin{:});
            results = fieldnames(p.Results);
            for r = 1:length(results)
                obj.params.(results{r}) = p.Results.(results{r});
            end
            obj.showParams
        end
        
        function showParams(obj,varargin)
            disp('')
            disp(obj.deviceName)
            disp(obj.params);
        end

    end
    
    methods (Abstract)
        inputstruct = transformInputs(obj,inputstruct)
        outputstruct = transformOutputs(obj,outputstruct)
    end
    
    methods (Access = protected)
        
        function createDeviceParameters(obj)
            % create an amplifier class that implements these
            % dbp.recgain = readGain();
            % dbp.recmode = readMode();
            dbp.blank = 'blank';
            
            obj.params = dbp;
        end
    end
end
