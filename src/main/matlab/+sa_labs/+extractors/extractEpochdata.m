function extractEpochdata(analysis, group, varargin)

device = analysis.getDeviceForGroup(group);

epochs = analysis.getEpochs(group);
n = numel(epochs);
epochdata = cell(0, n);
for i = 1 : n  
    epochdata{i} = epochs(i).getDerivedResponse(device, 'EPOCH');
end
group.createFeature('EPOCH', epochdata, 'device', device);
end


