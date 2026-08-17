function text = mark10ResponseText(raw)
% Normalize Mark-10 response text without interpreting its protocol role.
if isempty(raw)
    text = "";
elseif ischar(raw)
    text = string(raw);
elseif isstring(raw) && isscalar(raw)
    text = raw;
elseif isnumeric(raw)
    text = string(native2unicode(uint8(raw(:).'), "UTF-8"));
else
    error("labkit:mark10:InvalidValue", ...
        "Mark-10 response must be text or bytes.");
end
end
