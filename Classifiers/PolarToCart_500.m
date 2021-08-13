% Yanan Niu
% Impact and Implications of Mixed Plaque class in Automated Characterization of Complex Atherosclerotic Lesions
% version 26/07/2021

% Convert OCT from Polar coordinates into Cartesian coordinates
%   input -----------------------------------------------------------------
%      Name                Value
%      'OCT_pol'        OCT in Polar coordinates, 500*500*n

%   Output ----------------------------------------------------------------
%      Name                Value
%      'OCT_cart'       OCT in Cartesian coordinates, 500*500*n  

function [OCT_cart]=PolarToCart_500(OCT_pol)

% create a cartesian coordinate  x & y, centered at (250.5，250.5）in a 500*500 matrix
x = repmat(1:500,500,1)-250.5;
y = flip(x.',1);

% convert cartesian coordinates into polar coordinates
[t,r] = cart2pol(x,y); % t: [0,pi & 0, -pi]

% transfer t into [0,2pi]
%Vertical down: 0 degree
t((-pi<= t)&(t<= -pi/2)) = t((-pi<= t)&(t<= -pi/2))+2*pi;
t = t+pi/2;
% rescale t and r in polar coordinates
t_cart = round(t*500/(2*pi));
r_cart = round(r*500/250);

% r_cart,t_cart used as bridge to find corresponding coordinates for cartersian in polar.
% r_cart,t_cart used as index, so 0 should all be replaced by 1 (min index)
r_cart(r_cart==0)=1;
t_cart(t_cart==0)=1;

r_cart = repmat(r_cart,1,1,size(OCT_pol,3));
t_cart = repmat(t_cart,1,1,size(OCT_pol,3));
OCT_cart=zeros(500,500,size(OCT_pol,3));
for d = 1:size(OCT_pol,3) % repeat the process for all the dimensions
    for j=1:500  %row
        for i = 1:500 %coloum
            if r_cart(i,j,d)>=500
                OCT_cart(i,j,d) = 0;
            else
                OCT_cart(i,j,d) = OCT_pol(r_cart(i,j,d),t_cart(i,j,d),d);              
            end
        end
    end
end
