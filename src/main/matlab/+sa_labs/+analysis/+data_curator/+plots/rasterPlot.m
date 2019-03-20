function rasterPlot(epochData, parameter, axes)

% description : Raster plot
% xAxis:
%   default : duration
%   description: Protocol properties can be visualized for above deafault properties
% yAxis:
%   default: "@(epochData) sa_labs.analysis.data_curator.plots.params.getRasterYAxis(epochData)"
%   description: List of protocol name
% ---

import sa_labs.analysis.*;
util.clearAxes(axes);

epochs = epochData.parentCell.epochs;
if ~ strcmpi(parameter.yAxis, 'Filtered epochs')
    selectedEpochsIdx = arrayfun(@(epoch) strcmp(epoch.get('displayName'), parameter.yAxis), epochs);
else
    selectedEpochsIdx = [epochs.filtered];
end

if isempty(selectedEpochsIdx) || any(selectedEpochsIdx) == 0
    error('No epochs found, Execute filter and try again')
end

selectedEpochs = epochs(selectedEpochsIdx);
epochNumbers = epochData.parentCell.getEpochValues('epochNum', selectedEpochsIdx);

devices = parameter.devices;
axesArray = util.getNewAxesForSublot(axes, numel(devices));
n = numel(devices);

for i = 1 : n
    device = devices{i};
    rasters = getBinnedResponses(selectedEpochs, 2e-3, device);
    
    axes = axesArray(i);
    subplot(n, 1, i, axes);
    pcolor(axes, (rasters'>0)');
    shading(axes, 'flat')
    cMap = 1 - colormap(axes, 'gray');
    colormap(axes, cMap)
    set(axes, 'Layer', 'top')
    set(axes, 'XTick', [], 'YTick', 1:numel(epochNumbers), 'YTickLabels', epochNumbers)
    set(axes, 'XLim', [1, size(rasters, 2)],'YLim', [1, size(rasters, 1)]);
    ylabel(axes, [device ' (epochNum)']);
end
xlabel(axes, parameter.xAxis)
title(axesArray(1), ['Raster plot for protocol (' parameter.yAxis ')']);
hold(axes, 'off');
end

function responses = getBinnedResponses(epochs, binWidth, device)
  
  preTime = epochs(1).get('preTime')/1e3;
  stimTime = epochs(1).get('stimTime')/1e3;
  tailTime = epochs(1).get('tailTime')/1e3;
  binEdges = 0:binWidth:(preTime+stimTime+tailTime);
  responses = cell2mat(arrayfun(@(e) histcounts(e.getDerivedResponse('spikeTimes', device)/1e4, binEdges), epochs, 'UniformOutput', false)');
end