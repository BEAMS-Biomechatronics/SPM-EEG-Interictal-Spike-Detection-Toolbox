function [PatientSpecificDetSpikes] = sp_detfromclusters(Clusters,ProcessedData,RawData,DetectionParameters)

PatientSpecificDetSpikesCluster(Clusters.NumClusters).Det = [];
DetEpoch=[];
mindist=round(DetectionParameters.Fs*DetectionParameters.MinimumDistance2Spikes/1000);
for CurrentCluster = 1:Clusters.NumClusters
    
    Clusters.PatientSpecificDetSpikesResult(CurrentCluster).SpikeRawData = [];
    if any(CurrentCluster == Clusters.RejectedClusters)==0
        PatientSpecificDetectionParameters.Template = Clusters.Centroids(CurrentCluster,:);
        PatientSpecificDetectionParameters.TemplateLength = length(PatientSpecificDetectionParameters.Template);
        PatientSpecificDetectionParameters.TemplateNorm = norm(PatientSpecificDetectionParameters.Template);

        PatientSpecificDetectionParameters.RisingSlopeThreshold = mean(Clusters.FeatureCluster(CurrentCluster).RisingSlope)*DetectionParameters.PatientSpecificFeaturesThresh;
        PatientSpecificDetectionParameters.FallingSlopeThreshold = mean(Clusters.FeatureCluster(CurrentCluster).FallingSlope)*DetectionParameters.PatientSpecificFeaturesThresh;
        PatientSpecificDetectionParameters.CurvatureThreshold = mean(Clusters.FeatureCluster(CurrentCluster).Curvature)*DetectionParameters.PatientSpecificFeaturesThresh;
        PatientSpecificDetectionParameters.CorrelationThreshold = DetectionParameters.PatientSpecificCrossCorrelationThresh;

        PatientSpecificDetSpikesCluster(CurrentCluster).Det = sp_spikedetection(ProcessedData,RawData,PatientSpecificDetectionParameters,DetectionParameters);
        DetEpoch=[DetEpoch PatientSpecificDetSpikesCluster(CurrentCluster).Det.Epoch];

    end
end
PatientSpecificDetSpikes=sp_merge_epoch(sort(DetEpoch),mindist);

