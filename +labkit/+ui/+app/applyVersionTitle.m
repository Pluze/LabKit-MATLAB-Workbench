function titleText = applyVersionTitle(fig, info)
%APPLYVERSIONTITLE Apply app version metadata to a figure title.
%
% App-facing contract:
%   titleText = labkit.ui.app.applyVersionTitle(fig, info)
%
% Inputs:
%   fig - scalar app figure handle with a Name property.
%   info - app version struct with version and updated scalar text fields.
%
% Outputs:
%   titleText - title written to fig.Name.

    if isempty(fig) || ~isscalar(fig) || ~isvalid(fig) || ~isprop(fig, 'Name')
        error('labkit:ui:app:InvalidFigure', ...
            'Version title can only be applied to a valid scalar figure.');
    end
    titleText = labkit.ui.app.appVersionTitle(string(fig.Name), info);
    fig.Name = char(titleText);
end
