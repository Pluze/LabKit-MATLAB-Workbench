function out = sanitizeFieldName(txt)
%SANITIZEFIELDNAME Convert text to a valid MATLAB table field name.

    out = matlab.lang.makeValidName(txt);
end
