function outcome = mark10ResponseOutcome(raw)
% Classify an empty, GCL2 error, or ordinary response without guessing intent.
if isempty(raw)
    outcome = "NO_RESPONSE";
elseif startsWith(strip(mark10ResponseText(raw)), "*")
    outcome = "ERROR_RESPONSE";
else
    outcome = "RESPONSE";
end
end
