 function [ProcessedData] = sp_filter(RawData,DetectionParameters)

Fc_LP = DetectionParameters.lp; 
Fc_HP = DetectionParameters.hp; 
ProcessedData=RawData;

if Fc_LP
    Wn = Fc_LP/(DetectionParameters.Fs/2); 
    [Blp,Alp] = butter(5,Wn); 
    ProcessedData = filtfilt(Blp,Alp,ProcessedData);     
end


if Fc_HP
    Wn = Fc_HP/(DetectionParameters.Fs/2); 
    [Bhp,Ahp] = butter(5,Wn,'high'); 
    ProcessedData = filtfilt(Bhp,Ahp,ProcessedData); 
end