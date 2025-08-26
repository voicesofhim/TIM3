-- Reset modules for fresh process state
-- This ensures clean initialization during deployment

if package and package.loaded then
    for k, v in pairs(package.loaded) do
        if type(k) == "string" and not k:match("^_") then
            package.loaded[k] = nil
        end
    end
end