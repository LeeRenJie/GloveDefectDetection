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

    for i = 1:length(stats)
        center = stats(i).Centroid;
        if stats(i).Area < 10000
            circleRadius = max(120, sqrt(stats(i).Area / pi));
        else
            boundingBox = stats(i).BoundingBox;
            diameter = sqrt(boundingBox(3)^2 + boundingBox(4)^2);
            circleRadius = diameter / 2;
        end
        % Draw thicker circles on a binary mask
        circleMask = false(size(outputImage, 1), size(outputImage, 2));
        [columnsInImage, rowsInImage] = meshgrid(1:size(outputImage, 2), 1:size(outputImage, 1));
        filledCircle = (rowsInImage - center(2)).^2 + (columnsInImage - center(1)).^2 <= circleRadius.^2;
        smallerCircleRadius = circleRadius - circleThickness;
        smallerCircle = (rowsInImage - center(2)).^2 + (columnsInImage - center(1)).^2 <= smallerCircleRadius.^2;
        circleOutline = filledCircle & ~smallerCircle;

        % Use the mask to set the red channel to max in the detected regions
        outputImage(:,:,1) = outputImage(:,:,1) + uint8(circleOutline)*255;
    end

    % Ensure the red channel doesn't exceed the maximum value
    outputImage(:,:,1) = min(outputImage(:,:,1), 255);
end