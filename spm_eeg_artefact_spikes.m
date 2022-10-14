function res = spm_eeg_artefact_spikes(S)
% Detects spikes in spm data file by Antoine Nonclercq 
% S                     - input structure
% fields of S:
%    S.D                - M/EEG object
%    S.chanind          - vector of indices of channels that this plugin will look at.
%    S.threshold        - threshold parameter (in stdev)
%
%    Additional parameters can be defined specific for each plugin
% Output:
%  res -
%   If no input is provided the plugin returns a cfg branch for itself
%
%   If input is provided the plugin returns a matrix of size D.nchannels x D.ntrials
%   with zeros for clean channel/trials and ones for artefacts.
%______________________________________________________________________________________
% Copyright (C) 2008-2013 Wellcome Trust Centre for Neuroimaging

% Antoine Nonclercq & Rudy Ercek based on Vladimir Litvak's code !!!

% This part if for creating a config branch that plugs into spm_cfg_eeg_artefact
% Any parameters can be specified and they are then passed to the plugin
% when it's called.
%--------------------------------------------------------------------------
if nargin == 0           

    MinDist2Spikes = cfg_entry;
    MinDist2Spikes.tag = 'MinDist2Spikes';
    MinDist2Spikes.name = 'Minimum distance between 2 spikes';    
    MinDist2Spikes.strtype = 'r';
    MinDist2Spikes.num = [1 1];
    MinDist2Spikes.val = {75};
    MinDist2Spikes.help = {'Minimum distance/delay between 2 spikes (in ms)'};
  
    winlg = cfg_entry;
    winlg.tag = 'winlg';
    winlg.name = 'Window Length';
    winlg.strtype = 'r';
    winlg.num = [1 1];
    winlg.val = {300};
    winlg.help = {'Spike Window length (in ms)'};    
    
    genxcorrthr = cfg_entry;
    genxcorrthr.tag = 'genxcorrthr';
    genxcorrthr.name = 'Generic x-correl Threshold';
    genxcorrthr.strtype = 'r';
    genxcorrthr.num = [1 1];
    genxcorrthr.val = {0.6};
    genxcorrthr.help = {'Generic spike detection parameters : cross-correlation threshold'};    
   
    genfeatthr = cfg_entry;
    genfeatthr.tag = 'genfeatthr';
    genfeatthr.name = 'Generic Features Threshold';
    genfeatthr.strtype = 'r';
    genfeatthr.num = [1 1];
    genfeatthr.val = {0.3};
    genfeatthr.help = {'Generic spike detection parameters : Features threshold'}; 
    
    gentempamp = cfg_entry;
    gentempamp.tag = 'gentempamp';
    gentempamp.name = 'Generic Template Amplitude';
    gentempamp.strtype = 'r';
    gentempamp.num = [1 1];
    gentempamp.val = {200};
    gentempamp.help = {'Generic spike detection parameters : Template amplitude'}; 
    
    patxcorrthr = cfg_entry;
    patxcorrthr.tag = 'patxcorrthr';
    patxcorrthr.name = 'Patient x-correl Threshold';
    patxcorrthr.strtype = 'r';
    patxcorrthr.num = [1 1];
    patxcorrthr.val = {0.7};
    patxcorrthr.help = {'Patient Specific spike detection parameters : Cross-correlation threshold'}; 

    patfeatthr = cfg_entry;
    patfeatthr.tag = 'patfeatthr';
    patfeatthr.name = 'Patient Features Threshold';
    patfeatthr.strtype = 'r';
    patfeatthr.num = [1 1];
    patfeatthr.val = {0.5};
    patfeatthr.help = {'Patient Specific spike detection parameters : Features threshold'}; 
       
    patminswi = cfg_entry;
    patminswi.tag = 'patminswi';
    patminswi.name = 'Patient minimum SWI';
    patminswi.strtype = 'r';
    patminswi.num = [1 1];
    patminswi.val = {0.1};
    patminswi.help = {'Minimum SWI in order to use the patient specific spike detection algorithm'}; 
       
    clusterselthr = cfg_entry;
    clusterselthr.tag = 'clusterselthr';
    clusterselthr.name = 'Cluster Selection Threshold';
    clusterselthr.strtype = 'r';
    clusterselthr.num = [1 1];
    clusterselthr.val = {0.05};
    clusterselthr.help = {'Cluster Selection Threshold for rejecting a group of similar spikes'};
 
    lpfilt = cfg_entry;
    lpfilt.tag = 'lpfilt';
    lpfilt.name = 'Lowpass Butterworth Filter cutoff freq';
    lpfilt.strtype = 'r';
    lpfilt.num = [1 1];
    lpfilt.val = {35};
    lpfilt.help = {'Pre-processing : Cutoff frequency (Hz) for a lowpass butterworth zero-phase filter applied to both signal and generic template : 0 to disable it'};

    hpfilt = cfg_entry;
    hpfilt.tag = 'hpfilt';
    hpfilt.name = 'Highpass Butterworth Filter cutoff freq';
    hpfilt.strtype = 'r';
    hpfilt.num = [1 1];
    hpfilt.val = {0.16};
    hpfilt.help = {'Pre-processing : Cutoff frequency (Hz) for a highpass butterworth zero-phase filter applied to both signal and generic template : 0 to disable it'};
    
    clrevent = cfg_menu;
    clrevent.tag = 'clrevent';
    clrevent.name = 'Clear all events';
    clrevent.labels = {'yes', 'no'};
    clrevent.val = {false};
    clrevent.values = {true, false};
    clrevent.help = {'Clear all events before adding new ones i.e. spikes !'};    
    
    globalev = cfg_menu;
    globalev.tag = 'globalev';
    globalev.name = 'Merge all spike events';
    globalev.labels = {'yes', 'no'};
    globalev.val = {false};
    globalev.values = {true, false};
    globalev.help = {'Create only one spike event for all selected channels if the spike distance is less than the Minimum distance between 2 spikes value!'};    
    
    cfgspikes = cfg_branch;
    cfgspikes.tag = 'spikes';
    cfgspikes.name = 'Spikes';
    cfgspikes.val = {clrevent,MinDist2Spikes,globalev,winlg,genxcorrthr,genfeatthr,gentempamp,patxcorrthr,patfeatthr,patminswi,clusterselthr,lpfilt,hpfilt};
    
    res = cfgspikes;
    
    return
