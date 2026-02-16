function expr_out = parseParallel(expr_in)
%   Core Code : try to Parse Parallel Ex: 'ro1//ro2' => '((ro1*ro2)/(ro1+ro2))'
         
if isa(expr_in, 'sym')
    expr_str = char(expr_in);
else
    expr_str = strtrim(expr_in);
end
if ~contains(expr_str, '//')
    expr_out = expr_str;
    return;
end
expr_out = expand_all_parallel(expr_str);
end

function result = expand_all_parallel(expr)
max_iter = 100;
iter = 0; 
while iter < max_iter
    [pos, left, right] = find_innermost_parallel(expr);    
    if pos == 0
        result = expr;
        return;
    end
    expanded = sprintf('((%s)*(%s))/((%s)+(%s))', left, right, left, right);
    expr = [expr(1:pos-length(left)-1), expanded, expr(pos+length(right)+2:end)];    
    iter = iter + 1;
end
end

function [pos, left, right] = find_innermost_parallel(expr)
pos = 0; left = ''; right = '';
n = length(expr);
parallels = [];
depth = 0; 
for i = 1:n-1
    if expr(i) == '('
        depth = depth + 1;
    elseif expr(i) == ')'
        depth = depth - 1;
    elseif expr(i) == '/' && i < n && expr(i+1) == '/'
        parallels(end+1, :) = [i, depth];
    end
end    
if isempty(parallels)
    return;
end
[~, idx] = max(parallels(:,2));
pos = parallels(idx, 1);
    [left, right] = extract_operands(expr, pos);
end

function [left, right] = extract_operands(expr, pos)
n = length(expr);
i = pos - 1;
while i >= 1 && expr(i) == ' ', i = i - 1; end
if i < 1, return; end
if expr(i) == ')'
    depth = 1;
    i = i - 1;
    while i >= 1 && depth > 0
        if expr(i) == ')', depth = depth + 1;
        elseif expr(i) == '(', depth = depth - 1; end
        i = i - 1;
    end
    left_end = pos - 1;
    while i >= 1 && expr(i) == ' ', i = i - 1; end       
    if i >= 1 && (expr(i) == '*' || expr(i) == '/')
        op_pos = i;
        i = i - 1;
        while i >= 1 && expr(i) == ' ', i = i - 1; end  
        if i >= 1 && (isalnum(expr(i)) || expr(i) == '_' || expr(i) == ')')
            if expr(i) == ')'
                depth = 1;
                i = i - 1;
                while i >= 1 && depth > 0
                    if expr(i) == ')', depth = depth + 1;
                    elseif expr(i) == '(', depth = depth - 1; end
                    i = i - 1;
                end
            else
                while i >= 1 && (isalnum(expr(i)) || expr(i) == '_')
                    i = i - 1;
                end
            end
            left_start = i + 1;
        else
            left_start = i + 1;  
        end
    else
        left_start = i + 1;
    end
else
    left_end = i;
    while i >= 1 && (isalnum(expr(i)) || expr(i) == '_')
        i = i - 1;
    end
    while i >= 1 && expr(i) == ' ', i = i - 1; end    
    if i >= 1 && (expr(i) == '*' || expr(i) == '/')
        i = i - 1;
        while i >= 1 && expr(i) == ' ', i = i - 1; end
        if expr(i) == ')'
            depth = 1;
            i = i - 1;
            while i >= 1 && depth > 0
                if expr(i) == ')', depth = depth + 1;
                elseif expr(i) == '(', depth = depth - 1; end
                i = i - 1;
            end
        else
            while i >= 1 && (isalnum(expr(i)) || expr(i) == '_')
                i = i - 1;
            end
        end
    end
    left_start = i + 1;
end
left = strtrim(expr(left_start:pos-1)); 
i = pos + 2;  
while i <= n && expr(i) == ' ', i = i + 1; end
if i > n, return; end
right_start = i;
if expr(i) == '('
    depth = 1;
    i = i + 1;
    while i <= n && depth > 0
        if expr(i) == '(', depth = depth + 1;
        elseif expr(i) == ')', depth = depth - 1; end
        i = i + 1;
    end
    right_end = i - 1;
    while i <= n && expr(i) == ' ', i = i + 1; end
    if i <= n && (expr(i) == '*' || expr(i) == '/')
        i = i + 1;
        while i <= n && expr(i) == ' ', i = i + 1; end
        if expr(i) == '('
            depth = 1;
            i = i + 1;
            while i <= n && depth > 0
                if expr(i) == '(', depth = depth + 1;
                elseif expr(i) == ')', depth = depth - 1; end
                i = i + 1;
            end
        else
            while i <= n && (isalnum(expr(i)) || expr(i) == '_')
                i = i + 1;
            end
        end
        right_end = i - 1;
    end
else
    while i <= n && (isalnum(expr(i)) || expr(i) == '_')
        i = i + 1;
    end
    while i <= n && expr(i) == ' ', i = i + 1; end        
    if i <= n && expr(i) == '('
        depth = 1;
        i = i + 1;
        while i <= n && depth > 0
            if expr(i) == '(', depth = depth + 1;
            elseif expr(i) == ')', depth = depth - 1; end
            i = i + 1;
        end
        right_end = i - 1;
        while i <= n && expr(i) == ' ', i = i + 1; end
        if i <= n && (expr(i) == '*' || expr(i) == '/')
            i = i + 1;
            while i <= n && expr(i) == ' ', i = i + 1; end
            if expr(i) == '('
                depth = 1; i = i + 1;
                while i <= n && depth > 0
                    if expr(i) == '(', depth = depth + 1;
                    elseif expr(i) == ')', depth = depth - 1; end
                    i = i + 1;
                end
            else
                while i <= n && (isalnum(expr(i)) || expr(i) == '_'), i = i + 1; end
            end
            right_end = i - 1;
        end
    else
        right_end = i - 1;
    end
end
right = strtrim(expr(pos+2:right_end));
end

function yes = isalnum(ch)
yes = (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || (ch >= '0' && ch <= '9');
end



