% Expected caller: ecg_print.ui.runApp and direct unit tests. Inputs are raw
% UI control values. Output is a struct accepted by labkit.biosignal.readRecording.
% Side effects: none.

function optsOut = importOptions(fallbackFs, headerLine, hasHeaderChoice, timeColumnText, timeUnitChoice, signalColumnsText)
%IMPORTOPTIONS Build ECG Print app-local readRecording options.

    optsOut = struct('fallbackFs', fallbackFs);
    if headerLine > 0
        optsOut.headerLine = round(headerLine);
    end

    switch string(hasHeaderChoice)
        case "Yes"
            optsOut.hasHeader = true;
        case "No"
            optsOut.hasHeader = false;
    end

    if strlength(strtrim(string(timeColumnText))) > 0
        optsOut.timeColumn = parseColumnSpec(timeColumnText);
    end
    if string(timeUnitChoice) ~= "Auto"
        optsOut.timeUnit = char(timeUnitChoice);
    end
    if strlength(strtrim(string(signalColumnsText))) > 0
        optsOut.signalColumns = parseColumnList(signalColumnsText);
    end
end

function value = parseColumnSpec(textValue)
    textValue = strtrim(string(textValue));
    numericValue = str2double(textValue);
    if isfinite(numericValue) && numericValue == floor(numericValue)
        value = numericValue;
    else
        value = char(textValue);
    end
end

function values = parseColumnList(textValue)
    parts = split(string(textValue), {',', ';'});
    parts = strtrim(parts);
    parts = parts(strlength(parts) > 0);
    numericValues = str2double(parts);
    if all(isfinite(numericValues)) && all(numericValues == floor(numericValues))
        values = numericValues(:).';
    else
        values = cellstr(parts);
    end
end
