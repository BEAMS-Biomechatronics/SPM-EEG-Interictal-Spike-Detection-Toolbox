function [GenericTemplate] =  sp_generategenerictemplate(DetectionParameters)

%number of sample in the generice template window
EndWindow = round(DetectionParameters.Fs*DetectionParameters.WindowLength/1000); 
%limit for a 60ms triangle (in samples)
MidSpike = round(DetectionParameters.Fs*30/1000); % 30ms
EndSpike = round(DetectionParameters.Fs*60/1000); % 60ms

%generate a 60ms triangle
V(round(1.33*EndWindow))=0; %for filtering generate a longer temporary window (33% longer)
V([1:MidSpike]) = round([1:MidSpike]*DetectionParameters.GenericTemplateAmplitude/MidSpike);
V([MidSpike:EndSpike]) = round(DetectionParameters.GenericTemplateAmplitude-([MidSpike:EndSpike]-MidSpike)*DetectionParameters.GenericTemplateAmplitude/MidSpike);

%pre-process the data (filter and squaring)
ProcessedData = sp_preprocessing(V',DetectionParameters);
ProcessedData = ProcessedData(1:EndWindow);

%create a structure for the generated template (data & features)
GenericTemplate.Exists = 1;
GenericTemplate.Template = ProcessedData;
GenericTemplate.TemplateLength = length(ProcessedData);
GenericTemplate.TemplateNorm = norm(ProcessedData);
[GenericTemplate.RisingSlope PositionRisingSlope] = max(ProcessedData);
GenericTemplate.RisingSlope = sqrt(abs(GenericTemplate.RisingSlope));
[GenericTemplate.FallingSlope PositionFallingSlope] = min(ProcessedData);
GenericTemplate.FallingSlope = -sqrt(abs(GenericTemplate.FallingSlope));
GenericTemplate.Curvature = abs((GenericTemplate.RisingSlope - GenericTemplate.FallingSlope)/(PositionRisingSlope - PositionFallingSlope)); 

GenericTemplate.RisingSlopeThreshold = GenericTemplate.RisingSlope*DetectionParameters.GenericFeaturesThresh; 
GenericTemplate.FallingSlopeThreshold = GenericTemplate.FallingSlope*DetectionParameters.GenericFeaturesThresh; 
GenericTemplate.CurvatureThreshold = GenericTemplate.Curvature*DetectionParameters.GenericFeaturesThresh; 
GenericTemplate.CorrelationThreshold = DetectionParameters.GenericCrossCorrelationThresh;