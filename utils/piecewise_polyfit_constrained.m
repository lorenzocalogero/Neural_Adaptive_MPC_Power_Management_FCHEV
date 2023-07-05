function p = piecewise_polyfit_constrained(x,y,xc,yc,deg)

p = cell(length(deg),1);    % Contains the poly coef of each piece

for i = 1:1:length(deg)
	
	ind_fit = (x >= xc(i) & x <= xc(i+1));    % Fit range
	x_fit = x(ind_fit);
	y_fit = y(ind_fit);
	
	p{i} = polyfix(x_fit,y_fit,deg(i),[xc(i), xc(i+1)],[yc(i), yc(i+1)]);
	
end

end