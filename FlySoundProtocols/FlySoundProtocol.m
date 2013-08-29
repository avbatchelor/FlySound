classdef FlySoundProtocol < handle
    
    properties (Constant, Abstract) 
        protocolName;
    end
    
    properties (Constant, Abstract) 
        rigRequired;
    end
    
    properties (Hidden, SetAccess = protected)
        target
        current
        paramsToIter
        paramIter
        randomizeIter
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = protected)
        modusOperandi   % simulate or run?
        params
        rig
        x
        y
        out
    end
    
    % Define an event called InsufficientFunds
    events
        RigChange
    end
    
    methods
        
        function obj = FlySoundProtocol(varargin)
            notify(obj,'RigChange',RigChangeData(obj.requiredRig));
            obj.defineParameters();
            obj.setupStimulus();            
            % obj.showParams;
            obj.target = length(obj.paramIter);
            obj.randomizeIter = 0;
            obj.current = 1;
        end        
        
        function stim = next(obj)
            % for this, have to adhere to the convention that params are
            % the 
            for pn = 1:length(obj.paramsToIter)
                name = obj.paramsToIter{pn};
                obj.params.(name(1:end-1)) = obj.paramIter(pn,obj.current);
            end
            stim = obj.getStimulus();
            obj.current = obj.current+1;
        end
        
        function l = hasNext(obj)
            l = obj.current <= obj.target;
        end
                
        function reset(obj)
            obj.current = 1;
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
            obj.setupStimulus
            obj.showParams
        end
        
        function showParams(obj,varargin)
            disp('')
            disp(obj.protocolName)
            disp(obj.params);
        end

        function defaults = getDefaults(obj)
            defaults = getpref(['defaults',obj.protocolName]);
            if isempty(defaults)
                defaultsnew = [fieldnames(obj.params),struct2cell(obj.params)]';
                obj.setDefaults(defaultsnew{:});
                defaults = obj.params;
            end
        end
        
        function setDefaults(obj,varargin)
            p = inputParser;
            names = fieldnames(obj.params);
            for i = 1:length(names)
                addOptional(p,names{i},obj.params.(names{i}));
            end
            parse(p,varargin{:});
            results = fieldnames(p.Results);
            for r = 1:length(results)
                setpref(['defaults',obj.protocolName],...
                    [results{r}],...
                    p.Results.(results{r}));
            end
        end
        
        function showDefaults(obj)
            disp('');
            disp('DefaultParameters');
            disp(getpref(['defaults',obj.protocolName]));
        end
        
        function randomize(obj,varargin)
            sl = ~logical(obj.randomizeIter);
            if isempty(sl)
                sl = false;
            end
            if nargin>1
                sl = logical(varargin{1});
            end
            switch sl
                case true
                    obj.randomizeIter = true;
                case false
                    obj.randomizeIter = false;
            end
            obj.setupStimulus
        end

    end % methods
    
    methods (Abstract, Static, Access = protected)
        defineParameters
    end
    
    methods (Abstract,Static)
        % displayTrial
    end
    
    methods (Abstract)
        getStimulus(obj)
    end

    
    methods (Access = protected)
                
        function setupStimulus(obj,varargin)            
            names = fieldnames(obj.params);
            multivals = {};
            obj.paramsToIter = {};
            obj.target = 1;
            for pn = 1:length(names)
                if length(obj.params.(names{pn})) > 1
                    obj.paramsToIter{end+1} = names{pn};
                    multivals{end+1} = obj.params.(names{pn});
                    obj.target = obj.target*length(obj.params.(names{pn}));
                end
            end
            obj.paramIter = permsFromCell(multivals);

            if obj.randomizeIter
                rvec = randperm(size(obj.paramIter,2));
                obj.paramIter = obj.paramIter(:,rvec);
            end
            obj.current = 1;
        end
        
        function trialdata = runtimeParameters(obj,varargin)
            p = inputParser;
            addOptional(p,'repeats',1);
            addOptional(p,'vm_id',obj.params.Vm_id);
            parse(p,varargin{:});
            
            trialdata = appendStructure(obj.dataBoilerPlate,obj.params);
            trialdata.Vm_id = p.Results.vm_id;
            trialdata.repeats = p.Results.repeats;
        end
                                        
    end % protected methods
    
    methods (Static)
    end
end % classdef