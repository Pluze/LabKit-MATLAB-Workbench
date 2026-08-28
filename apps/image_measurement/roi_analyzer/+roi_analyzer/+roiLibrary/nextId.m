function id = nextId(values, prefix)
%NEXTID Return the first unused bounded semantic identity.
existing = string(values);
index = 1;
id = string(prefix) + index;
while any(existing == id)
    index = index + 1;
    id = string(prefix) + index;
end
end
