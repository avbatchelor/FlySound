%% Whole cell voltage clamp, imaging Ca in the terminals of B1 cells
% Aiming for Big Spiker in the GH86-Gal4;ArcLight; Line.  Trying to elicit
% single spikes while hyperpolarized. Filling the cell with Alexa 594 (10uM
% or 50uM) and Fluo5F (150uM or 300uM).  Find the terminal under 2P at 925
% nm illumination, change the wavelength to 800nm, then watch terminals
% fill in the red channel, start imaging the green channel.

% 1) Beginning of the day: start acquisition here in order to have a file
% to save images to.

setpref('AcquisitionHardware','twoPToggle','off')

% Start the bitch 
clear all, close all
A = Acquisition;

%% 
% Procedure is:
% Before dropping the electrode in, startup the acquisition and the
% imaging.  
% Zoom the 2P all the way out.  
% Find the cell under normal illumination and with the LED.  
% Image the cell under 2P. at wide zoom
% Adjust the laser wavelength to 800.
%
% Now bring the electrode down, could try imaging the electrode first
% Patch the cell.
% (Maybe image while ruputuring, could see the dialysis of the cell)
%
% Now connect the imaging with the physiology
% Set up the directory
% Paste the images name
% Enter the line number and repeats
% Start the physiology protocol

%% Seal
toggleTwoPPref('off')
A.setProtocol('SealAndLeak');
A.tag('Seal')
A.run
A.untag('Seal')

%% Take a quick sweep early after break-in just to see base line at the ROI 
toggleTwoPPref('on')
A.setProtocol('Sweep');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q','durSweep',5);
A.run(2)
systemsound('Notify');

%% Start by trying to see changes in calcium levels when the cell is hyperpolarized
A.setProtocol('CurrentStep');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'preDurInSec',0.2,...
    'stimDurInSec',0.4,...
    'postDurInSec',0.5,...
    'steps',-100);          % tune this
A.tag('Hyperpolarizing steps')
A.run(5)
A.untag('Hyperpolarizing steps')
systemsound('Notify');

%% Start trying to measure spikes going above threshold
% switch to current clamp

A.setProtocol('CurrentPlateau');
% A.rig.setParams('interTrialInterval',1);
plateaux = [repmat(-35,1,3), -32,repmat(-35,1,6)];
A.protocol.setParams('-q','preDurInSec',1.5,...
    'postDurInSec',1.5,'stimDurInSec',0.025,'plateaux',plateaux,'randomize',0);
A.run(3)
systemsound('Notify');

%% CurrentChirp - up
A.setProtocol('CurrentChirp');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'freqStart',17,...
    'freqEnd',400,...
    'amps',[20],... % [10 40]
    'postDurInSec',1);
A.run(3)
systemsound('Notify');

%% CurrentChirp - down
A.setProtocol('CurrentChirp');
A.rig.setParams('interTrialInterval',1);
A.protocol.setParams('-q',...
    'freqStart',800,...
    'freqEnd',17,...
    'amps',[2.5 10],...
    'postDurInSec',1);
A.run(3)
systemsound('Notify');


%% CurrentSine
A.setProtocol('CurrentSine');
A.rig.setParams('interTrialInterval',1);
freqs = 25 * sqrt(2) .^ (0:10); 
A.protocol.setParams('-q','freqs',freqs,'amps',[0.1 0.2 0.4],'postDurInSec',1);
A.run(3)
systemsound('Notify');

%% Finally, image the whole cell.
