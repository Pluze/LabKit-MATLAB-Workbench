function styleControlSurface(control, style, containerColor)
% Called as each control node is built, before child semantic nodes exist.
% Scientific workspaces and plot nodes never enter this construction path.
if nargin < 3
    containerColor = style.Surface;
end
switch control.Type
    case 'uipanel'
        if any(string(control.Tag) == ["labkitDividerRule","labkitDividerGrip"])
            return
        end
        if strcmp(control.Tag, "labkitAppRowResize")
            control.BackgroundColor = containerColor;
            return
        end
        control.BorderType = "none";
        control.BackgroundColor = containerColor;
        control.ForegroundColor = style.Text;
        control.FontWeight = "bold";
    case {'uigridlayout','uitab'}
        control.BackgroundColor = containerColor;
    case 'uibutton'
        control.FontSize = 12;
        control.BackgroundColor = style.Paper;
        control.FontColor = style.Text;
    case 'uilabel'
        if endsWith(string(control.Tag), ".label")
            control.HorizontalAlignment = "left";
            grid = control.Parent;
            if numel(grid.ColumnWidth) == 2 && isnumeric(grid.ColumnWidth{1}) && strlength(string(control.Text)) > 0
                width = 112;
                if isprop(grid.Parent, "ColumnWidth") && numel(grid.Parent.ColumnWidth) > 1
                    width = min(width, max(44, 8 * strlength(string(control.Text))));
                end
                grid.ColumnWidth{1} = width;
                grid.UserData.FormLabelWidth = width;
            end
        end
        control.FontColor = style.Text;
    case {'uicheckbox','uislider'}
        control.FontColor = style.Text;
    case {'uitextarea','uieditfield','uinumericeditfield','uispinner', ...
            'uidropdown','uilistbox'}
        policy = labkit.app.internal.native.NativeAdapterValues.layoutPolicy();
        control.FontSize = policy.ReadonlyFontSize;
        control.BackgroundColor = style.Surface;
        control.FontColor = style.Text;
    otherwise
        % Tables and other result displays keep their native presentation.
        return
end
if any(strcmp(control.Type, {'uipanel','uitab','uigridlayout'}))
    for child = reshape(control.Children, 1, [])
        labkit.app.internal.native.styleControlSurface(child, style, containerColor);
    end
end
end
