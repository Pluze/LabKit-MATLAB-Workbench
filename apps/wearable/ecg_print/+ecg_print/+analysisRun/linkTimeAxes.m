function linkTimeAxes(axes, enabled)
%LINKTIMEAXES Keep the fixed plot group's time linkage across redraws.
% linkaxes flushes graphics even when unlinking; change it only when the
% displayed workflow switches between independent and shared time domains.
key = "ecgPrintTimeAxesLinked";
linked = isappdata(axes(1), key) && getappdata(axes(1), key);
if linked == enabled, return; end
mode = 'off';
if enabled, mode = 'x'; end
linkaxes(axes, mode);
setappdata(axes(1), key, enabled);
end
