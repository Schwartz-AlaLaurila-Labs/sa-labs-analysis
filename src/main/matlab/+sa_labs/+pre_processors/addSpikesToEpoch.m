function addSpikesToEpoch(cellData, varargin)

ip = inputParser;
ip.addParameter('devices', {'Amp1'}, @iscellstr);
ip.addParameter('checkDetection', false, @islogical);
ip.parse(varargin{:});
devices = ip.Results.devices;
checkDetection = ip.Results.checkDetection;


for epoch = cellData.epochs
    for device = each(devices)
        try
            
            data = epoch.getResponse(device).quantity;
            spikeTime =  mht.spike_util.detectSpikes(data, 'checkDetection', checkDetection);
            
            id = strcat('SPIKES', upper(device));
            epoch.attributes(id) = createFeature(id, spikeTime);
        catch
            disp(exception.message);
        end
    end
end
end

function f = createFeature(id, data)
import sa_labs.analysis.*;

map = containers.Map();
map('id') = id;
description = entity.FeatureDescription(map);
f = entity.Feature(description, data);
end


