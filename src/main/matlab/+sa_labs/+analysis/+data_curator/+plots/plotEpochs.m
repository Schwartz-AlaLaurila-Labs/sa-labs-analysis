function plotEpochs(epochs, parameter, axes)

% description : It plots signal from various amplifier device over stimulus duration. Below 'YAML' describes the fields present in the parameter structure.
% xAxis:
%   default : Duration
%   description: Stimulus duration (preTime + stimTime + tailTime)
% yAxis:
%   default: response, filteredResponse
%   description: Can alternate between response and filtered response. However, filtered response is an inmemmory attribute. So one needs to run the simple spike detector again in Advanced mode in order to plot the filtered response
% devices:
%   default: Amp1
%   description: It is the value selected from the device pannel in curator interface
% ---

import sa_labs.analysis.*;
util.clearAxes(axes);
devices = parameter.devices;
yAxis = parameter.yAxis;
axesArray = util.getNewAxesForSublot(axes, numel(devices));

for epochData = epochs
    n = numel(devices);

    for i = 1 : n
        device = devices{i};
        % Get data based upon yAxis
        [data, units] = getData(epochData, device, yAxis);
        
        axes = axesArray(i);
        subplot(n, 1, i, axes);
        
        description = epochData.toStructure();
        description.device = device;
        description.units = units;
        spikeTimes = epochData.getDerivedResponse('spikeTimes', device);
        
        if ~ isempty(spikeTimes)
            plots.plotSpikes(spikeTimes, data, description, axes);
        else
            plots.plotEpoch(data, description, axes);
        end
        xlabel(axes, '');
        title(axes, '');
    end
    xlabel(axes, 'Time (seconds)');
    title(axesArray(1), ['Epoch number (' num2str(description.epochNum) ')']);
end
end

function [response, units] = getData(epochData, device, yAxis)

structure = epochData.getResponse(device);
units = deblank(structure.units(:,1)');

if ~ strcmpi(yAxis, 'filteredResponse')
    response = structure.quantity';
    return;
end

response = epochData.getDerivedResponse('filteredResponse', device);
if isempty(response)
    error('filteredResponse is an inmemory attribute. Run simpleSpikeDetector in mode ''Advanced'' to visualize')
end
end
