function eeglab_psd_cli(varargin)
% CLI wrapper for container entrypoint.
% Usage:
%   eeglab_psd_cli input.set output.csv tmin_sec tmax_sec

    addpath eeglab;

    if numel(varargin) ~= 4
        error(['Usage: eeglab_psd_cli <input.set> <output.csv> ' ...
               '<tmin_sec> <tmax_sec>']);
    end

    infile   = varargin{1};
    outfile  = varargin{2};
    tmin_sec = varargin{3};
    tmax_sec = varargin{4};

    eeglab_psd_pipeline(infile, outfile, tmin_sec, tmax_sec);
end
