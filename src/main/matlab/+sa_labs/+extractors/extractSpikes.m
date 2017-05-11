function extractSpikes(analysis, group, varargin)

device = analysis.getDeviceForGroup(group);

epochs = analysis.getEpochs(group);
n = numel(epochs);
spikes = cell(0, n);
for i = 1 : n  
    spikes{i} = epochs(i).getDerivedResponse(device, 'SPIKES');
end
group.createFeature('SPIKES', spikes, 'device', device);
end


