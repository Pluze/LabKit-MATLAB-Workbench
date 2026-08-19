function digest = fileSha256(filepath, failureId, failureMessage)
%FILESHA256 Compute the lowercase SHA-256 digest of one file.
% The file is read in bounded chunks and hashed with repository-owned Base
% MATLAB code. No Java, shell command, Toolbox, or third-party runtime is used.

if nargin < 2
    failureId = "labkit:app:runtime:FileReadFailed";
end
if nargin < 3
    failureMessage = "Could not read file for SHA-256: %s.";
end
file = fopen(filepath, "rb");
if file < 0
    error(failureId, failureMessage, filepath);
end
cleanup = onCleanup(@() fclose(file));
state = initialState();
pending = zeros(0, 1, "uint8");
byteCount = uint64(0);
while true
    chunk = fread(file, 1024 * 1024, "*uint8");
    if isempty(chunk)
        break
    end
    byteCount = byteCount + uint64(numel(chunk));
    bytes = [pending; chunk];
    completeCount = floor(numel(bytes) / 64) * 64;
    state = processBlocks(state, bytes(1:completeCount));
    pending = bytes(completeCount + 1:end);
end
bitCount = byteCount * uint64(8);
paddingCount = mod(56 - mod(numel(pending) + 1, 64), 64);
lengthBytes = uint8(bitand( ...
    bitshift(bitCount, -8 * (7:-1:0)), uint64(255))).';
finalBytes = [pending; uint8(128); zeros(paddingCount, 1, "uint8"); lengthBytes];
state = processBlocks(state, finalBytes);
digest = stateHex(state);
delete(cleanup);
end

function state = initialState()
state = uint32(hex2dec([ ...
    "6A09E667"; "BB67AE85"; "3C6EF372"; "A54FF53A"; ...
    "510E527F"; "9B05688C"; "1F83D9AB"; "5BE0CD19"]));
end

function state = processBlocks(state, bytes)
constants = roundConstants();
for offset = 1:64:numel(bytes)
    block = bytes(offset:offset + 63);
    words = zeros(64, 1, "uint32");
    for index = 1:16
        first = (index - 1) * 4 + 1;
        words(index) = bitor( ...
            bitor(bitshift(uint32(block(first)), 24), ...
                bitshift(uint32(block(first + 1)), 16)), ...
            bitor(bitshift(uint32(block(first + 2)), 8), ...
                uint32(block(first + 3))));
    end
    for index = 17:64
        low = bitxor(bitxor(rotateRight(words(index - 15), 7), ...
            rotateRight(words(index - 15), 18)), ...
            bitshift(words(index - 15), -3));
        high = bitxor(bitxor(rotateRight(words(index - 2), 17), ...
            rotateRight(words(index - 2), 19)), ...
            bitshift(words(index - 2), -10));
        words(index) = add32(words(index - 16), low, ...
            words(index - 7), high);
    end
    working = state;
    for index = 1:64
        sigma1 = bitxor(bitxor(rotateRight(working(5), 6), ...
            rotateRight(working(5), 11)), rotateRight(working(5), 25));
        choice = bitxor(bitand(working(5), working(6)), ...
            bitand(bitcmp(working(5)), working(7)));
        temporary1 = add32(working(8), sigma1, choice, ...
            constants(index), words(index));
        sigma0 = bitxor(bitxor(rotateRight(working(1), 2), ...
            rotateRight(working(1), 13)), rotateRight(working(1), 22));
        majority = bitxor(bitxor(bitand(working(1), working(2)), ...
            bitand(working(1), working(3))), ...
            bitand(working(2), working(3)));
        temporary2 = add32(sigma0, majority);
        working = [ ...
            add32(temporary1, temporary2); working(1); working(2); working(3); ...
            add32(working(4), temporary1); working(5); working(6); working(7)];
    end
    for index = 1:8
        state(index) = add32(state(index), working(index));
    end
end
end

function value = rotateRight(value, count)
value = bitor(bitshift(value, -count), bitshift(value, 32 - count));
end

function value = add32(varargin)
total = uint64(0);
for index = 1:nargin
    total = total + uint64(varargin{index});
end
value = uint32(bitand(total, uint64(4294967295)));
end

function constants = roundConstants()
constants = uint32(hex2dec([ ...
    "428A2F98"; "71374491"; "B5C0FBCF"; "E9B5DBA5"; "3956C25B"; "59F111F1"; "923F82A4"; "AB1C5ED5"; ...
    "D807AA98"; "12835B01"; "243185BE"; "550C7DC3"; "72BE5D74"; "80DEB1FE"; "9BDC06A7"; "C19BF174"; ...
    "E49B69C1"; "EFBE4786"; "0FC19DC6"; "240CA1CC"; "2DE92C6F"; "4A7484AA"; "5CB0A9DC"; "76F988DA"; ...
    "983E5152"; "A831C66D"; "B00327C8"; "BF597FC7"; "C6E00BF3"; "D5A79147"; "06CA6351"; "14292967"; ...
    "27B70A85"; "2E1B2138"; "4D2C6DFC"; "53380D13"; "650A7354"; "766A0ABB"; "81C2C92E"; "92722C85"; ...
    "A2BFE8A1"; "A81A664B"; "C24B8B70"; "C76C51A3"; "D192E819"; "D6990624"; "F40E3585"; "106AA070"; ...
    "19A4C116"; "1E376C08"; "2748774C"; "34B0BCB5"; "391C0CB3"; "4ED8AA4A"; "5B9CCA4F"; "682E6FF3"; ...
    "748F82EE"; "78A5636F"; "84C87814"; "8CC70208"; "90BEFFFA"; "A4506CEB"; "BEF9A3F7"; "C67178F2"]));
end

function value = stateHex(state)
bytes = zeros(32, 1, "uint8");
for index = 1:8
    target = (index - 1) * 4 + (1:4);
    bytes(target) = uint8(bitand( ...
        bitshift(state(index), -8 * (3:-1:0)), uint32(255)));
end
value = lower(string(reshape(dec2hex(bytes, 2).', 1, [])));
end
