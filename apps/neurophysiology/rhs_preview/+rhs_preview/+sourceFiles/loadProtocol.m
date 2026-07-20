% Expected caller: RHS Preview direct callbacks. Input is an optional protocol JSON path.
% Output is the decoded protocol struct or an empty struct. No UI handles are
% touched.
function protocol = loadProtocol(protocolFile)
%LOADPROTOCOL Load a lightweight RHS protocol JSON.

    protocol = struct();
    protocolFile = string(protocolFile);
    if strlength(protocolFile) == 0 || exist(char(protocolFile), "file") ~= 2
        return;
    end
    protocol = jsondecode(fileread(char(protocolFile)));
end
