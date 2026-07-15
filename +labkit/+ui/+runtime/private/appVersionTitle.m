% Private UI runtime helper. Formats an app title with version metadata.
function titleText = appVersionTitle(baseTitle, info)
%
% App-facing contract:
%   titleText = labkit.ui.runtime.appVersionTitle(baseTitle, info)
%
% Inputs:
%   baseTitle - scalar text already used as the figure title.
%   info - app version struct with version and updated scalar text fields.
%
% Outputs:
%   titleText - string in the form "<baseTitle> v<version> (<updated>)".

    version = textField(info, 'version');
    updated = textField(info, 'updated');
    suffix = " v" + version + " (" + updated + ")";
    baseTitle = stripVersionSuffix(normalizeTitle(baseTitle, info), suffix);
    titleText = baseTitle + suffix;
end

function baseTitle = stripVersionSuffix(baseTitle, suffix)
    if endsWith(baseTitle, suffix)
        suffixStart = strlength(baseTitle) - strlength(suffix) + 1;
        if suffixStart > 1
            baseTitle = strtrim(extractBefore(baseTitle, suffixStart));
        end
    end
end

function baseTitle = normalizeTitle(value, info)
    if nargin > 0 && (ischar(value) || (isstring(value) && isscalar(value)))
        baseTitle = strtrim(string(value));
    else
        baseTitle = "";
    end
    if strlength(baseTitle) == 0 && isstruct(info) && isfield(info, 'displayName')
        baseTitle = textField(info, 'displayName');
    end
    if strlength(baseTitle) == 0 && isstruct(info) && isfield(info, 'name')
        baseTitle = textField(info, 'name');
    end
    if strlength(baseTitle) == 0
        error('labkit:ui:runtime:InvalidVersionInfo', ...
            'App version title requires a base title, displayName, or name.');
    end
end

function text = textField(info, fieldName)
    if ~isstruct(info) || ~isscalar(info) || ~isfield(info, fieldName)
        error('labkit:ui:runtime:InvalidVersionInfo', ...
            'App version info must include scalar text field "%s".', fieldName);
    end
    value = info.(fieldName);
    if ~(ischar(value) || (isstring(value) && isscalar(value)))
        error('labkit:ui:runtime:InvalidVersionInfo', ...
            'App version info field "%s" must be scalar text.', fieldName);
    end
    text = strtrim(string(value));
    if strlength(text) == 0
        error('labkit:ui:runtime:InvalidVersionInfo', ...
            'App version info field "%s" cannot be empty.', fieldName);
    end
end
