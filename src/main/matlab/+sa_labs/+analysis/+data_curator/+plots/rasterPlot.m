function rasterPlot(epochData, parameter, axes)

% description : Raster plot
% xAxis:
%   default : "@(epochData) keys(epochData.parentCell.getEpochValuesMap('displayName'))"
%   description: List of protocol name
% yAxis:
%   default: "@(epochData) setdiff(epochData.parentCell.getEpochKeysetUnion(), {'epochNum', 'epochStartTime'})"
%   description: Group by selected parameters
% ---

import sa_labs.analysis.*;
util.clearAxes(axes);

epochs = epochData.parentCell.epochs;
values = epochData.parentCell.getEpochValues(parameter.yAxis);
[sortedValues, idx] = sort(values);
selectedEpochsIdx = find(arrayfun(@(epoch) strcmp(epoch.get('displayName'), parameter.xAxis), epochs));
validIdx = intersect(idx, selectedEpochsIdx, 'stable');

if numel(validIdx) ~= numel(selectedEpochsIdx)
    error('Invalid yAxis parameter')
end

selectedEpochs = epochs(validIdx);
epochNumbers = epochData.parentCell.getEpochValues('epochNum', validIdx);
devices = parameter.devices;
axesArray = util.getNewAxesForSublot(axes, numel(devices));
n = numel(devices);

groupByIdx = [1 find(diff(sortedValues(epochNumbers))) + 1];

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
    set(axes, 'XTick', [])
    yticks = get(axes, 'YTick');
    set(axes, 'XTick', [], 'YTick', 1:numel(epochNumbers), 'YTickLabels', epochNumbers)
    for divider = groupByIdx
        h = refline(axes, 0, divider);
        h.DisplayName = [ parameter.yAxis ' = ' num2str(epochNumbers(divider))];
        legend(axes);
    end
end
xlabel(axes, parameter.xAxis)
title(axesArray(1), ['Raster plot for protocol (' parameter.xAxis ') group by (' parameter.yAxis  ')']);
hold(axes, 'off');
end

function responses = getBinnedResponses(epochs, binWidth, device)
  
  preTime = epochs(1).get('preTime')/1e3;
  stimTime = epochs(1).get('stimTime')/1e3;
  tailTime = epochs(1).get('tailTime')/1e3;
  binEdges = 0:binWidth:(preTime+stimTime+tailTime);
  responses = cell2mat(arrayfun(@(e) histcounts(e.getDerivedResponse('spikeTimes', device)/1e4, binEdges), epochs, 'UniformOutput', false)');
end