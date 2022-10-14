function [DetectedSpikes] = sp_spikedetection(ProcessedData,RawData,ReferenceSpike,DetectionParameters)

DetectedSpikes = [];
SpikeIndex = 1;


%note pour moi : getdata reprenait les séquence de temps
%intéressantes (i.e. trial) + calculait éventuellement par rapport à
%une électrode de référence + refasait un resample à 200Hz
%Maintenant les rawdata ont déjà été traité par les autres librairires
%de spm (création de trials & référencement correct!)
%[RawData] = GetData(Recording.timeIn(k),Recording.timeOut(k),nrElectrodeLeft,nrElectrodeRight,Recording.fname,DetectionParameters);

%note pour moi : on a décidé d'enlever le preprocessing pour éviter de le
%faire à la première détection ainsi qu'aux autres détectiosn
%[ProcessedData] = sp_preprocessing(RawData,DetectionParameters); %preprocessing the signal using filter + signed squaring
%note pour moi corrélation à réimplémenter ou bien à trouver un équivalent
%(image processing toolbox)
VprodScNorm = normxcorr2(ReferenceSpike.Template,ProcessedData); %cross correlation between the templte & the data
VprodScNorm = VprodScNorm(ReferenceSpike.TemplateLength:end);

mindist=round(DetectionParameters.MinimumDistance2Spikes/1000*DetectionParameters.Fs); %minimum distance between two spikes
%findpeaks : signal processing toolbox --> à réimplémenter ou trouver
[pks,locs] = findpeaks(VprodScNorm,'MINPEAKHEIGHT',ReferenceSpike.CorrelationThreshold,'MINPEAKDISTANCE',mindist);
%note pour moi EpochspikeIndex = 1 = spikeindex car plus de trial ici (pour
%l'instant)
if ~isempty(pks)    
    EpochSpikeIndex = 1;
    while EpochSpikeIndex <= length(locs)
        %spike candidate isolation in the signal
        CurrentSpike = ProcessedData(locs(EpochSpikeIndex):min([locs(EpochSpikeIndex)+ReferenceSpike.TemplateLength-1,length(ProcessedData)]));
        %features extraction fo the current spike
        [RisingSlope PositionRisingSlope] = max(CurrentSpike);
        RisingSlope = sqrt(abs(RisingSlope));
        [FallingSlope PositionFallingSlope] = min(CurrentSpike);
        FallingSlope = -sqrt(abs(FallingSlope));
        Curvature = abs((RisingSlope - FallingSlope)/(PositionRisingSlope - PositionFallingSlope));
        %check if the features are ok
        if ((FallingSlope<ReferenceSpike.FallingSlopeThreshold) && (RisingSlope>ReferenceSpike.RisingSlopeThreshold) && (Curvature>ReferenceSpike.CurvatureThreshold))
            %note pour moi : bug possible ici si une pointe est plus courte que
            %la pointe template !!!! --> à vérifier
            DetectedSpikes.ProcessedSpikes(SpikeIndex,:) = CurrentSpike;
            DetectedSpikes.RisingSlope(SpikeIndex) = RisingSlope;
            DetectedSpikes.FallingSlope(SpikeIndex) = FallingSlope;
            DetectedSpikes.Curvature(SpikeIndex) = Curvature;
            SpikeIndex = SpikeIndex + 1;
            EpochSpikeIndex = EpochSpikeIndex + 1;
        else %remove the spike if the features are not good
            locs(EpochSpikeIndex) = [];
        end
    end
    
    %question à Antoine : pq on enlève la dernière pointe détectée ???
%     DetectedSpikes.ProcessedSpikes = DetectedSpikes.ProcessedSpikes(1:SpikeIndex-1,:);
%     DetectedSpikes.RisingSlope = DetectedSpikes.RisingSlope(1:SpikeIndex-1);
%     DetectedSpikes.FallingSlope = DetectedSpikes.FallingSlope(1:SpikeIndex-1);
%     DetectedSpikes.Curvature = DetectedSpikes.Curvature(1:SpikeIndex-1);
    
    DetectedSpikes.Epoch = sp_adj_spikes_pos(locs,RawData,mindist);
    DetectedSpikes.lgData=length(RawData);
    %plus d'epoch --> on retire
    %DetectedSpikes.Epoch(k).DetectedTime = [1000*Recording.timeIn(k)+round(1000/DetectionParameters.Fs)*locs' 1000*Recording.timeIn(k)+round(1000/DetectionParameters.Fs)*(locs+ReferenceSpike.TemplateLength)'];
end


