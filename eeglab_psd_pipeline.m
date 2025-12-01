function eeglab_psd_pipeline(infile, outfile, tmin_sec, tmax_sec)
% EEG lab PSD pipeline for container use.
% infile:  path to .set file
% outfile: path to CSV output
% tmin_sec, tmax_sec: crop window in seconds (numeric or numeric strings)

    % Be tolerant to string inputs (from CLI)
    if ischar(tmin_sec) || isstring(tmin_sec)
        tmin_sec = str2double(tmin_sec);
    end
    if ischar(tmax_sec) || isstring(tmax_sec)
        tmax_sec = str2double(tmax_sec);
    end

    % Start EEGLAB in nogui mode
    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab('nogui'); %#ok<ASGLU,NASGU>

    % Load dataset
    EEG = pop_loadset('filename', infile);
    EEG = eeg_checkset(EEG);

    % Crop to time window
    EEG = pop_select(EEG, 'time', [tmin_sec tmax_sec]);
    EEG = eeg_checkset(EEG);

    % Compute PSD using spectopo (no plotting)
    % spectopo returns power in dB; data is chans x freqs
    [spectra_db, freqs] = spectopo(EEG.data, 0, EEG.srate, 'plot', 'off');

    % Convert dB -> linear power
    psd_lin = 10.^(spectra_db / 10);

    % Define bands
    bands(1).name  = 'delta'; bands(1).range = [1 4];
    bands(2).name  = 'theta'; bands(2).range = [4 8];
    bands(3).name  = 'alpha'; bands(3).range = [8 13];
    bands(4).name  = 'beta';  bands(4).range = [13 30];
    bands(5).name  = 'gamma'; bands(5).range = [30 45];

    nbchan = EEG.nbchan;
    nbands = numel(bands);

    band_power_abs = zeros(nbchan, nbands);
    band_power_rel = zeros(nbchan, nbands);

    % Integrate power over frequency (per channel, per band)
    for b = 1:nbands
        f_idx = freqs >= bands(b).range(1) & freqs < bands(b).range(2);
        if ~any(f_idx)
            continue;
        end
        band_power_abs(:, b) = trapz(freqs(f_idx), psd_lin(:, f_idx), 2);
    end

    % Total power across all frequencies for relative power
    total_power = trapz(freqs, psd_lin, 2);   % chans x 1

    % Avoid divide-by-zero
    total_power(total_power == 0) = NaN;
    band_power_rel = band_power_abs ./ total_power;

    % Channel labels (fallback to numeric indices if missing)
    if isfield(EEG, 'chanlocs') && ~isempty(EEG.chanlocs)
        chan_labels = {EEG.chanlocs.labels}';
        empty_mask = cellfun(@isempty, chan_labels);
        chan_labels(empty_mask) = ...
            arrayfun(@(i) sprintf('Chan%d', i), find(empty_mask), ...
                     'UniformOutput', false);
    else
        chan_labels = arrayfun(@(i) sprintf('Chan%d', i), 1:nbchan, ...
                               'UniformOutput', false).';
    end

    % Build output table
    band_names = {bands.name};

    T_abs = array2table(band_power_abs, ...
        'VariableNames', strcat('abs_', band_names), ...
        'RowNames', chan_labels);

    T_rel = array2table(band_power_rel, ...
        'VariableNames', strcat('rel_', band_names), ...
        'RowNames', chan_labels);

    T = [T_abs T_rel];

    % Write to CSV; row names go into first column
    writetable(T, outfile, 'WriteRowNames', true);
end
