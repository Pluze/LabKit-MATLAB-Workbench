% DIC Postprocess view helper. Expected caller: labkit_DICPostprocess_app.
% Input is a MAT filepath. Output is a safe export tag. Side effects: none.
function tag = tagFromPath(filepath)
    tokens = regexp(filepath, '(\d+(?:\.\d+)?mm)', 'tokens');
    if isempty(tokens)
        tag = 'unknown_mm';
    else
        tag = tokens{end}{1};
    end
    tag = regexprep(tag, '[^A-Za-z0-9_.-]', '_');
end
