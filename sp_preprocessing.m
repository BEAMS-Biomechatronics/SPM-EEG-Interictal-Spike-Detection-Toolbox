function [ProcessedData] = sp_preprocessing(RawData,DetectionParameters)

LengthData = length(RawData);
RawData = sp_filter(RawData,DetectionParameters);

% First derivation estimation
Der(1) = (2*RawData(1))./8;
Der(2) = (2*RawData(2)+RawData(1))./8;
Der(3) = (2*RawData(3)+RawData(2))./8;
Der(4) = (2*RawData(4)+RawData(3)-RawData(1))./8;
Der(5:LengthData) = (2*RawData(5:LengthData,:)+RawData(4:LengthData-1,:)-RawData(2:LengthData-3,:)-2*RawData(1:LengthData-4,:))./8;

% Squaring
Der = (Der.^2).*sign(Der);

% Smoothing
AverageWindow = round(DetectionParameters.Fs/20); %avaraging on a 50ms window 
ProcessedData(AverageWindow,LengthData) = 0;

ProcessedData(1,:)=Der';
newElem = Der(1);
for n=2:AverageWindow
    ProcessedData(n,:)=[newElem ProcessedData(n-1,1:end-1)];
end;
ProcessedData=sum(ProcessedData)/AverageWindow;

