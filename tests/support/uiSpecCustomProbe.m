function handle = uiSpecCustomProbe(parent, id, context, props)
%UISPECCUSTOMPROBE Test-only custom UI 2.0 builder.
%
% Expected caller: UI 2.0 spec tests. Inputs mirror custom builder contract:
% parent container, semantic id, context struct, and props struct. Output is a
% simple label handle registered by labkit.ui.app.create.

    labelText = sprintf('%s:%s:%d', id, class(context), numel(fieldnames(props)));
    handle = uilabel(parent, 'Text', labelText);
end
