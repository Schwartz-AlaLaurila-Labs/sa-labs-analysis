function plotPSTH(epochData, parameter, axes)

% description : PSTH plot
% xAxis:
%   default : duration
%   description: Protocol properties can be visualized for above deafault properties
% yAxis:
%   default: "@(epochData) keys(epochData.parentCell.getEpochValuesMap('displayName'))"
%   description: List of protocol name
% ---

import sa_labs.analysis.*;
util.clearAxes(axes);

epochs = epochData.parentCell.epochs;
selectedEpochsIdx = arrayfun(@(epoch) strcmp(epoch.get('displayName'), parameter.yAxis), epochs);
selectedEpochs = epochs(selectedEpochsIdx);

devices = parameter.devices;
axesArray = util.getNewAxesForSublot(axes, numel(devices));
n = numel(devices);
colors = get(groot,'DefaultAxesColorOrder');

for i = 1 : n
    device = devices{i};
    spikeCounts = getBinnedResponses(selectedEpochs, 1/60, device);
    psth = mean(spikeCounts);
    psth = filter2(ones(1, 3)/3, [psth(1), psth, psth(end)], 'valid');
    mu = psth*60;
    sem = std(spikeCounts*60) ./ sqrt(size(spikeCounts, 1));
    time = 1/120:1/60:(size(spikeCounts, 2)/60);
    
    axes = axesArray(i);
    subplot(n, 1, i, axes);
    xFill = [time, flip(time)];
    yFill = [mu-sem, flip(mu+sem)];
    hold(axes, 'on')
    fill(axes, xFill, yFill, colors(i, :), 'FaceAlpha', 0.5, 'EdgeColor', 'none')
    plot(axes, time, mu, 'Color', colors(i, :), 'LineWidth', 2)
    set(axes, 'XLim', [0, size(spikeCounts, 2)/60], 'YLim', [0, 300]);
    ylabel(axes, device);
end
xlabel(axes, parameter.xAxis)
title(axesArray(1), ['PSTH plot for protocol (' parameter.yAxis ')']);
hold(axes, 'off');
end

function responses = getBinnedResponses(epochs, binWidth, device)
  
  preTime = epochs(1).get('preTime')/1e3;
  stimTime = epochs(1).get('stimTime')/1e3;
  tailTime = epochs(1).get('tailTime')/1e3;
  binEdges = 0:binWidth:(preTime+stimTime+tailTime);
  responses = cell2mat(arrayfun(@(e) histcounts(e.getDerivedResponse('spikeTimes', device)/1e4, binEdges), epochs, 'UniformOutput', false)');
end