function outputImage = detectDirtOnGlove(inputImage)
    % Convert input image from RGB to HSV color space for better color segmentation
    hsvImg = rgb2hsv(inputImage);

    % Define value range for identifying the black glove (dark colors)
    gloveValRange = [0.0 0.5];

    % Create binary mask to identify the glove by its value range
    gloveMask = (hsvImg(:,:,3) >= gloveValRange(1)) & (hsvImg(:,:,3) <= gloveValRange(2));

    % Clean the glove mask by removing noise and filling holes
    gloveMaskCleaned = imfill(bwareaopen(gloveMask, 50), 'holes');

    % Define saturation and value ranges to identify white dirt
    dirtSatRange = [0.0 0.5];
    dirtValRange = [0.6 1.0];

    % Create binary mask for detecting white dirt based on its color characteristics
    dirtMask = (hsvImg(:,:,2) >= dirtSatRange(1)) & (hsvImg(:,:,2) <= dirtSatRange(2)) & ...
               (hsvImg(:,:,3) >= dirtValRange(1)) & (hsvImg(:,:,3) <= dirtValRange(2));

    % Refine the dirt detection to only include dirt on the glove
    dirtOnGloveMask = dirtMask & gloveMaskCleaned;

    % Clean the dirt mask further by removing very small objects
    dirtOnGloveMaskCleaned = bwareaopen(dirtOnGloveMask, 1);

    % Perform morphological closing to connect nearby dirt grains into clumps
    se = strel('disk', 10);
    closedDirtMask = imclose(dirtOnGloveMaskCleaned, se);

    % Identify clusters of dirt grains as connected components
    cc = bwconncomp(closedDirtMask);

    % Measure properties of dirt clusters for visualization
    stats = regionprops(cc, 'Area', 'Centroid', 'BoundingBox');

    % Initialize output image for drawing indications of dirt
    outputImage = inputImage;

    % Iterate through each detected dirt clump to visualize
    for i = 1:length(stats)
        if stats(i).Area < 10000
            % Use a fixed or calculated radius for small dirt grains
            circleRadius = max(5, sqrt(stats(i).Area/pi));
        else
            % For larger clumps, calculate circle size based on bounding box diagonal
            boundingBox = stats(i).BoundingBox;
            diameter = sqrt(boundingBox(3)^2 + boundingBox(4)^2);
            circleRadius = diameter / 2;
        end

        % Draw a red circle around each detected dirt clump or grain
        color = [255, 0, 0]; % Red indicates detected dirt
        thickness = 5; % Circle line thickness
        outputImage = drawCircleOnImage(outputImage, stats(i).Centroid(1), stats(i).Centroid(2), circleRadius, thickness, color);
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