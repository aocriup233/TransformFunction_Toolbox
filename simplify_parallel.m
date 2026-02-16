function expr_out = simplify_parallel(expr_in)
% 使用调度场算法处理并联运算符 //

    if isa(expr_in, 'sym')
        expr_str = char(expr_in);
    else
        expr_str = strtrim(expr_in);
    end
    
    if isempty(strfind(expr_str, '//'))
        expr_out = expr_str;
        return;
    end
    
    % 标记 // 为特殊运算符，避免与普通 / 混淆
    expr_marked = strrep(expr_str, '//', char(127));  % 用 DEL 字符 (ASCII 127) 标记
    
    % 解析为 tokens
    tokens = tokenize(expr_marked);
    
    % 调度场算法：中缀转后缀，同时展开 //
    output_queue = shunting_yard(tokens);
    
    % 重建表达式
    expr_out = rebuild_expr(output_queue);
end

function tokens = tokenize(expr)
% 将表达式分割为 tokens
    tokens = {};
    i = 1;
    n = length(expr);
    
    while i <= n
        ch = expr(i);
        
        if ch == ' '
            i = i + 1;
        elseif ch == char(127)  % 并联运算符
            tokens{end+1} = '//';
            i = i + 1;
        elseif any(ch == '+-*/^')
            tokens{end+1} = ch;
            i = i + 1;
        elseif ch == '(' || ch == ')'
            tokens{end+1} = ch;
            i = i + 1;
        else
            % 标识符或数字
            start = i;
            while i <= n && (isalnum(expr(i)) || expr(i) == '_' || expr(i) == '.')
                i = i + 1;
            end
            tokens{end+1} = expr(start:i-1);
        end
    end
end

function output = shunting_yard(tokens)
% 调度场算法，遇到 // 立即展开
    output = {};
    op_stack = {};
    
    i = 1;
    while i <= length(tokens)
        token = tokens{i};
        
        if is_identifier(token)
            output{end+1} = token;
            
        elseif token == '('
            op_stack{end+1} = token;
            
        elseif token == ')'
            while ~isempty(op_stack) && ~strcmp(op_stack{end}, '(')
                output{end+1} = op_stack{end};
                op_stack(end) = [];
            end
            if ~isempty(op_stack)
                op_stack(end) = [];  % 弹出 '('
            end
            
        elseif is_operator(token)
            if strcmp(token, '//')
                % 并联运算符：弹出栈顶直到遇到 '(' 或更低优先级
                while ~isempty(op_stack) && ~strcmp(op_stack{end}, '(') && ...
                      precedence(op_stack{end}) >= precedence(token)
                    output{end+1} = op_stack{end};
                    op_stack(end) = [];
                end
                op_stack{end+1} = token;
            else
                % 普通运算符
                while ~isempty(op_stack) && ~strcmp(op_stack{end}, '(') && ...
                      precedence(op_stack{end}) >= precedence(token)
                    output{end+1} = op_stack{end};
                    op_stack(end) = [];
                end
                op_stack{end+1} = token;
            end
        end
        
        i = i + 1;
    end
    
    % 弹出剩余运算符
    while ~isempty(op_stack)
        output{end+1} = op_stack{end};
        op_stack(end) = [];
    end
end

function out = expand_rpn(rpn_tokens)
% 计算后缀表达式，遇到 // 展开为 (a*b)/(a+b)
    stack = {};
    
    for i = 1:length(rpn_tokens)
        token = rpn_tokens{i};
        
        if is_identifier(token)
            stack{end+1} = token;
            
        elseif is_operator(token)
            if length(stack) < 2
                error('表达式错误：运算符 %s 需要两个操作数', token);
            end
            
            b = stack{end}; stack(end) = [];  % 右操作数
            a = stack{end}; stack(end) = [];  % 左操作数
            
            if strcmp(token, '//')
                % 并联展开：(a*b)/(a+b)
                result = sprintf('((%s)*(%s))/((%s)+(%s))', a, b, a, b);
            else
                % 普通运算符
                result = sprintf('(%s%s%s)', a, token, b);
            end
            
            stack{end+1} = result;
        end
    end
    
    if length(stack) ~= 1
        error('表达式错误：栈中剩余 %d 个元素', length(stack));
    end
    
    out = stack{1};
end

function out = rebuild_expr(rpn_tokens)
% 从 RPN 重建表达式字符串
    out = expand_rpn(rpn_tokens);
end

function yes = is_identifier(token)
    yes = ~isempty(token) && (isletter(token(1)) || isdigit(token(1)));
end

function yes = is_operator(token)
    yes = any(token(1) == '+-*/^') || strcmp(token, '//');
end

function p = precedence(op)
    switch op
        case {'+', '-'}
            p = 1;
        case {'*', '/'}
            p = 2;
        case '//'
            p = 3;  % 并联优先级最高（左结合）
        case '^'
            p = 4;
        otherwise
            p = 0;
    end
end

function yes = isalnum(ch)
    yes = (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || (ch >= '0' && ch <= '9');
end

function yes = isdigit(ch)
    yes = ch >= '0' && ch <= '9';
end

function yes = isletter(ch)
    yes = (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z');
end