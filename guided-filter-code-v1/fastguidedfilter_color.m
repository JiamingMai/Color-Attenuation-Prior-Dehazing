function q = fastguidedfilter_color(I, p, r, eps, s)
%   GUIDEDFILTER_COLOR   O(1) time implementation of guided filter using a color image as the guidance.
%
%   - guidance image: I (should be a color (RGB) image)
%   - filtering input image: p (should be a gray-scale/single channel image)
%   - local window radius: r
%   - regularization parameter: eps
%   - subsampling ratio: s (try s = r/4 to s=r)

I_sub = imresize(I, 1/s, 'nearest'); % NN is often enough
p_sub = imresize(p, 1/s, 'nearest');
r_sub = r / s; % make sure this is an integer

[hei, wid] = size(p_sub);
N = boxfilter(ones(hei, wid), r_sub); % the size of each local patch; N=(2r+1)^2 except for boundary pixels.

mean_I_r = boxfilter(I_sub(:, :, 1), r_sub) ./ N;
mean_I_g = boxfilter(I_sub(:, :, 2), r_sub) ./ N;
mean_I_b = boxfilter(I_sub(:, :, 3), r_sub) ./ N;

mean_p = boxfilter(p_sub, r_sub) ./ N;

mean_Ip_r = boxfilter(I_sub(:, :, 1).*p_sub, r_sub) ./ N;
mean_Ip_g = boxfilter(I_sub(:, :, 2).*p_sub, r_sub) ./ N;
mean_Ip_b = boxfilter(I_sub(:, :, 3).*p_sub, r_sub) ./ N;

% covariance of (I, p) in each local patch.
cov_Ip_r = mean_Ip_r - mean_I_r .* mean_p;
cov_Ip_g = mean_Ip_g - mean_I_g .* mean_p;
cov_Ip_b = mean_Ip_b - mean_I_b .* mean_p;

% variance of I in each local patch: the matrix Sigma in Eqn (14).
% Note the variance in each local patch is a 3x3 symmetric matrix:
%           rr, rg, rb
%   Sigma = rg, gg, gb
%           rb, gb, bb
var_I_rr = boxfilter(I_sub(:, :, 1).*I_sub(:, :, 1), r_sub) ./ N - mean_I_r .*  mean_I_r; 
var_I_rg = boxfilter(I_sub(:, :, 1).*I_sub(:, :, 2), r_sub) ./ N - mean_I_r .*  mean_I_g; 
var_I_rb = boxfilter(I_sub(:, :, 1).*I_sub(:, :, 3), r_sub) ./ N - mean_I_r .*  mean_I_b; 
var_I_gg = boxfilter(I_sub(:, :, 2).*I_sub(:, :, 2), r_sub) ./ N - mean_I_g .*  mean_I_g; 
var_I_gb = boxfilter(I_sub(:, :, 2).*I_sub(:, :, 3), r_sub) ./ N - mean_I_g .*  mean_I_b; 
var_I_bb = boxfilter(I_sub(:, :, 3).*I_sub(:, :, 3), r_sub) ./ N - mean_I_b .*  mean_I_b; 

a = zeros(hei, wid, 3);
for y=1:hei
    for x=1:wid        
        Sigma = [var_I_rr(y, x), var_I_rg(y, x), var_I_rb(y, x);
            var_I_rg(y, x), var_I_gg(y, x), var_I_gb(y, x);
            var_I_rb(y, x), var_I_gb(y, x), var_I_bb(y, x)];
        
        cov_Ip = [cov_Ip_r(y, x), cov_Ip_g(y, x), cov_Ip_b(y, x)];        
        
        a(y, x, :) = cov_Ip * inv(Sigma + eps * eye(3)); % very inefficient. Replace this in your C++ code.
    end
end

b = mean_p - a(:, :, 1) .* mean_I_r - a(:, :, 2) .* mean_I_g - a(:, :, 3) .* mean_I_b; % Eqn. (15) in the paper;

mean_a(:, :, 1) = boxfilter(a(:, :, 1), r_sub)./N;
mean_a(:, :, 2) = boxfilter(a(:, :, 2), r_sub)./N;
mean_a(:, :, 3) = boxfilter(a(:, :, 3), r_sub)./N;
mean_b = boxfilter(b, r_sub)./N;

mean_a = imresize(mean_a, [size(I, 1), size(I, 2)], 'bilinear'); % bilinear is recommended
mean_b = imresize(mean_b, [size(I, 1), size(I, 2)], 'bilinear');
q = mean_a(:, :, 1) .* I(:, :, 1)...
    + mean_a(:, :, 2) .* I(:, :, 2)...
    + mean_a(:, :, 3) .* I(:, :, 3)...
    + mean_b;
end