end

SVNrev = '$Rev: 0001 $';

%-Startup
%--------------------------------------------------------------------------
spm('sFnBanner', mfilename, SVNrev);
spm('FigName','M/EEG spikes detection');

%add spikes function (toolbox) in the path
sp_path=[spm('Dir') '\spikes'];
addpath(sp_path);

%Statistic toolbox should be installed for "kmeans" function
if isempty(which('kmeans'))
    error('Matlab Statistics Toolbox has to be installed !');
end

%Signal processing toolbox should be installed for "findpeaks" function
if isempty(which('findpeaks'))
    error('Matlab Signal Processing Toolbox has to be installed !');
end

%Image processing toolbox should be installed for "normxcorr2" function
if isempty(which('normxcorr2'))
    error('Matlab Image Processing Toolbox has to be installed !');
end

if isequal(S.mode, 'reject')
    error('Only mark mode is supported by this plug-in, use event-based rejection to reject.');
end

D = spm_eeg_load(S.D);

% Detect spikes using Nonclercq's Algorithm
%------------------------------------------
% General parameters
DetectionParameters.MinimumDistance2Spikes = S.MinDist2Spikes; % ms
DetectionParameters.WindowLength = S.winlg; % ms

% Generic spike detection parameters
DetectionParameters.GenericCrossCorrelationThresh = S.genxcorrthr; % Cross-correlation threshold
DetectionParameters.GenericFeaturesThresh = S.genfeatthr; % Features threshold
DetectionParameters.GenericTemplateAmplitude = S.gentempamp;

% Patient Specific spike detection parameters
DetectionParameters.PatientSpecificCrossCorrelationThresh = S.patxcorrthr; % Cross-correlation threshold
DetectionParameters.PatientSpecificFeaturesThresh = S.patfeatthr; % Features threshold
DetectionParameters.PatientSpecificMinimumSWI = S.patminswi;
DetectionParameters.ClusterSelectionThresh = S.clusterselthr;

% Sampling Frenquency for the signal
DetectionParameters.Fs=D.fsample;

%Filters 
DetectionParameters.lp=S.lpfilt; %Lowpass filter
DetectionParameters.hp=S.hpfilt; %Highpass wfilter
nbchan = length(S.chanind); %number of channel to analyze

if nbchan==0 
    error('At least one channel has to be selected !');
end

sp=[]; %structure to save spike information for each channel
AllSpikes=[]; %index of all detected spikes (for all selected channels)
if S.clrevent
    disp(['Clearing all events in file "' D.fname '" before adding spikes events!']);
    for n=1:D.ntrials
        D=events(D,n,[]);
    end
