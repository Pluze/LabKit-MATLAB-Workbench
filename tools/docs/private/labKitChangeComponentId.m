function id = labKitChangeComponentId(value)
%LABKITCHANGECOMPONENTID Extract a stable component identifier from metadata.
id = strip(extractBefore(string(value) + " |", " |"));
end
