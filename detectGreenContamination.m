function outputImage = detectGreenContamination(inputImage)
    % Convert the image to the HSV color space
    hsvImg = rgb2hsv(inputImage);

    % HSV ranges for green contamination detection
    hueRange = [0.15 0.4]; % hue range
    satRange = [0.3 0.9]; % saturation range
    valRange = [0 0.8]; % value range

    % Binary mask for green contamination detection
    stainMask = (hsvImg(:,:,1) >= hueRange(1)) & (hsvImg(:,:,1) <= hueRange(2)) & ...
               (hsvImg(:,:,2) >= satRange(1)) & (hsvImg(:,:,2) <= satRange(2)) & ...
               (hsvImg(:,:,3) >= valRange(1)) & (hsvImg(:,:,3) <= valRange(2));

    % Clean mask by removing small objects
    stainMaskCleaned = bwareaopen(stainMask, 1500);

    % Morphological closing to join regions
    structuringElement = strel('disk', 100); 
    stainMaskClosed = imclose(stainMaskCleaned, structuringElement);

    % Blob analysis on closed mask
    cc = bwconncomp(stainMaskClosed);
    stats = regionprops(cc, 'Area', 'Centroid', 'BoundingBox');

    % Prepare the output image
    outputImage = inputImage;

    if ~isempty(stats)
        increaseFactor = 1.5; % Adjust this factor to make the circle larger
        lineWidth = 10; % This will be the 'thickness' of your circle boundary

        for idx = 1:numel(stats)
            % Calculate the circle parameters based on the bounding box
            boundingBox = stats(idx).BoundingBox;
            diameter = max(boundingBox(3), boundingBox(4)) * increaseFactor;
            radius = diameter / 2;
            centerX = round(stats(idx).Centroid(1));
            centerY = round(stats(idx).Centroid(2));
            
            % Draw the circle manually
            [rows, columns, ~] = size(outputImage);
            [columnGrid, rowGrid] = meshgrid(1:columns, 1:rows);
            circlePixels = (rowGrid - centerY).^2 + (columnGrid - centerX).^2 <= radius.^2;
            thickBoundary = imdilate(circlePixels, strel('disk', lineWidth)) & ~circlePixels; % This creates a thick boundary
            
            % Update the output image pixels to draw the circle
            for channel = 1:size(outputImage, 3) % For each color channel
                channelData = outputImage(:,:,channel);
                channelData(thickBoundary) = channel == 1; % Sets the boundary to red
                outputImage(:,:,channel) = channelData;
            end
        end
    end
end