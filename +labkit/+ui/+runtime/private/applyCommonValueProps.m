% Private UI runtime helper. Expected caller: declarative control builders. Inputs are
% a MATLAB UI handle and validated spec props. Output is none. Side effects
% assign common value, limit, item, and display-format properties when the
% target handle supports them.
function applyCommonValueProps(control, props)
    if isfield(props, 'items') && isprop(control, 'Items')
        control.Items = cellstr(string(props.items));
    end
    if isfield(props, 'limits') && isprop(control, 'Limits')
        control.Limits = props.limits;
    end
    if isfield(props, 'step') && isprop(control, 'Step')
        control.Step = props.step;
    end
    if isfield(props, 'valueDisplayFormat') && isprop(control, 'ValueDisplayFormat')
        control.ValueDisplayFormat = props.valueDisplayFormat;
    end
    if isfield(props, 'value') && isprop(control, 'Value')
        control.Value = props.value;
    end
    if isfield(props, 'value') && isprop(control, 'Text') && ~isprop(control, 'Value')
        control.Text = char(string(props.value));
        applyTextFit(control);
    end
end
