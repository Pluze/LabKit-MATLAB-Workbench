function fs = inferSampleRate(timeSec)
%INFERSAMPLERATE Estimate sampling frequency from a time vector.

    fs = NaN;
    if numel(timeSec) < 2
        return;
    end
    dt = diff(double(timeSec(:)));
    dt = dt(isfinite(dt) & dt > 0);
    if isempty(dt)
        return;
    end
    fs = 1 / median(dt);
end
