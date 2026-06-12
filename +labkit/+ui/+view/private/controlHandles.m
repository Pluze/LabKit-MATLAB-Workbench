% Private UI view helper. Expected caller: named labkit.ui.view helpers.
% Collects MATLAB graphics handles from a UI 2.0 control adapter so common
% state such as Enable can be applied across compound controls.
function handles = controlHandles(control)
    handles = {};
    handles = appendHandles(handles, control);
end

function handles = appendHandles(handles, value)
    if isempty(value)
        return;
    end
    if isgraphics(value)
        for k = 1:numel(value)
            if isvalid(value(k))
                handles{end+1} = value(k);
            end
        end
        return;
    end
    if iscell(value)
        for k = 1:numel(value)
            handles = appendHandles(handles, value{k});
        end
        return;
    end
    if isstruct(value)
        fields = fieldnames(value);
        for k = 1:numel(fields)
            field = fields{k};
            if ismember(field, {'props', 'event'})
                continue;
            end
            handles = appendHandles(handles, value.(field));
        end
    end
end
