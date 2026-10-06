function text = escapeLabKitHtml(text)
%ESCAPELABKITHTML Escape text and attribute values for documentation renderers.
text = replace(string(text), "&", "&amp;");
text = replace(text, "<", "&lt;");
text = replace(text, ">", "&gt;");
text = replace(text, """", "&quot;");
end
