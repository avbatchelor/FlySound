function time = makeInTime(params)
% time = makeTime(params)
% see also makeTime makeInTime makeOutTime
if isa(params, 'FlySoundProtocol')
    params = params.params;
end

time = (0:1:params.durSweep*params.sampratein)/params.sampratein;
if isfield(params,'preDurInSec');
    time = time-params.preDurInSec;
end
time = time(:);