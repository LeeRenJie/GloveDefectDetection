function outputImage = detectBreachOnGlove(inputImage)
    % Convert input image from RGB to HSV color space
    hsvImg = rgb2hsv(inputImage);

    % Define the hue range for breach detection
    hueRange = [0.0 0.09];
    % Define the saturation range for breach detection
    satRange = [0.3 0.7];
    % Define the value range for breach detection
    valRange = [0.3 0.9];

    % Create a binary mask identifying the breach based on color ranges
    breachMask = (hsvImg(:,:,1) >= hueRange(1)) & (hsvImg(:,:,1) <= hueRange(2)) & ...
                 (hsvImg(:,:,2) >= satRange(1)) & (hsvImg(:,:,2) <= satRange(2)) & ...
                 (hsvImg(:,:,3) >= valRange(1)) & (hsvImg(:,:,3) <= valRange(2));

    % Remove small objects from binary mask to clean it up
    breachMaskCleaned = bwareaopen(breachMask, 50);

    % Identify connected components in the cleaned mask
    cc = bwconncomp(breachMaskCleaned);

    % Measure properties of connected components
    stats = regionprops(cc, 'Area', 'Centroid', 'BoundingBox');

    % Initialize output image as a copy of the input image
    outputImage = inputImage;

    % Draw circles around breaches on the output image
    for idx = 1:numel(stats)
        % Set increase factor for circle size adjustment
        increaseFactor = 1.5;
        % Calculate diameter of circle to be drawn around breach
        diameter = max(stats(idx).BoundingBox(3), stats(idx).BoundingBox(4)) * increaseFactor;
        % Calculate radius of the circle
        radius = diameter / 2;
        % Set thickness of the circle's outline
        thickness = 10;
        % Get center coordinates of the circle
        centerX = stats(idx).Centroid(1);
        centerY = stats(idx).Centroid(2);
        % Set color of the circle to red
        color = [255, 0, 0];

        % Draw circle on the image
        outputImage = drawCircleOnImage(outputImage, centerX, centerY, radius, thickness, color);
    end
end

function img = drawCircleOnImage(img, centerX, centerY, radius, thickness, color)
    % Get the dimensions of the image
    [rows, cols, ~] = size(img);
    % Create a grid of x,y coordinates
    [X, Y] = meshgrid(1:cols, 1:rows);

    % Iterate through each layer of thickness around the radius
    for r = radius-thickness/2:radius+thickness/2
        % Create a mask for the circle area
        mask = ((X - centerX).^2 + (Y - centerY).^2 <= r.^2) & ...
               ((X - centerX).^2 + (Y - centerY).^2 >= (r-thickness).^2);

        % Apply the mask to each color channel of the image
        for k = 1:3 % Loop through the RGB channels
            channel = img(:,:,k); % Select the current channel
            channel(mask) = color(k); % Apply the color to the masked area
            img(:,:,k) = channel; % Update the image channel
        end
    end
    % Return the image with the drawn circle
end