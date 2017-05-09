function addSpikesToEpoch(cellData, varargin)

    ip = inputParser;
    ip.addParameter('devices', {'Amp1'}, @iscell);
    ip.parse(varargin{:});
    devices = ip.Results.devices;

    import sa_labs.analysis.*;
    description = entity.FeatureDescription(containers.Map('id', 'SPIKES'));

    for epoch = cellData.epochs
        for i = 1 : numel(devices)
            device = devices{i};
            try
                data = epoch.getResponse(device).quantity;
                spikeTime =  mht.spike_util.detectSpikes(data);
                epoch.attributes('SPIKES') = entity.Feature(description, spikeTime);
            catch
                logging.getLogger('')
            end
        end
    end
end


