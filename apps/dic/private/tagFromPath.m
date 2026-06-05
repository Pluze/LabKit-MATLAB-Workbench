% App-owned DIC helper extracted from labkit_DICPostprocess_app.m. Expected caller: DIC app entrypoints.
% Inputs, outputs, and side effects match the original local helper implementation.
function tag = tagFromPath(filepath)
    tokens = regexp(filepath, '(\d+(?:\.\d+)?mm)', 'tokens');
    if isempty(tokens)
        tag = 'unknown_mm';
    else
        tag = tokens{end}{1};
    end
    tag = regexprep(tag, '[^A-Za-z0-9_.-]', '_');
end
