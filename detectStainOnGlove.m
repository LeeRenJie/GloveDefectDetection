function outputImage = detectStainOnGlove(inputImage)
    % Convert the input image to the HSV color space for easier color segmentation
    hsvImg = rgb2hsv(inputImage);
    
    % Define the color ranges for the black glove
    blackColorValueRange = [0.0 0.5]; % Low value indicates darker colors
    
    % Create a binary mask for the glove based on the value (brightness) range
    gloveMask = (hsvImg(:,:,3) >= blackColorValueRange(1)) & (hsvImg(:,:,3) <= blackColorValueRange(2));
    noiseRemovedGloveMask = bwareaopen(gloveMask, 170); % Remove small objects
    filledGloveMask = imfill(noiseRemovedGloveMask, 'holes'); % Fill holes in the mask
    structuralElement = strel('disk', 17);
    smoothedGloveMask = imopen(filledGloveMask, structuralElement);
    
    % Define the color ranges for detecting white stains on the glove
    StainSatRange = [0.0 0.5]; % Stain has low saturation
    StainValRange = [0.6 1.0]; % High value brightness
    
    % Create a binary mask for potential stain areas
    StainMask = (hsvImg(:,:,2) >= StainSatRange(1)) & (hsvImg(:,:,2) <= StainSatRange(2)) & ...
                (hsvImg(:,:,3) >= StainValRange(1)) & (hsvImg(:,:,3) <= StainValRange(2));
    
    % Isolate stains on the glove by combining the stain mask with the cleaned glove mask
    StainOnGloveMask = StainMask & smoothedGloveMask;
    StainOnGloveMaskCleaned = bwareaopen(StainOnGloveMask, 320);
    se = strel('disk', 100); % Define the structuring element for closing
    closedStainMask = imclose(StainOnGloveMaskCleaned, se);
    
    % Prepare to overlay detected stains on the original image
    outputImage = inputImage;
    
    % Find connected components in the cleaned stain mask for visualization
    cc = bwconncomp(closedStainMask);
    stats = regionprops(cc, 'Area', 'Centroid', 'BoundingBox');
    
    % Circle thickness
    circleThickness = 17; % Adjust thickness
    
        % Loop through each detected object in the 'stats' array
        for i = 1:length(stats)
            % Retrieve the centroid coordinates of the current object
            center = stats(i).Centroid;
            
            % If the area of the object is smaller than 10,000 pixels,
            % calculate the circle radius based on the area to maintain a minimum
            % size or scale with the object's area.
            if stats(i).Area < 10000
                % Ensure a minimum radius of 120 pixels, or scale with sqrt(area/pi) for smaller objects
                circleRadius = max(120, sqrt(stats(i).Area / pi));
            else
                % For larger objects, calculate the diagonal of the bounding box
                boundingBox = stats(i).BoundingBox;
                diameter = sqrt(boundingBox(3)^2 + boundingBox(4)^2);
                % Use half the diagonal as the circle radius
                circleRadius = diameter / 2;
            end
            
            % Create a grid of column and row indices for the entire image
            [columnsInImage, rowsInImage] = meshgrid(1:size(outputImage, 2), 1:size(outputImage, 1));
            
            % Define a filled circle based on the calculated radius and the object's centroid,
            % marking pixels inside the circle as true.
            filledCircle = (rowsInImage - center(2)).^2 + (columnsInImage - center(1)).^2 <= circleRadius.^2;
            
            % Calculate a slightly smaller radius for creating an outline effect
            smallerCircleRadius = circleRadius - circleThickness;
            
            % Define another circle with the smaller radius
            smallerCircle = (rowsInImage - center(2)).^2 + (columnsInImage - center(1)).^2 <= smallerCircleRadius.^2;
            
            % Create the circle outline by subtracting the smaller circle from the filled circle,
            % resulting in a ring (outline) of the original circle.
            circleOutline = filledCircle & ~smallerCircle;
                % Use the mask to set the red channel to max in the detected regions
                outputImage(:,:,1) = outputImage(:,:,1) + uint8(circleOutline)*255;
        end
    
        % Ensure the red channel doesn't exceed the maximum value
        outputImage(:,:,1) = min(outputImage(:,:,1), 255);
 end