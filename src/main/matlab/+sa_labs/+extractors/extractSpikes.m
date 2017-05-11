function extractSpikes(analysis, group, varargin)

ip = inputParser;
ip.addParameter('device', '', @ischar);
ip.parse(varargin{:});

if strcmpi(group.splitParameter, 'devices')
    device = group.splitValue;
else
    device = ip.Results.device;
end

id = strcat('SPIKES', upper(device));

for epoch = analysis.getEpochs(group)
    data = epoch.get(id);
    group.createFeature(id, data);
end
end


