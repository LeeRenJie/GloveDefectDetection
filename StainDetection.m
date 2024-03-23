                        %---------------Detect Stain----------------%
% Load the image
img = imread('Stain-4.jpeg');

% Convert the RGB image to the HSV color space for easier color segmentation
hsvImg = rgb2hsv(img);

% Define the color ranges for the black glove. Black color has no specific hue,
% but we can identify it by its low value (brightness) in the HSV color space.
blackColorHueRange = [0.0 1.0]; % Full hue range since black has no specific hue
blackColorSaturationRange = [0.0 1.0]; % Full saturation range, adjust based on observation
blackColorValueRange = [0.0 0.5]; % Low value indicates darker colors

% Create a binary mask for the glove based on the value (brightness) range
gloveMask = (hsvImg(:,:,3) >= blackColorValueRange(1)) & (hsvImg(:,:,3) <= blackColorValueRange(2));

% Clean up the glove mask by removing small objects and filling holes
% This helps to create a more accurate representation of the glove
noiseRemovedGloveMask = bwareaopen(gloveMask, 170); % Remove small objects
filledGloveMask = imfill(noiseRemovedGloveMask, 'holes'); % Fill holes in the mask

% Create a structural element for morphological operations
structuralElement = strel('disk', 17);

% Perform morphological opening on the glove mask to smooth edges
smoothedGloveMask = imopen(filledGloveMask, structuralElement);

% Define the color ranges for detecting white stains on the glove.
StainSatRange = [0.0 0.5]; % Stain has low saturation
% Stains are characterized by their higher brightness and lower saturation.
StainValRange = [0.6 1.0]; % High value brightness

% Create a binary mask for potential stain areas based on saturation and brightness
StainMask = (hsvImg(:,:,2) >= StainSatRange(1)) & (hsvImg(:,:,2) <= StainSatRange(2)) & ...
           (hsvImg(:,:,3) >= StainValRange(1)) & (hsvImg(:,:,3) <= StainValRange(2));

% Isolate stains on the glove by combining the stain mask with the cleaned glove mask
StainOnGloveMask = StainMask & smoothedGloveMask;

% Refine the stain detection by removing noise and small artifacts
StainOnGloveMaskCleaned = bwareaopen(StainOnGloveMask, 320);

% Perform a morphological closing operation to connect close regions of stains
se = strel('disk', 100); % Define the structuring element
closedStainMask = imclose(StainOnGloveMaskCleaned, se);

% Display results: original image, processed mask, and final detection with overlays
figure('Position', get(0, 'Screensize'));
% Original image
subplot(1, 3, 1);
imshow(img);
title('Original Image');

% Processed mask (Stain on glove)
subplot(1, 3, 2);
imshow(closedStainMask);
title('Processed Mask');

% Final image with detections overlaid
subplot(1, 3, 3);
imshow(img);
hold on;
title('Detected on Stain');

% Find connected components in the cleaned stain mask for visualization
cc = bwconncomp(StainOnGloveMaskCleaned);
stats = regionprops(cc, 'Area', 'Centroid', 'Eccentricity', 'BoundingBox');

% Loop through each detected region to draw circles
for i = 1:length(stats)
    % Adjust the visualization based on the stain's size
    if stats(i).Area < 10000
        % Smaller stains are visualized with smaller circles
        circleRadius = max(120, sqrt(stats(i).Area/pi)); % Calculate radius, ensuring a minimum size
    else
        % Larger stains are visualized based on their bounding box size
        boundingBox = stats(i).BoundingBox;
        diameter = sqrt(boundingBox(3)^2 + boundingBox(4)^2);
        circleRadius = diameter / 2
    end

    % Draw circles around detected stains for visualization
    viscircles(stats(i).Centroid, circleRadius, 'Color', 'r', 'LineWidth', 0.5);
end

hold off;