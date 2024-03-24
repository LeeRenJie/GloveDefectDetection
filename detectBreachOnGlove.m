function outputImage = detectBreachOnGlove(inputImage)
    % Convert the image to the HSV color space
    hsvImg = rgb2hsv(inputImage);

    % Define HSV color ranges for breach detection
    hueRange = [0.0 0.09];  
    satRange = [0.3 0.7];   
    valRange = [0.3 0.9];

    % Create a binary mask for the breach
    breachMask = (hsvImg(:,:,1) >= hueRange(1)) & (hsvImg(:,:,1) <= hueRange(2)) & ...
                 (hsvImg(:,:,2) >= satRange(1)) & (hsvImg(:,:,2) <= satRange(2)) & ...
                 (hsvImg(:,:,3) >= valRange(1)) & (hsvImg(:,:,3) <= valRange(2));

    % Clean up the mask
    breachMaskCleaned = bwareaopen(breachMask, 50);

    % Find connected components
    cc = bwconncomp(breachMaskCleaned);
    stats = regionprops(cc, 'Area', 'Centroid', 'BoundingBox');

    % Start with the original image
    outputImage = inputImage;

    for idx = 1:numel(stats)
        % Calculate the circle parameters
        increaseFactor = 1.5; % Adjust as needed
        diameter = max(stats(idx).BoundingBox(3), stats(idx).BoundingBox(4)) * increaseFactor;
        radius = diameter / 2;
        thickness = 10; % Thickness of the circle
        centerX = stats(idx).Centroid(1);
        centerY = stats(idx).Centroid(2);
        color = [255, 0, 0]; % Color of the circle (red)
        
        % Draw the circle on the image
        outputImage = drawCircleOnImage(outputImage, centerX, centerY, radius, thickness, color);
    end
end

function img = drawCircleOnImage(img, centerX, centerY, radius, thickness, color)
    [rows, cols, ~] = size(img);
    [X, Y] = meshgrid(1:cols, 1:rows);
    
    for r = radius-thickness/2:radius+thickness/2
        mask = ((X - centerX).^2 + (Y - centerY).^2 <= r.^2) & ...
               ((X - centerX).^2 + (Y - centerY).^2 >= (r-thickness).^2);
        
        for k = 1:3 % For R, G, B channels
            channel = img(:,:,k);
            channel(mask) = color(k);
            img(:,:,k) = channel;
        end
    end
end