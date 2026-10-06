function text = plotTitle(label, filename)
%PLOTTITLE Compose an App-owned plot heading with the active recording name.
text = string(label);
if strlength(filename) > 0
    text = text + " — " + filename;
end
end
