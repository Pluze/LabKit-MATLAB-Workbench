function slug = labKitChangeComponentSlug(value)
%LABKITCHANGECOMPONENTSLUG Return the generated archive slug for a component.
slug = lower(regexprep(labKitChangeComponentId(value), '[^A-Za-z0-9]+', '-'));
slug = strip(slug, "-");
end
