function simpleSpikeDetector(epochs, parameter)

% description : Simple spike detection from SchwartzNU Analysis folder; Refer https://github.com/SchwartzNU/SymphonyAnalysis/blob/master/GUIs/SpikeDetectorGUI.m
% mode:
%   default : Advanced
%   description: Type of spike detection, Example- 'Simple threshold' (or) 'Advanced'
% threshold:
%   default: -10
%   description: Threshold value to detect spikes
% overwrite:
%   default: false
%   description: Can override previously detected feature
% devices:
%   default: "@(epoch, devices) sa_labs.analysis.common.getdeviceForEpoch(epoch, devices)"
%   description: List of amplifier channels for the given epoch
% ---

thresholdSign =  sign(parameter.threshold);
threshold = parameter.threshold;
mode = parameter.mode;
structure = load(which('spikeFilter.mat'));
spikeFilter = structure.spikeFilter;

for epochData = epochs
    for i = 1 : numel(parameter.devices)
        device = parameter.devices{i};
        
        if epochData.hasDerivedResponse('spikeTimes', device) && ~ parameter.overwrite
            error('spikeTimes already present! To overwrite, Click on overwrite in simpleSpikeDetector pre-processor');
        end
        
        sampleRate = epochData.get('sampleRate');
        data = epochData.getResponse(device);
        response = data.quantity';
        
        spikeIndices = getThresCross(response, threshold, thresholdSign);
        
        if strcmpi(mode, 'Simple threshold')
            spikeIndices = getThresCross(response, threshold, thresholdSign);
        elseif strcmpi(mode, 'Advanced')
            [fresponse, noise] = filterResponse(response, spikeFilter);
            spikeIndices = getThresCross(fresponse, noise * threshold, thresholdSign);
            epochData.addDerivedResponseInMemory('filteredResponse', fresponse, device);
        end
        
        if threshold < 0
            spikeIndices = getSpikeIndicesForNegativeThresold(spikeIndices, response);
        else
            spikeIndices = getSpikeIndicesForPositiveThresold(spikeIndices, response);
        end
        
        % Remove double-counted spikes
        if length(spikeIndices) >= 2
            ISItest = diff(spikeIndices);
            spikeIndices = spikeIndices([(ISItest > (0.001 * sampleRate)) true]);
        end
        epochData.addDerivedResponse('spikeTimes', spikeIndices, device);
    end
end
end

function Ind = getThresCross(V,th,dir)
%dir 1 = up, -1 = down

Vorig = V(1:end-1);
Vshift = V(2:end);

if dir>0
    Ind = find(Vorig<th & Vshift>=th) + 1;
else
    Ind = find(Vorig>=th & Vshift<th) + 1;
end
end

function [fdata, noise] = filterResponse(fdata, spikeFilter)

fdata = [fdata(1) + zeros(1,2000), fdata, fdata(end) + zeros(1,2000)];
fdata = filtfilt(spikeFilter, fdata);
fdata = fdata(2001:(end-2000));
noise = median(abs(fdata) / 0.6745);

end

function spikeIndices = getSpikeIndicesForNegativeThresold(spikeIndices, response)
for spikeIndex = 1 : length(spikeIndices)
    sp = spikeIndices(spikeIndex);
    if sp < 100 || sp > length(response) - 100
        continue
    end
    while response(sp) > response(sp + 1)
        sp = sp + 1;
    end
    while response(sp) > response(sp - 1)
        sp = sp - 1;
    end
    spikeIndices(spikeIndex) = sp;
end
end

function spikeIndices = getSpikeIndicesForPositiveThresold(spikeIndices, response)
for spikeIndex = 1 : length(spikeIndices)
    sp = spikeIndices(spikeIndex);
    if sp < 100 || sp > length(response) - 100
        continue
    end
    while response(sp) < response(sp + 1)
        sp = sp + 1;
    end
    while response(sp) < response(sp - 1)
        sp = sp - 1;
    end
    spikeIndices(spikeIndex) = sp;
end
end