function [Stat] = sp_stats(Det,DetectionParameters)

Fs=DetectionParameters.Fs;
lg=Det.lgData;
nbsec=ceil(lg/Fs); %number of signal second
nbsecreal=round(lg/Fs); %rounded number of signal seconds (the last second of signal is considered only if it is longer than half a second)
isspikes=zeros(Fs,nbsec);
isspikes(Det.Epoch)=1;
isspikesinsec=max(isspikes,[],1);
Stat.IsSpikesInSec=isspikesinsec(1:nbsecreal); %determine for each signal second if a spike is present (value 0 not present, value 1 present)
Stat.SWI=sum(Stat.IsSpikesInSec)/nbsecreal; %computed the SWI i.e. the proportion of signal seconds that is contaminated by spikes

