function [J,h,func_evals,f_0]=num_jacobian(func,x,varargin)
     
%%  DEFAULT PARAMETERS
f_0=[];                     %   value at evaluation point (can be user-supplied
lb=-inf(size(x));           %   lower boundary of domain of X
ub=inf(size(x));            %   upper boundary of domain of X
FinDiffRelStep=eps^(1/3);   %   relative differentiation step size
TypicalX=1;                 %   sets lower limit of differentiation step 
%                               size, similar to the optimization routines 
%                               in matlab 
%%  DYNAMIC READ IN
if nargin>2    
    list=who;
    opt=[];arg_list=[];
    pos=1;flag_thereismore=1;
    %%  check if argument gives us a structure
    if flag_thereismore
        if isstruct(varargin{pos})
            opt=varargin{pos};
            pos=pos+1;
            flag_thereismore=nargin>(pos+1);
        end
    end
    %%  check for name-variable pairs
    if flag_thereismore
        if ((nargin-pos-1)/2)==fix((nargin-pos-1)/2)
            arg_list=varargin(pos:end);
        else
            error('No of arguments is off.')
        end
    end  
    %%  add option structure variables if they are part of the list
    if ~isempty(opt)
        for i1=1:numel(list)
            if isfield(opt, char(list{i1}))
                eval(horzcat(matlab.lang.makeValidName(char(list(i1))),'=opt.',char(list{i1}),';'));
            end
        end
    end
    %%  add name-value pair arguments if they are part of the list
    if ~isempty(arg_list)
        for i1=1:numel(arg_list)/2
            if ismember(arg_list{(i1-1)*2+1},list) && isnumeric(arg_list{(i1-1)*2+2})
                eval(horzcat(arg_list{(i1-1)*2+1},'=',num2str(arg_list{(i1-1)*2+2}),';'));
            end
        end
    end 
end
%%  MAIN ROUTINE
% function value
func_evals=0;
if isempty(f_0)
    f_0=func(x);                   
    func_evals=func_evals+1;
end
%   size of independent
n=numel(x);  
%   size of dependent
m=numel(f_0);
%   size of increment before boundaries are considered
h=FinDiffRelStep.*max(abs(x),TypicalX);
%   allocate memory for the Jacobian matrix
J=zeros(m,n);                   
%%  loop for each independent variable 
for k=1:n                       
    %%  reference point calculation
    x1=x;                       
    %   boundary integrity
    if (ub(k)-x1(k))<h(k)         % feasibility
        if (x1(k)-lb(k))<h(k) 
            h(k)=-h(k);
        else
            if (ub(k)-x1(k))>=(x1(k)-lb(k))
                h(k)=ub(k)-x1(k);
            else
                h(k)=lb(k)-x1(k);
            end
        end
    end
    %   final increment in kth independent variable
    x1(k)=x1(k)+h(k);   
    %%  step differentiation 
    J(:,k)=(func(x1)-f_0)/h(k);     
    func_evals=func_evals+1;
    h(k)=abs(h(k));
end
end