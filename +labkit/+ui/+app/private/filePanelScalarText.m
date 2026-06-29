% Private filePanel helper. Expected caller: buildFilePanelControl. Inputs
% are file-entry text values that may be empty, scalar, or non-scalar. Output
% is a scalar string fallback or the first supplied text value.
function value = filePanelScalarText(rawValue, fallback)
    value = string(rawValue);
    if isempty(value)
        value = string(fallback);
        return;
    end
    value = value(1);
end
