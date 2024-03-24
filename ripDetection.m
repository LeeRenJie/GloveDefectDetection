function outputImage = ripDetection(inputImage)

    % Convert to HSV color space
    hsvImg = rgb2hsv(inputImage);

    % Define HSV ranges for rip detection
    hueRange = [0.0 0.08]; 
    satRange = [0.3 0.7]; 
    valRange = [0.3 0.9]; 

    % Binary mask for rip detection
    ripMask = (hsvImg(:,:,1) >= hueRange(1)) & (hsvImg(:,:,1) <= hueRange(2)) & ...
               (hsvImg(:,:,2) >= satRange(1)) & (hsvImg(:,:,2) <= satRange(2)) & ...
               (hsvImg(:,:,3) >= valRange(1)) & (hsvImg(:,:,3) <= valRange(2));

    % Clean mask by removing small objects
    ripMaskCleaned = bwareaopen(ripMask, 1500);

    % Blob analysis on cleaned mask
    cc = bwconncomp(ripMaskCleaned);
    % Measure properties of image regions
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