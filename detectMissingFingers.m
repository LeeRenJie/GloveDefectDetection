function outputImage = detectMissingFingers(inputImage)
    % Convert the input image to the HSV color space for easier color segmentation
    hsvImg = rgb2hsv(inputImage);

    % Define the HSV color range for detecting skin
    skinHueRange = [0.0 0.09]; % hue range
    skinSaturationRange = [0.3 0.7]; % saturation range
    skinValueRange = [0.3 0.9]; % value range

    % Create a binary mask identifying skin areas
    skinMask = (hsvImg(:,:,1) >= skinHueRange(1)) & (hsvImg(:,:,1) <= skinHueRange(2)) & ...
               (hsvImg(:,:,2) >= skinSaturationRange(1)) & (hsvImg(:,:,2) <= skinSaturationRange(2)) & ...
               (hsvImg(:,:,3) >= skinValueRange(1)) & (hsvImg(:,:,3) <= skinValueRange(2));

    % Remove small objects from the mask
    MissFingerMaskCleaned = bwareaopen(skinMask, 6300);

    % Apply morphological closing to the mask
    structuringElement = strel('disk', 100);
    MissFingerMaskClosed = imclose(MissFingerMaskCleaned, structuringElement);

    % Analyze the closed mask to identify regions
    connectedComponents = bwconncomp(MissFingerMaskClosed);
    regionsStats = regionprops(connectedComponents, 'Area', 'Centroid', 'BoundingBox');

    outputImage = inputImage;

    % Define circle thickness
    circleThickness = 17; % Adjust for thicker or thinner circles

    % Loop through each region in the 'regionsStats' array
    for idx = 1:numel(regionsStats)
        % Extract the centroid coordinates for the current region
        center = regionsStats(idx).Centroid;
        
        % Retrieve the bounding box of the current region, which contains
        % the rectangle enclosing the region
        boundingBox = regionsStats(idx).BoundingBox;
        
        % Determine the diameter of the circle by taking the maximum of the
        % width (3rd element) and height (4th element) of the bounding box
        diameter = max(boundingBox(3), boundingBox(4));
        
        % Calculate the radius of the circle as half of the diameter
        radius = diameter / 2;
        
        % Initialize a binary mask the same size as 'outputImage' to false (all black)
        % This mask will be used to draw the circle outlines
        circleMask = false(size(outputImage, 1), size(outputImage, 2));
        
        % Create a grid of column and row indices matching the dimensions of 'outputImage'
        [columnsInImage, rowsInImage] = meshgrid(1:size(outputImage, 2), 1:size(outputImage, 1));
        
        % Compute the distance from each pixel to the center of the circle.
        % This creates a matrix where each cell contains the distance from that pixel
        % to the centroid of the current region.
        distanceFromCenter = sqrt((rowsInImage - center(2)).^2 + (columnsInImage - center(1)).^2);
        
        % Define the circle mask: pixels are part of the mask if their distance from the center
        % is less than or equal to the radius (inside the circle) and also greater than or equal to
        % the radius minus the circle thickness (creating an outline effect).
        % This effectively creates a ring whose width is 'circleThickness'.
        circleMask = distanceFromCenter <= radius & distanceFromCenter >= (radius - circleThickness);
        
        % At this point, 'circleMask' contains a true value for pixels that should be part of
        % the circular outline. We might then apply this mask to 'outputImage' to visualize
        % the circles, such as by setting these pixels to a certain color or intensity.

        % Apply the circle mask to the image, setting the outlined area to red
        for c = 1:3 % Apply to all three color channels for a red circle
            channel = outputImage(:,:,c);
            if c == 1
                channel(circleMask) = 255; % Set red channel to max
            else
                channel(circleMask) = 0; % Set green and blue channels to min
            end
            outputImage(:,:,c) = channel;
        end
    end
end