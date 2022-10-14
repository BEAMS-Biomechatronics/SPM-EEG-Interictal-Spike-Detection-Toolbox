function [Clusters] = sp_clustersfromdetect(ClusterSelectionThresh,DetectedSpikes)

NumDetectedSpikes = length(DetectedSpikes.ProcessedSpikes(:,1));

if NumDetectedSpikes>1
    % Sort spikes as a function of energies for IC. 
    SpikeEnergy = std(DetectedSpikes.ProcessedSpikes,0,2);
    [sortE,sortEind]=sort(SpikeEnergy);
    SortedSpikes=DetectedSpikes.ProcessedSpikes(sortEind,:);
    % Starting from one single cluster, the number of clusters increases until one
    % or more clusters contain less than 5% of the spikes
    NumClusters = 0; %We could begin at 1 (so 2 clusters in while loop), ask antoine
    MinClustr = NumDetectedSpikes;
    while (MinClustr/NumDetectedSpikes > ClusterSelectionThresh) && (NumClusters<NumDetectedSpikes)
        NumClusters = NumClusters + 1;
        
        % Divide spikes in classes as a function of energies for IC. 
        for i = 1:NumClusters
            LowerBound = ceil((i-1)*(NumDetectedSpikes-1)/NumClusters+1);
            UpperBound = floor(i*(NumDetectedSpikes-1)/NumClusters+1);
            IC(i,:) = mean(SortedSpikes(LowerBound:UpperBound,:));
        end
        
        % Clustering
        warning('off','all'); % Stop display warning in case of empty cluster
        %Note pour moi : kmeans à réimplementer ou à trouver car Matlab Statistic Toolbox !
        [ClusterIndices,Centroids] = kmeans(DetectedSpikes.ProcessedSpikes,NumClusters,'distance','correlation','start',IC,'emptyaction','drop');
        warning('on','all');
        
        countClust = histc(ClusterIndices,1:NumClusters);
        MinClustr = min(countClust);
    end;
    % Removing empty clusters
    ind=find(countClust>0); %find indices with no empty clusters
    lookup=zeros(NumClusters,1);
    NumClusters=length(ind); %update the number of "not empty" clusters
    lookup(ind)=[1:NumClusters]; %Lookup table for cluster indice NB: new value of NumClusters !!! (equal or less than previous one)
    ClusterIndices=lookup(ClusterIndices); %update the clusterindices
    Centroids=Centroids(ind,:); %update the Centroids    
       
    % The cluster, or the clusters, showing less than 5% of spikes are discarded.
    countClust = histc(ClusterIndices,1:NumClusters); %compute the number of spikes per cluster
    RejectedClusters = find(countClust/NumDetectedSpikes < ClusterSelectionThresh);
    %Features assignement by Cluster
    for i = 1:NumClusters
        ind=find(ClusterIndices==i);
        FeatureCluster(i).RisingSlope=DetectedSpikes.RisingSlope(ind);
        FeatureCluster(i).FallingSlope=DetectedSpikes.FallingSlope(ind);
        FeatureCluster(i).Curvature=DetectedSpikes.Curvature(ind);
    end
    
    Clusters.Centroids = Centroids;
    Clusters.RejectedClusters = RejectedClusters;
    Clusters.NumClusters = NumClusters;
    Clusters.FeatureCluster = FeatureCluster;
else
    Clusters = [];
end
