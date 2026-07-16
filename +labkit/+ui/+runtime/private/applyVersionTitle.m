% Private UI runtime helper. Applies app version metadata to a figure title.
function titleText = applyVersionTitle(fig, info)
%
% Internal contract:
%   titleText = applyVersionTitle(fig, info)
%
% Inputs:
%   fig - scalar app figure handle with a Name property.
%   info - app version struct with version and updated scalar text fields.
%
% Outputs:
%   titleText - title written to fig.Name.

    if isempty(fig) || ~isscalar(fig) || ~isvalid(fig) || ~isprop(fig, 'Name')
        error('labkit:ui:runtime:InvalidFigure', ...
            'Version title can only be applied to a valid scalar figure.');
    end
    titleText = appVersionTitle(string(fig.Name), info);
    fig.Name = char(titleText);
    setappdata(fig, 'labkitUiAppVersion', info);
end
