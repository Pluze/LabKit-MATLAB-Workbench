function applicationState = editWindow(applicationState, event, context)
%EDITWINDOW Validate the proposed cell while preserving independent windows.
a=applicationState.session.analysis;
r=event.RowIndex; c=event.ColumnIndex; value=event.NewValue;
if r>size(a.windows,1) || c>4, return; end
if c==1
    valid=islogical(value)&&isscalar(value);
elseif c==2
    valid=(ischar(value)||(isstring(value)&&isscalar(value))) && strlength(string(value))>0;
else
    valid=isnumeric(value)&&isscalar(value)&&isreal(value)&&isfinite(value);
end
if ~valid
    error("mark10_monitor:analysis:InvalidWindow", ...
        "Enter a valid enabled flag, name or finite strain bound.");
end
candidate=a.windows; candidate{r,c}=value;
if candidate{r,3}>=candidate{r,4}
    error("mark10_monitor:analysis:InvalidWindow", "Window start must be less than its end.");
end
a.windows=candidate; applicationState.session.analysis=a;
applicationState=mark10_monitor.analysis.invalidateWindows(applicationState,context,[]);
end
