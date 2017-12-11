function yAxisList = getYaxisForEpochGroupParameterPlot(epochGroup)
% Returns list of y axis which as number of elements same as number of epochs

numberOfEpochs = numel(epochGroup.attributes('epochNum'));
valueList = epochGroup.attributes.values;
indices = cellfun(@(v) numel(v) == numberOfEpochs, valueList);
keySet = epochGroup.attributes.keys;
yAxisList = keySet(indices);
end

