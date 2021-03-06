% Collect data
classdef Sweep < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'Sweep';
    end
    
    properties (SetAccess = protected)
        requiredRig = 'BasicEPhysRig';
        analyses = {};
    end
    
    properties (SetAccess = protected)
    end

    
    methods
        
        function obj = Sweep(varargin)
            ...
        end
        
        function varargout = getStimulus(obj,varargin)
            varargout = {obj.out,obj.x};
        end
        
    end % methods
    
    methods (Access = protected)
                        
        function defineParameters(obj)
            obj.params.sampratein = 50000;
            obj.params.samprateout = 50000;
            obj.params.durSweep = 5;
            obj.params.Vm_id = 0;
            obj.params = obj.getDefaults;
        end
       
        function setupStimulus(obj,varargin)
            obj.x = makeOutTime(obj);
            obj.out.voltage = zeros(size(obj.x));
            obj.out.current = zeros(size(obj.x));
        end
                
    end % protected methods
    
    methods (Static)
    end
end % classdef
