function [FirstDet] = sp_genericdetection(RawData,DetectionParameters)

% ************************************************************************
% Main function : first detection by using the generated template
% ************************************************************************
        
% A generic template is used
[GenericTemplate] = sp_generategenerictemplate(DetectionParameters);

% first detection
FirstDet = sp_spikedetection(RawData,GenericTemplate,DetectionParameters);