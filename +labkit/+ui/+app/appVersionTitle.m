function titleText = appVersionTitle(baseTitle, info)
%APPVERSIONTITLE Format an app figure title with version metadata.
%
% App-facing contract:
%   titleText = labkit.ui.app.appVersionTitle(baseTitle, info)
%
% Inputs:
%   baseTitle - scalar text already used as the figure title.
%   info - app version struct with version and updated scalar text fields.
%
% Outputs:
%   titleText - string in the form "<baseTitle> v<version> (<updated>)".

    baseTitle = normalizeTitle(baseTitle, info);
    version = textField(info, 'version');
    updated = textField(info, 'updated');
    titleText = baseTitle + " v" + version + " (" + updated + ")";
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
        error('labkit:ui:app:InvalidVersionInfo', ...
            'App version title requires a base title, displayName, or name.');
    end
end

function text = textField(info, fieldName)
    if ~isstruct(info) || ~isscalar(info) || ~isfield(info, fieldName)
        error('labkit:ui:app:InvalidVersionInfo', ...
            'App version info must include scalar text field "%s".', fieldName);
    end
    value = info.(fieldName);
    if ~(ischar(value) || (isstring(value) && isscalar(value)))
        error('labkit:ui:app:InvalidVersionInfo', ...
            'App version info field "%s" must be scalar text.', fieldName);
    end
    text = strtrim(string(value));
    if strlength(text) == 0
        error('labkit:ui:app:InvalidVersionInfo', ...
            'App version info field "%s" cannot be empty.', fieldName);
    end
end
