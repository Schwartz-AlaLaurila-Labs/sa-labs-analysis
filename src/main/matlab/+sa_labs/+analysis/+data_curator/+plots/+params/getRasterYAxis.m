function yaxis = getRasterYAxis(epochData)
    yaxis = keys(epochData.parentCell.getEpochValuesMap('displayName'));
    yaxis = [yaxis, 'Filtered epochs'];
end

