% Expected caller: readHeader. Input is an open little-
% endian RHS file handle. Output is one Intan UTF-16 QString as a char row.
function value = readQString(fid)
    len = fread(fid, 1, "uint32=>uint32");
    if isempty(len)
        error("labkit:rhs:ShortHeader", "Unexpected end of RHS QString.");
    end
    if len == uint32(hex2dec("ffffffff"))
        value = "";
        return;
    end

    nBytes = double(len);
    if mod(nBytes, 2) ~= 0
        error("labkit:rhs:InvalidString", "RHS QString byte count is not even.");
    end
    raw = fread(fid, nBytes / 2, "uint16=>uint16");
    if numel(raw) ~= nBytes / 2
        error("labkit:rhs:ShortHeader", "Unexpected end of RHS QString data.");
    end
    value = char(raw(:).');
end
