function connection = mark10EnsureForceConvention(connection)
% Enforce and verify the LabKit convention: tension positive, compression negative.
[connection, settings] = labkit.mark10.readSettings(connection);
if settings.InvertPolarity
    return;
end
[connection, settings, result] = labkit.mark10.writeSetting( ...
    connection, "invertPolarity", true);
if ~result.Success || ~settings.InvertPolarity
    error("labkit:mark10:ConnectionFailed", ...
        ["Could not verify the required Series 5 output polarity " ...
         "(tension positive, compression negative; IPOL1)."]);
end
end
