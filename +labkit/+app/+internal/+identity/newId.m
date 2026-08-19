function value = newId()
%NEWID Create one opaque process-unique identifier using Base MATLAB.
[~, token] = fileparts(tempname);
value = string(token);
end
