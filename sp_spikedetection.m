function [DetectedSpikes] = sp_spikedetection(ProcessedData,RawData,ReferenceSpike,DetectionParameters)

DetectedSpikes = [];
SpikeIndex = 1;


%note pour moi : getdata reprenait les s�quence de temps
%int�ressantes (i.e. trial) + calculait �ventuellement par rapport �
%une �lectrode de r�f�rence + refasait un resample � 200Hz
%Maintenant les rawdata ont d�j� �t� trait� par les autres librairires
%de spm (cr�ation de trials & r�f�rencement correct!)
%[RawData] = GetData(Recording.timeIn(k),Recording.timeOut(k),nrElectrodeLeft,nrElectrodeRight,Recording.fname,DetectionParameters);

%note pour moi : on a d�cid� d'enlever le preprocessing pour �viter de le
%faire � la premi�re d�tection ainsi qu'aux autres d�tectiosn
%[ProcessedData] = sp_preprocessing(RawData,DetectionParameters); %preprocessing the signal using filter + signed squaring
%note pour moi corr�lation � r�impl�menter ou bien � trouver un �quivalent
%(image processing toolbox)
VprodScNorm = normxcorr2(ReferenceSpike.Template,ProcessedData); %cross correlation between the templte & the data
VprodScNorm = VprodScNorm(ReferenceSpike.TemplateLength:end);

mindist=round(DetectionParameters.MinimumDistance2Spikes/1000*DetectionParameters.Fs); %minimum distance between two spikes
%findpeaks : signal processing toolbox --> � r�impl�menter ou trouver
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
            %la pointe template !!!! --> � v�rifier
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
    
    %question � Antoine : pq on enl�ve la derni�re pointe d�tect�e ???
%     DetectedSpikes.ProcessedSpikes = DetectedSpikes.ProcessedSpikes(1:SpikeIndex-1,:);
%     DetectedSpikes.RisingSlope = DetectedSpikes.RisingSlope(1:SpikeIndex-1);
%     DetectedSpikes.FallingSlope = DetectedSpikes.FallingSlope(1:SpikeIndex-1);
%     DetectedSpikes.Curvature = DetectedSpikes.Curvature(1:SpikeIndex-1);
    
    DetectedSpikes.Epoch = sp_adj_spikes_pos(locs,RawData,mindist);
    DetectedSpikes.lgData=length(RawData);
    %plus d'epoch --> on retire
    %DetectedSpikes.Epoch(k).DetectedTime = [1000*Recording.timeIn(k)+round(1000/DetectionParameters.Fs)*locs' 1000*Recording.timeIn(k)+round(1000/DetectionParameters.Fs)*(locs+ReferenceSpike.TemplateLength)'];
end


