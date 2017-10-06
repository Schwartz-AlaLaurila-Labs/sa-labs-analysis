function addSpikesToEpoch(cellData, varargin)

ip = inputParser;
ip.addParameter('devices', {'Amp1'}, @iscellstr);
ip.addParameter('checkDetection', false, @islogical);


ip.parse(varargin{:});
devices = ip.Results.devices;
checkDetection = ip.Results.checkDetection;

for epoch = cellData.epochs
    for device = each(devices)
        try
            data = epoch.getResponse(device).quantity;
            spikeTime =  mht.spike_util.detectSpikes(data, 'checkDetection', checkDetection);
            epoch.addDerivedResponse('SPIKES', spikeTime, device);
            
            label = epoch.get('recordingLabel');
            number = epoch.get('epochNum');
            if checkDetection
                disp(['cell:',label{1},' epoch:', num2str(number),' ', device]);
            end
            close(gcf);
        catch e
            disp(e.message);
        end
    end
end

