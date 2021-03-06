%% Whole cell voltage clamp, trying to patch using the hamamatsu
% Aiming for Big Spiker in the GH86-Gal4;ArcLight; Line.  Trying to elicit single
% spikes while hyperpolarized and trying to patch with the Hamamatsu loaner
% camera.  

setpref('AcquisitionHardware','cameraToggle','on')

% Start the bitch 
clear all, close all
A = Acquisition;

% 64x64 on images on 1x to allow more light in.  This works better.  Procedure is:
% Before dropping the electrode in, start the baseline imaging routine.
% Check the camera properties
% Set up the directory
% Paste the images name
% check the frame rate
% Bring in the trode, make sure it's unblocked, etc.
% Patch the cell,
% move the 2x to 1x
% adjust the image scale
% stop live
% move to start trigger
% hit start on the camera
% start on the epoch


%% Seal
A.setProtocol('SealAndLeak');
A.tag('Seal')
A.run
A.untag('Seal')

%% Try to break in while imaging  Go to -50 mV (or -25 mV)
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',15);
A.tag('Voltage Clamp, break in')
A.run(1)
A.untag('Voltage Clamp, break in')
systemsound('Notify');

%% Immediately go to different plateaus to measure ArcLight 
% switch to current clamp

A.setProtocol('VoltagePlateau');
A.protocol.setParams('-q',...
    'preDurInSec',1.5,...
    'postDurInSec',1.5,...
    'stimDurInSec',0.02,...
    'plateaux',[-10 0 -20 0 -30 0 -40 0 -50 0 10 0 20 0 30],...
    'randomize',0);
A.run(6)
systemsound('Notify');

%% Turn the camera off
setpref('AcquisitionHardware','cameraToggle','off')

%% Sweep

A.setProtocol('Sweep');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q','durSweep',5);
A.tag
A.run(4)
systemsound('Notify');


%% Current injection characterization

A.setProtocol('CurrentStep');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',0.5,...
    'stimDurInSec',0.5,...
    'postDurInSec',0.5,...
    'steps',[-40 -30 -20 -10 10 20 30 40]);          % tune this 
A.tag
A.run(3)
A.clearTags
systemsound('Notify');

%% CurrentChirp - up

A.setProtocol('CurrentChirp');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',2,...
    'freqStart',17,...
    'freqEnd',300,...
    'amps',[3 10]*1,... % [10 40]
    'postDurInSec',2);
A.tag
A.run(10)
systemsound('Notify');
A.clearTags

%% Inject current to hyperpolarize and cause rebound spike-like activity
A.setProtocol('CurrentStep');
A.protocol.setParams('-q',...
    'preDurInSec',0.5,...
    'stimDurInSec',0.5,...
    'postDurInSec',0.5,...
    'steps',[-4 -3 -2 -1    1 2 3 4]);          % tune this
A.tag
A.run(5)
systemsound('Notify');
A.clearTags


%% Inject current to hyperpolarize and cause rebound spike-like activity
A.setProtocol('CurrentStep');
A.protocol.setParams('-q',...
    'preDurInSec',0.2,...
    'stimDurInSec',0.2,...
    'postDurInSec',0.2,...
    'steps',[-10 10 20 40]);          % tune this
A.run(5)
systemsound('Notify');

