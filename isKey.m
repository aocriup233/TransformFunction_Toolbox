function tf = isKey(mapObj, keySpec)
%ISKEY 检查键是否存在于 Map 容器中
%   TF = ISKEY(mapObj, key) 检查单个键是否存在，返回逻辑标量
%   TF = ISKEY(mapObj, keys) 检查多个键，返回逻辑数组
%
%   输入参数：
%     mapObj  - containers.Map 对象
%     keySpec - 单个键或键的单元数组/字符串数组
%
%   输出参数：
%     tf      - 逻辑值或逻辑数组，表示键是否存在

    % 输入验证
    if ~isa(mapObj, 'containers.Map')
        error('第一个输入必须是 containers.Map 对象');
    end
    
    % 处理单个键的情况
    if ischar(keySpec) || isstring(keySpec) || isnumeric(keySpec)
        % 检查单个键
        try
            % 尝试访问该键，如果成功则键存在
            value = mapObj(keySpec);
            tf = true;
        catch ME
            if strcmp(ME.identifier, 'MATLAB:containers:Map:NoKey')
                tf = false;
            else
                rethrow(ME);
            end
        end
        
    % 处理多个键的情况（单元数组或字符串数组）
    elseif iscell(keySpec) || (isstring(keySpec) && numel(keySpec) > 1)
        numKeys = numel(keySpec);
        tf = false(1, numKeys);  % 预分配逻辑数组
        
        for i = 1:numKeys
            try
                value = mapObj(keySpec{i});
                tf(i) = true;
            catch ME
                if strcmp(ME.identifier, 'MATLAB:containers:Map:NoKey')
                    tf(i) = false;
                else
                    rethrow(ME);
                end
            end
        end
        
        % 保持与输入相同的形状
        tf = reshape(tf, size(keySpec));
        
    else
        error('不支持的键类型');
    end
end