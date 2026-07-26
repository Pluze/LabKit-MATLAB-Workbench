function height = preferredRowHeight(obj, node)
% Class-folder implementation of MatlabPlatformAdapter.preferredRowHeight.
    policy = labkit.app.internal.NativeAdapterValues.layoutPolicy();
    switch node.Kind
        case {"tab", "workspace", "workspacePage", "plotArea"}
            height = "1x";
        case "fileList"
            if node.Configuration.SelectionMode == "single" && ...
                    node.Configuration.MaxFiles == 1
                height = policy.CompactFileHeight;
            elseif ~node.Configuration.ShowStatus
                height = policy.FileListNoStatusHeight;
            else
                height = policy.FileListHeight;
            end
        case "dataTable"
            height = policy.TableHeight;
        case "statusPanel"
            if node.Id == "applicationUsage"
                height = policy.UsageHeight;
            else
                height = policy.StatusChromeHeight + ...
                    node.Configuration.Lines * policy.StatusLineHeight;
            end
        case "button"
            height = labkit.app.internal.NativeAdapterValues.estimatedControlHeight( ...
                node.Configuration.Label, 22, 2, ...
                policy.ButtonHeight);
        case "slider"
            height = policy.SliderHeight;
        case "field"
            if node.Configuration.Kind == "readonly"
                text = [string(node.Configuration.Label), ...
                    string(node.Configuration.Value)];
                height = labkit.app.internal.NativeAdapterValues.estimatedControlHeight( ...
                    text, 34, 3, policy.FieldHeight);
            elseif node.Configuration.Kind == "logical"
                height = labkit.app.internal.NativeAdapterValues.estimatedControlHeight( ...
                    node.Configuration.Label, 42, 2, ...
                    policy.FieldHeight);
            else
                height = labkit.app.internal.NativeAdapterValues.estimatedControlHeight( ...
                    node.Configuration.Label, 30, 2, ...
                    policy.FieldHeight);
            end
        case {"rangeField", "panner"}
            height = policy.FieldHeight;
        case {"section", "group"}
            children = obj.nodes(node.ChildIds);
            childHeights = zeros(1, numel(children));
            for k = 1:numel(children)
                candidate = obj.preferredRowHeight(children(k));
                if ischar(candidate) || isstring(candidate)
                    candidate = policy.FileListHeight;
                end
                childHeights(k) = candidate;
            end
            horizontal = node.Kind == "group" && ...
                isfield(node.Configuration, "Layout") && ...
                node.Configuration.Layout == "horizontal";
            if node.Kind == "section" && ...
                    ~obj.sectionDrawsOwnTitle(node) && ...
                    numel(children) == 1
                height = childHeights(1) + ...
                    policy.UntitledSectionChromeHeight;
            elseif obj.usesAdaptiveActionGrid(node)
                [rows, ~] = obj.actionGridSize(node);
                height = rows * policy.ButtonHeight + ...
                    max(0, rows - 1) * policy.ContentSpacing + ...
                    policy.GroupChromeHeight;
            elseif horizontal
                height = max(childHeights, [], "omitnan") + ...
                    policy.GroupChromeHeight;
            else
                height = sum(childHeights) + ...
                    max(0, numel(children) - 1) * ...
                    policy.ContentSpacing + ...
                    policy.SectionChromeHeight;
            end
        otherwise
            height = "fit";
    end
end
