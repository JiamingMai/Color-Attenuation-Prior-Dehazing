function [ A ] = estA( img, Jdark, isShowImg)
%ESTABYTRAN Summary of this function goes here

if nargin < 3
    isShowImg = 1;
end

% Estimate Airlight of image I

[h,w,c] = size(img);
if isinteger(img)
    img = double(img)/255;
end

    % Compute number for 0.1% brightest pixels
    n_bright = ceil(0.001*h*w); 
    % Loc contains the location of the sorted pixels
    [Y,Loc] = sort(Jdark(:));
    
    %column-stacked version of I 
    Ics = reshape(img, h*w, 1, 3);
    ix = img;
    dx = Jdark(:);
    
    %init a matrix to store candidate airlight pixels
    Acand = zeros(n_bright,1,3);
    %init matrix to store largest norm airlight 
    Amag = zeros(n_bright,1); 
    
    % Compute magnitudes of RGB vectors of A
    for i = 1:n_bright
        x = Loc(h*w+1-i);
        %ix(mod(x,h)+1, floor(x/w)+1, 1) = 1;
        %ix(mod(x,h)+1, floor(x/w)+1, 2) = 0;
        %ix(mod(x,h)+1, floor(x/w)+1, 3) = 0;
        ix(mod(x,h)+1, floor(x/h)+1, 1) = 1;
        ix(mod(x,h)+1, floor(x/h)+1, 2) = 0;
        ix(mod(x,h)+1, floor(x/h)+1, 3) = 0;
        %Jdark(mod(x,h), floor(x/w)+1);
        %dx(x);

       Acand(i,1,:) = Ics(Loc(h*w+1-i),1,:);
       Amag(i) = norm(Acand(i,:)); 
    end
    
    % Sort A magnitudes
    [Y2,Loc2] = sort(Amag(:));
    % A now stores the best estimate of the airlight
    if length(Y2) > 20
        A = Acand(Loc2(n_bright-19:n_bright),:); 
    else
        A = Acand(Loc2(n_bright-length(Y2)+1:n_bright),:); 
    end
    % finds the max of the 20 brightest pixels in original image
    if size(A,1)~=1
        A = max(A);     
    end
    if isShowImg == 1
        figure;
        imshow(ix);    
        title('position of the atmospheric light');
        imwrite(ix, 'res/position_of_the_atmospheric_light.png');    
    end
end