end
disp(['Spike Detection for ' num2str(nbchan) ' channel(s) is started!']);
strchan=[];
%create the generic spike template for first detection
[GenericTemplate] = sp_generategenerictemplate(DetectionParameters);
for ch=1:nbchan
    chanind=S.chanind(ch);
    spikes=[];
    RawData = reshape(squeeze(D(chanind,:,:)), 1, [])'; %extract the current channel data
    ProcessedData = sp_preprocessing(RawData,DetectionParameters);
    sp(ch).GenDet = sp_spikedetection(ProcessedData,RawData,GenericTemplate,DetectionParameters); %spike detection using the template
    if ~isempty(sp(ch).GenDet)        
        sp(ch).StatGenDet = sp_stats(sp(ch).GenDet,DetectionParameters);
        if sp(ch).StatGenDet.SWI > DetectionParameters.PatientSpecificMinimumSWI
            sp(ch).Clusters = sp_clustersfromdetect(DetectionParameters.ClusterSelectionThresh,sp(ch).GenDet);
            sp(ch).PatientSpecificDetSpikes = sp_detfromclusters(sp(ch).Clusters,ProcessedData,RawData,DetectionParameters);            
            spikes = sp(ch).PatientSpecificDetSpikes;
        else
            spikes = sp(ch).GenDet.Epoch;
        end
        Det.lgData=length(RawData);
        Det.Epoch=spikes;
        AllSpikes=[AllSpikes spikes];
        sp(ch).stat=sp_stats(Det,DetectionParameters); %compute statistics (i.e. SWI)
        disp(['Number of spikes detected in channel ' char(D.chanlabels(chanind)) ' : ' num2str(length(spikes)) ' (SWI = ' num2str(sp(ch).stat.SWI) ')']);
    end
    
    if ~isempty(spikes)
       if ~S.globalev
            D=add_events(D,S,spikes+1,char(D.chanlabels(chanind)));
       else
           strchan=[strchan char(D.chanlabels(chanind)) ','];
       end
    else
        warning(['No spikes events detected in the selected channel : ' char(D.chanlabels(chanind))]);
    end
end
%Global Statistic
GlobalSpikes=[];
if ~isempty(AllSpikes)
    GlobalSpikes.spikes=sort(AllSpikes);
    GlobalSpikes.spmerged=sp_merge_epoch(GlobalSpikes.spikes,round(DetectionParameters.Fs*DetectionParameters.MinimumDistance2Spikes/1000));        
    Det.Epoch=GlobalSpikes.spikes;
    GlobalSpikes.stat=sp_stats(Det,DetectionParameters);
    Det.Epoch=GlobalSpikes.spmerged;
    GlobalSpikes.statmerged=sp_stats(Det,DetectionParameters);
    disp(['Number of spikes detected through all selected channels : ' num2str(length(GlobalSpikes.spikes)) ' (Global SWI = ' num2str(GlobalSpikes.stat.SWI) ')']);
    disp(['Number of merged spikes detected through all selected channels : ' num2str(length(GlobalSpikes.spmerged)) ' (Global SWI = ' num2str(GlobalSpikes.statmerged.SWI) ')']);
    if S.globalev
        D=add_events(D,S,GlobalSpikes.spmerged+1,strchan(1:end-1));
    end
end
save([D.path '\sp_' D.fname],'sp','DetectionParameters','S','GlobalSpikes');    %for debug/info

res = D;



% Update the event structure (copy paste from heartbeat with some modifications)
%------------------------------------------------------------------------------
function Dout=add_events(Din,S,spikes,value)
D=Din;
for n = 1:D.ntrials
    cspikes   = spikes(spikes>(D.nsamples*(n-1)) & spikes<(D.nsamples*n));
    ctime  = D.trialonset(n)+(cspikes - D.nsamples*(n-1)-1)/D.fsample;
    ctime  = num2cell(ctime);
    
    ev = events(D, n);
    
    if iscell(ev)
        ev = ev{1};
    end
    
    if ~isempty(ev) && ~S.append
        ind1 = strmatch('spike', {ev.type}, 'exact');
        if ~isempty(ind1)
            ind2 = strmatch(value, {ev(ind1).value}, 'exact');
            if ~isempty(ind2)
                ev(ind1(ind2)) = [];
            end
        end
    end
    
    Nevents = numel(ev);
    for i=1:numel(ctime)
        if ctime{i} == 0
            continue; %likely to be trial border falsely detected as spikes
        end
        ev(Nevents+i).type     = 'spike';
        ev(Nevents+i).value    = value;
        ev(Nevents+i).duration = [];
        ev(Nevents+i).time     = ctime{i};
    end
    
    if ~isempty(ev)
        [dum, I] = sort([ev.time]);
        ev = ev(I);
        D = events(D, n, ev);
    end
end
Dout=D;



